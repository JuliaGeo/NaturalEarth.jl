module NaturalEarth

import GeoJSON
using Pkg
using Pkg.Artifacts
using p7zip_jll
using Scratch
using Downloads
using XML
using RasterDataSources

download_cache = ""

"A list of the names of available artifacts"
const available_artifacts = collect(keys(
    Artifacts.select_downloadable_artifacts(Artifacts.find_artifacts_toml(@__FILE__); include_lazy=true)
))

export naturalearth, bathymetry, NaturalEarthRaster, ne_raster

"""
    naturalearth(dataset_name::String)

Load a NaturalEarth dataset as a `GeoJSON.FeatureCollection` object.

Valid names are found in `Artifacts.toml`. 
We aim to support all datasets listed in https://github.com/nvkelso/natural-earth-vector/tree/master/geojson
"""
function naturalearth(dataset_name::String)
    if dataset_name ∈ available_artifacts
        file_path = @artifact_str("$dataset_name/$dataset_name.geojson")
        return GeoJSON.read(read(file_path, String))
    # elseif dataset_name ∈ available_rasters
    end

    @assert isfile(file_path) """
    `$dataset_name` is not a valid NaturalEarth.jl artifact!
    Please search https://www.naturalearthdata.com for available
    datasets.
    """
end

"""
    bathymetry(contour::Int = 2000)

Convenient acccess to ocean bathymetry datasets.
Currently tested on: https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-bathymetry/
The function returns a MultiPolygon describing the bathymetry at a given depth contour.
The following depths should be available: [10000, 9000, 8000, 7000, 6000, 5000, 4000, 3000, 2000, 1000, 200, 0]
"""
function bathymetry(contour::Int=2000)
    global available_artifacts
    # extract a list of all available bathymetry files
    bathyfiles = filter(contains("bathymetry"), available_artifacts)
    # Extract depth signifier from filename
    matches = match.(r"ne_10m_.*_(\d+)", bathyfiles)
    depths = parse.(Int, first.(getproperty.(matches, :captures)))
    # Extract the file corresponding to the contour
    fileind = findfirst(==(contour), depths)
    isnothing(fileind) && error("Contour $contour not found. Available contours: $(sort(depths))")

    # Open bathymetry file
    bathyfile = bathyfiles[fileind]
    return naturalearth(bathyfile)
end


# Get rasters from AWS

# function get_available_rasters(refresh = false)
#     scratchspace = Scratch.@get_scratch!("rasters")
#     xml_file = joinpath(scratchspace, "index.xml")
#     # refresh the XML file
#     if !isfile(xml_file) || refresh
#         download("https://naturalearth.s3.amazonaws.com/", xml_file)
#     end
#     # read the document
#     xml_doc = LightXML.parse_file(xml_file);
#     # get the root node
#     xml_root = LightXML.root(xml_doc);
#     @assert name(xml_root) == "ListBucketResult" "The format of the NaturalEarth data dictionary at Amazon AWS has changed, or the file is invalid.  Please file an issue at https://github.com/JuliaGeo/NaturalEarth.jl/issues."
#     return deepcopy(attributes_dict(xml_root))
# end

# function available_rasters_dict(keys)
#     retval = Dict{String, Vector{VersionNumber}}()
#     for key_element in keys
#         key_str = key_element[1]
#         endswith(key_str, "/") && continue # discard directory specs
#         if haskey(key_str, "raster")
#             name = splitext(basename(key_str))[1]
#             dirs = splitpath(name)

#             version = if length(dirs) == 1 || !(occursin(".", dirs[1])) # no version number
#                 VersionNumber(typemax(UInt32))
#             else
#                 VersionNumber(dirs[1])
#             end

#             # for i in 1
#     end
# end

# Implement the RasterDataSources.jl interface.
# With this, you can call e.g. # Rasters.Raster(NaturalEarthRaster{:latest, 10, :HYP_HR}, nothing)

struct NaturalEarthRaster{Version, Scale, Name} <: RasterDataSources.RasterDataSource end

function ne_raster(; version = :latest, scale::Int = 10, name::Int) 
    NaturalEarthRaster{Symbol(version), scale, Symbol(name)}
end

const _NATURALEARTH_URI = RasterDataSources.URIs.URI(scheme="https", host="naturalearth.s3.amazonaws.com", path="/")

function _zippath(::Type{NaturalEarthRaster{Version, Scale, Name}}) where {Version, Scale, Name}
    return if Version == :latest || VersionNumber(string(Version)).major == typemax(UInt32)
        "" # max version, so latest
    else
        string(Version) * "/"
    end * if Scale == 110 || Scale == 50 || Scale == 10
        string(Scale) * "m_raster"
    else
        error("Invalid scale: $Scale")
    end * "/" * string(Name) * ".zip"
