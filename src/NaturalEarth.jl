module NaturalEarth

import GeoJSON
using Scratch

const naturalearth_cache = Ref{String}("")

function __init__()
    global naturalearth_cache

    naturalearth_cache[] = @get_scratch!("naturalearth")
end

export naturalearth, bathymetry

"""
    naturalearth(name::String)

Load a NaturalEarth dataset as a `GeoJSON.FeatureCollection` object.

Valid names are found in `Artifacts.toml`. 
We aim to support all datasets listed in https://github.com/nvkelso/natural-earth-vector/tree/master/geojson
"""
function naturalearth(full_name::String)
    filename = "ne_" * full_name * ".geojson"
    if isfile(joinpath(naturalearth_cache[], filename))
        return GeoJSON.read(read(joinpath(naturalearth_cache[], filename), String))
    else
        try
            download("https://rawcdn.githack.com/nvkelso/natural-earth-vector/v5.1.2/geojson/$filename", joinpath(naturalearth_cache[], filename))
            return GeoJSON.read(read(joinpath(naturalearth_cache[], filename), String))
        catch e
            if e isa RequestError
                error("Could not download file $filename. Check the name and try again.")
            else
                rethrow(e)
            end
        end
    end
end

function naturalearth(name::String, scale::Int)
    @assert scale in (10, 50, 110) "`scale` must be one of 10, 50, or 110.  Got $scale."

    return naturalearth("$(scale)m_$(name)")
end

"""
    bathymetry(contour::Int = 2000)

Convenient acccess to ocean bathymetry datasets.
Currently tested on: https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-bathymetry/
The function returns a MultiPolygon describing the bathymetry at a given depth contour.
The following depths should be available: [10000, 9000, 8000, 7000, 6000, 5000, 4000, 3000, 2000, 1000, 200, 0]
"""
function bathymetry(contour::Int=2000)
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

function _download_url(name, scale)
    return "https://rawcdn.githack.com/nvkelso/natural-earth-vector/v5.1.2/geojson/$(geojson_file_name(name, scale))"
end

geojson_file_name(name, scale) = "ne_$(scale)m_$(name).geojson"


end  # end module
