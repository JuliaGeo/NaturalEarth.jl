module NaturalEarth

import GeoJSON, LightXML
using Pkg
using Pkg.Artifacts
using p7zip_jll
using Scratch
using Downloads
using LightXML

download_cache = ""

"A list of the names of available artifacts"
const available_artifacts = collect(keys(
    Artifacts.select_downloadable_artifacts(Artifacts.find_artifacts_toml(@__FILE__); include_lazy=true)
))

export naturalearth, bathymetry

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
    elseif dataset_name ∈ available_rasters
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

function _unpack_zip(zipfile, outputdir)
    out = Pipe()
    err = Pipe()
    try
        run(pipeline(`$(p7zip_jll.p7zip()) e $zipfile -o$outputdir -y `, stdout = out, stderr = err))
    catch e
        printstyled("Error while unzipping!"; bold = true, color = :red)
        println()
        printstyled("Stdout:"; bold = false, color = :blue)
        println(read(out, String))
        printstyled("Stderr:"; bold = false, color = :red)
        println(read(err, String))
        rethrow(e)
    end
end

function _download_unpack(url::String, path = splitext(basename(url))[1])
    scratchspace = Scratch.@get_scratch!("rasters")
    unpack_path = mkpath(joinpath(scratchspace, path))
    zipfile = Downloads.download(url)
    _unpack_zip(zipfile, unpack_path)
end

function __init__()
    global download_cache = Scratch.get_scratch!(@__MODULE__, "rasters")
end

end  # end module
