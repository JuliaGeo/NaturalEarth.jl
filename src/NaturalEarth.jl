import GeoJSON
using Pkg.Artifacts

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