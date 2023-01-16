# NaturalEarth.jl

This package provides a Julia interface to the [Natural Earth](http://www.naturalearthdata.com/) dataset. The Natural Earth dataset is a public domain map dataset available at 1:10m, 1:50m, and 1:110 million scales. It is ideal for small-scale thematic mapping and for creating static maps and illustrations.

Currently, this package provides a single function, `naturalearth`, which fetches any `.geojson` file from [this](https://github.com/nvkelso/natural-earth-vector/tree/master/geojson) repository. The function returns a `GeoJSON.FeatureCollection` object.

The data is downloaded on demand and cached using the Julia Artifacts system. This means that the first time you fetch a dataset, it will take a while to download. Subsequent calls will be much faster.

## Acknowledgements

All datasets are provided by [Natural Earth](http://www.naturalearthdata.com/).

Initial development by [Haakon Ludvig Langeland Ervik](https://github.com/haakon-e)