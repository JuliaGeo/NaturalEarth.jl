using NaturalEarth
using Documenter

DocMeta.setdocmeta!(NaturalEarth, :DocTestSetup, :(using NaturalEarth); recursive=true)

makedocs(;
    modules=[NaturalEarth],
    authors="Anshul Singhvi <anshulsinghvi@gmail.com> and contributors",
    sitename="NaturalEarth.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="github.com/JuliaGeo/NaturalEarth.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGeo/NaturalEarth.jl",
    branch = "gh-pages",
    devbranch="main",
    push_preview = true,
)
