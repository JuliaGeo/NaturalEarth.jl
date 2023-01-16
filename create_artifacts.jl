using Pkg.Artifacts
using SHA

# This is the path to the Artifacts.toml we will manipulate
artifact_toml = joinpath(@__DIR__, "Artifacts.toml")

# artifacts = [
#     (; name="ne_10m_coastline", url="https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_coastline.geojson", lazy=true),
# ]
include("geojson_files.jl")
artifacts = _get_artifacts_names()

for artifact in artifacts
    (; name, url, lazy) = artifact

    # Query the `Artifacts.toml` file for the hash bound to `artifact.name`
    # (returns `nothing` if no such binding exists)
    data_hash = artifact_hash(name, artifact_toml)

    # If the name was not bound, or the hash it was bound to does not exist, create it!
    if isnothing(data_hash) || !artifact_exists(data_hash)
        # create_artifact() returns the content-hash of the artifact directory once we're finished creating it
        contents_hash = ""  # Capture the path to the artifact from the `do` block
        data_hash = create_artifact() do artifact_dir
            path = joinpath(artifact_dir, last(split(url, "/")))
            download(url, path)
            contents_hash = bytes2hex(open(sha256, path))
        end

        # Now bind that hash within our `Artifacts.toml`.  `force = true` means that if it already exists,
        # just overwrite with the new content-hash.  Unless the source files change, we do not expect
        # the content hash to change, so this should not cause unnecessary version control churn.
        download_info = [(url, contents_hash),]
        bind_artifact!(artifact_toml, name, data_hash; lazy, download_info)
    end

end
