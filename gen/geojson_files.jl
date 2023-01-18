import HTTP
import JSON3

# Should point to latest release of: https://github.com/nvkelso/natural-earth-vector
const NATURALEARTH_TAG = "v5.1.2"

"""
    get_naturalearth_geojson_metadata(;[tag = NATURALEARTH_TAG])

Fetch list of geojson files available for download at the selected tag.

Looks for .geojson files in: https://github.com/nvkelso/natural-earth-vector/tree/<tag>/geojson

Returns a list of NamedTuples on the form `(; name, url, lazy)`. `name` is the name of the artifact, `url` is the url 
to download the file from, and `lazy` is a boolean indicating whether the artifact should be installed lazily or not.
"""
function get_naturalearth_geojson_metadata(;tag = NATURALEARTH_TAG)
    req = HTTP.request("GET", "https://api.github.com/repos/nvkelso/natural-earth-vector/git/trees/$tag")
    contents = String(req.body)  # get body of request
    obj = JSON3.read(contents)  # parse JSON

    tree = obj["tree"];  # get file tree
    # filter for geojson directory
    geojson_dir = filter(t -> t["path"] == "geojson" && t["type"] == "tree", tree) |> only 

    # get list of files in geojson directory
    req_geojson = HTTP.request("GET", geojson_dir["url"])
    obj = JSON3.read(String(req_geojson.body))
    tree = obj["tree"]
    names = [t["path"] for t in tree]  # get list of file names. These should all be geojson files
    @assert all(endswith.(names, ".geojson"))

    download_url(name) = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/$tag/geojson/$name"

    # list of artifacts to be non-lazy:
    nonlazy = ("ne_50m_coastline.geojson", "ne_110m_coastline.geojson", )
    islazy(name) = name ∉ nonlazy

    # create a list of artifacts
    artifacts = [(; name=split(name, ".")[1], url=download_url(name), lazy=islazy(name)) for name in names]
    return artifacts
end