end

_zipfile_to_read(raster_name, zf) = first(filter(f -> splitdir(f.name)[2] == raster_name, zf.files))

function RasterDataSources.zippath(::Type{NaturalEarthRaster{Version, Scale, Name}}) where {Version, Scale, Name}
    return joinpath(RasterDataSources.rasterpath(), "NaturalEarth", "zips", split(_zippath(NaturalEarthRaster{Version, Scale, Name}), "/")...)
end

function RasterDataSources.zipurl(::Type{NaturalEarthRaster{Version, Scale, Name}}) where {Version, Scale, Name}
    return RasterDataSources.URIs.URI(_NATURALEARTH_URI; path = "/" * _zippath(NaturalEarthRaster{Version, Scale, Name}))
end

function RasterDataSources.zipname(::Type{NaturalEarthRaster{Version, Scale, Name}}) where {Version, Scale, Name}
    return splitpath(_zippath(NaturalEarthRaster{Version, Scale, Name}))[end]
end

function RasterDataSources.rasterpath(T::Type{NaturalEarthRaster{Version, Scale, Name}}) where {Version, Scale, Name}
    return joinpath(RasterDataSources.rasterpath(), "NaturalEarth", split((_zippath(NaturalEarthRaster{Version, Scale, Name})), "/")[1:end-1]..., RasterDataSources.rastername(T))
end

function RasterDataSources.rastername(::Type{NaturalEarthRaster{Version, Scale, Name}}) where {Version, Scale, Name}
    return string(Name) * ".tif"
end

function RasterDataSources.getraster(T::Type{NaturalEarthRaster{Version, Scale, Name}}, layer = nothing) where {Version, Scale, Name}
    raster_path = RasterDataSources.rasterpath(T)
    if !isfile(raster_path)
        zip_path = RasterDataSources.zippath(T)
        RasterDataSources._maybe_download(RasterDataSources.zipurl(T), zip_path)
        zf = RasterDataSources.ZipFile.Reader(zip_path)
        mkpath(dirname(raster_path))
        raster_name = RasterDataSources.rastername(T)
        @show zf
        write(raster_path, read(RasterDataSources._zipfile_to_read(raster_name, zf)))
        close(zf)
    end
    return raster_path
end

function __init__()
    global download_cache = Scratch.get_scratch!(@__MODULE__, "rasters")
end

# Raster API - hook into RasterDataSources

function check_scale(scale::Int)
    return scale in (110, 50, 10)
end

function ne_file_name(scale::Int, type::String, category::String)
    if type in (
        "countries",
        "map_units",
        "map_subunits",
        "sovereignty",
        "tiny_countries",
        "boundary_lines_land",
        "pacific_groupings",
        "breakaway_disputed_areas",
        "boundary_lines_disputed_areas",
        "boundary_lines_maritime_indicator")
        type = "admin_0_" * type
    elseif type == "states"
        type = "admin_1_" * type
    end

    
    if category == "raster"
        return type
    else
        return "ne_$(scale)m_$(type)"
    end
end

end # module

# This is the name checker implementation for the NaturalEarth R package.

# function(scale = 110,
#                          type = "countries",
#                          category = c("cultural", "physical", "raster"),
#                          full_url = FALSE) {
#   # check on permitted scales, convert names to numeric
#   scale <- check_scale(scale)

#   # check permitted category
#   category <- match_arg(category)


#   # add admin_0 to known types
#   if (type %in% c(
#     "countries",
#     "map_units",
#     "map_subunits",
#     "sovereignty",
#     "tiny_countries",
#     "boundary_lines_land",
#     "pacific_groupings",
#     "breakaway_disputed_areas",
#     "boundary_lines_disputed_areas",
#     "boundary_lines_maritime_indicator"
#   )) {
#     type <- paste0("admin_0_", type)
#   }


#   # add admin_1 to known types
#   # this actually just expands 'states' to the name including lakes
#   if (type == "states") {
#     type <- "admin_1_states_provinces_lakes"
#   }


#   if (category == "raster") {
#     # raster seems not to have so straightforward naming, so require that name
#     # is passed in type
#     file_name <- paste0(type)
#   } else {
#     file_name <- paste0("ne_", scale, "m_", type)
#   }


#   # https://naturalearth.s3.amazonaws.com/110m_cultural/ne_110m_admin_0_countries.zip
#   if (full_url) {
#     file_name <- paste0(
#       "https://naturalearth.s3.amazonaws.com/",
#       scale, "m_", category, "/",
#       file_name, ".zip"
#     )
#   }

#   return(file_name)
# }

# end  # end module
