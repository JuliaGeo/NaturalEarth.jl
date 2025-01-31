using NaturalEarth
using Documenter

DocMeta.setdocmeta!(NaturalEarth, :DocTestSetup, :(using NaturalEarth); recursive=true)

makedocs(;
    modules=[NaturalEarth],
    authors="Anshul Singhvi <anshulsinghvi@gmail.com> and contributors",
    repo="github.com/JuliaGeo/NaturalEarth.jl",
    sitename="NaturalEarth.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://juliageo.github.io/NaturalEarth.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGeo/NaturalEarth.jl",
    devbranch="main",
)
