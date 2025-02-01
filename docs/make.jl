using NaturalEarth
using Documenter

DocMeta.setdocmeta!(NaturalEarth, :DocTestSetup, :(using NaturalEarth); recursive=true)

makedocs(;
    modules=[NaturalEarth],
    authors="Anshul Singhvi <anshulsinghvi@gmail.com> and contributors",
    sitename="NaturalEarth.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://juliageo.org/NaturalEarth.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="https://github.com/JuliaGeo/NaturalEarth.jl",
    devbranch="main",
    push_preview = true,
)
