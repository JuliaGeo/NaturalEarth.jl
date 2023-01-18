module NaturalEarth

import GeoJSON
using Pkg
using Pkg.Artifacts

const available_artifacts = collect(keys(
    Artifacts.select_downloadable_artifacts(Artifacts.find_artifacts_toml(@__FILE__); include_lazy=true)
))

export naturalearth, bathymetry

"""
    naturalearth(name::String)

Load a NaturalEarth dataset as a `GeoJSON.FeatureCollection` object.

Valid names are found in `Artifacts.toml`. 
We aim to support all datasets listed in https://github.com/nvkelso/natural-earth-vector/tree/master/geojson
"""
function naturalearth(name::String)
    pth = @artifact_str("$name/$name.geojson")
    @assert isfile(pth) "`$name` is not a valid NaturalEarth.jl artifact"
    GeoJSON.read(read(pth, String))
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



end  # end module
