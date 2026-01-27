using GLUtilities
using Documenter

DocMeta.setdocmeta!(GLUtilities, :DocTestSetup, :(using GLUtilities); recursive=true)

makedocs(;
    modules=[GLUtilities],
    authors="Galen Lynch <galen@galenlynch.com>",
    sitename="GLUtilities.jl",
    format=Documenter.HTML(;
        canonical="https://galenlynch.github.io/GLUtilities.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/galenlynch/GLUtilities.jl",
    devbranch="main",
)
