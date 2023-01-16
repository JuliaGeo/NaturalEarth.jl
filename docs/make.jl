using NaturalEarth
using Documenter

DocMeta.setdocmeta!(NaturalEarth, :DocTestSetup, :(using NaturalEarth); recursive=true)

makedocs(;
    modules=[NaturalEarth],
    authors="Anshul Singhvi <anshulsinghvi@gmail.com> and contributors",
    repo="https://github.com/asinghvi17/NaturalEarth.jl/blob/{commit}{path}#{line}",
    sitename="NaturalEarth.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://asinghvi17.github.io/NaturalEarth.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/asinghvi17/NaturalEarth.jl",
    devbranch="main",
)
