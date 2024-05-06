module NaturalEarth

import GeoJSON, Downloads
using Scratch

const naturalearth_cache = Ref{String}("")

function __init__()
    # Populate the cache by obtaining a directory for the 
    # scratchspace.
    global naturalearth_cache
    naturalearth_cache[] = @get_scratch!("naturalearth")
end

export naturalearth, bathymetry

"""
    naturalearth(name::String; version = v"5.1.2")
    naturalearth(name::String, scale::Int; version = v"5.1.2")

Load a NaturalEarth dataset as a `GeoJSON.FeatureCollection` object.

The `name` should not include the `ne_` prefix, and if providing a `scale` should also not include a scale.  No suffix should be added.

For example, to get the `ne_110m_admin_0_countries` dataset, you could use:

```julia
naturalearth("admin_0_countries", 110)
naturalearth("110m_admin_0_countries")
```

We aim to support all datasets listed in https://github.com/nvkelso/natural-earth-vector/tree/master/geojson.

!!! warning
    This function downloads files from the Internet when not found locally.
"""
function naturalearth(full_name::String; version::Union{VersionNumber, String} = v"5.1.2")
    filename = full_name
    # Ensure `ne` prefix
    if !startswith(full_name, "ne_")
        filename = "ne_" * filename
    end
    # and `.geojson` suffix
    if !endswith(filename, ".geojson")
        filename = filename * ".geojson"
    end
    # Create a String object from the version number
    version_string = version isa VersionNumber ? "v" * string(version) : version

    # First, check that the appropriate path exists
    if !ispath(joinpath(naturalearth_cache[], version_string))
        mkpath(joinpath(naturalearth_cache[], version_string))
    end
    # Check that version's cache before downloading
    filepath = joinpath(naturalearth_cache[], version_string, filename)
    if !isfile(filepath)
        # Download from Githack CDN
        # We could change this later, to use zipped Shapefiles and return a GeoDataFrame or something
        try
            Downloads.download("https://rawcdn.githack.com/nvkelso/natural-earth-vector/$version_string/geojson/$filename", filepath)
        catch e
            if e isa Downloads.RequestError
                @error("NaturalEarth.jl: Could not download file $filename. Check the name and try again.")
                rethrow(e)
            else
                rethrow(e)
            end
        end
    end
    return GeoJSON.read(read(filepath, String))
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
The following depths should be available: `[10000, 9000, 8000, 7000, 6000, 5000, 4000, 3000, 2000, 1000, 200, 0]`
"""
function bathymetry(contour::Int=2000)
    # extract a list of all available bathymetry files
    available_depths = [10000, 9000, 8000, 7000, 6000, 5000, 4000, 3000, 2000, 1000, 200, 0]
    # Extract the file corresponding to the contour
    fileind = findfirst(==(contour), available_depths)
    isnothing(fileind) && error("Contour $contour not found. Available contours: $(sort(depths))")
    # Open bathymetry file.  They are prefixed by a letter corresponding to depth in reverse order from A to K,
    # so we perform a bit of arithmetic to obtain that.
    return naturalearth("10m_$('A' + (fileind - 1))_$(contour)")
end

geojson_file_name(name, scale) = "ne_$(scale)m_$(name).geojson"


end  # end module
