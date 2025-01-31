# NaturalEarth.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliageo.github.io/NaturalEarth.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliageo.github.io/NaturalEarth.jl/dev/)
[![Build Status](https://github.com/JuliaGeo/NaturalEarth.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaGeo/NaturalEarth.jl/actions/workflows/CI.yml?query=branch%3Amain)


This package provides a Julia interface to the [Natural Earth](http://www.naturalearthdata.com/) dataset. The Natural Earth dataset is a public domain map dataset available at 1:10m, 1:50m, and 1:110 million scales. It is ideal for small-scale thematic mapping and for creating static maps and illustrations.

Currently, this package provides a single function, `naturalearth`, which fetches any `.geojson` file from [this](https://github.com/nvkelso/natural-earth-vector/tree/master/geojson) repository. The function returns a `GeoJSON.FeatureCollection` object.

The data is downloaded on demand and cached using Julia's scratch space system. This means that the first time you fetch a dataset, it will take a while to download, and you will need an internet connection. Subsequent calls will be much faster, even in a new session.

## Quick start

You can install the Natural Earth package through the Julia package manager: `using Pkg; Pkg.add("NaturalEarth")`.  The main entry point is the `naturalearth(dataset, [scale])` function which returns a `GeoJSON.FeatureCollection` from [GeoJSON.jl](https://github.com/JuliaGeo/GeoJSON.jl).

```julia
using NaturalEarth
naturalearth("admin_0_countries", 110) # this resolves to `ne_110m_admin_0_countries.geojson`
naturalearth("10m_admin_0_countries")  # this gets the 10m-scale, but explicitly
```
These return `GeoJSON.FeatureCollections`, which you can either use as-is or convert to `DataFrames` (by `DataFrame(naturalearth(...))`).
## Acknowledgements

All datasets are provided by [Natural Earth](http://www.naturalearthdata.com/).

Initial development by [Haakon Ludvig Langeland Ervik](https://github.com/haakon-e)
