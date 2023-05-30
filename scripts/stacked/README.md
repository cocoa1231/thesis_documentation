# Stacked Diamond Lattice Runs

This has the most SLOC in this repo, so the documentation is divided into
sections.

## `run_v3.jl` and `includes_v3.jl`

These are the libraries used to run simulations for an order 4 depth 15 stacked
diamond lattice with variable coupling strength. Place these two files in a
directory that can be parsed as a Float64 indicating the stacking weight (bond
strength in spatial direction). `run_v3.jl` takes no command line arguments,
however parameters can be changed at the start of the file in the `@everywhere`
section below the `"Creating lattice everywhere"` log line. The directory that
this file exists in must also have `Tcrit.txt`, however this can be changed on
lines 26 to 28. This script utilizes distributed computing, and so if your julia
session is launched with 10 processes, 10 temperatures will be simultaniously
simulated at. `includes_v3.jl` are utility functions.

## `calculate_free_energies.jl` and `free_enery.sh`

The Julia script takes in a source directory, i.e, a directory containing
directories with the name of the directories being the temperatures simulated at
and the histogram in `histogram.csv` and outputs the free energy using
`MultihistogramAnalysis.jl` to `free_energies.csv` in that directory. Use
`--help` to get help for this script.

The bash script should be placed in the directory containing the directories
that label stacking weights. In a file named `remaining_temperatures_interp.txt`
write on each line which stacking weights are remaining (I know confusing name)
for which you need to calculate free energies and the script will run the Julia
script for all those directories simultaniously.

If you're confused about the directory structure, for a simulation of a stacked
lattice with stacking weight `K` at temperature `T`, the histogram should be at
`K/T/histogram.csv`. Use the diagram below as a reference for where these two
scripts go.

```text
K                                                           /T/histogram.csv
^
Contains both scripts and remaining_temperatures_interp.txt
```

Figure 1: A very helpful and informative diagram /s.

## `interpolate_MH.jl` and `interpolate_data.sh`

This is to be run after free energies have been calculated. Right now this
script will look for `free_energy_10p.csv` in the source directory given and use
those to interpolate the first and second moment of the internal energy
distribution across the temperature range of the simulation. This will be saved
in `interpolates.csv` and can then later be used to find the peak of the
specific heat as the critical temperature.

`interpolate_data.sh` does the same thing as `free_energy.sh`. It will take in
the list of remaining coupling strength directories as
`remaining_temperatures_interp.txt` and run `interpolate_MH.jl`
