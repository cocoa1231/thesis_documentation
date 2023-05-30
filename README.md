# Documentation of Thesis Scripts Used

Install julia using the [juliaup](https://github.com/JuliaLang/juliaup)
installer. Once installed, launch a Julia REPL and type `]` to enter Pkg mode.
There you can type `add <Package>` to add a package to the default environment.
Reference for installing IJulia kernel is provided [on their documentation
website](https://github.com/JuliaLang/IJulia.jl). If the notebooks complain some
package is not available, install it using the Julia REPL Pkg mode. To install
`HierarchicalLattices.jl` and `MultihistogramAnalysis.jl` you can do the
following since the packages are not yet registered on the Julia package repos.

```julia
]add https://github.com/cocoa1231/HierarchicalLattices.jl
]add https://github.com/cocoa1231/MultihistogramAnalysis.jl
```

Note the `]` is to indicate that this should be done in the Pkg mode. Do not
type it if you are already in Pkg mode.

The documentation for both the packages can be found on their GitHub
repositories. Here are quick links to the docs.

- [HierarchicalLattices.jl](https://cocoa1231.github.io/HierarchicalLattices.jl)
- [MultihistogramAnalysis.jl](https://cocoa1231.github.io/MultihistogramAnalysis.jl)

