using MultihistogramAnalysis
using CSV
using DataFrames
using ArgParse
using ProgressMeter

function parse_cli_args()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--ofile", "-o"
            help = "Output filename."
            default = "interpolates.csv"
            arg_type = String
        "--sourcedir", "-s"
            help = "Directory holding free energies and histograms."
            default = pwd()
            arg_type = String
        "--step"
            help = "Step size to take in T."
            default = 0.01
            arg_type = Float64
    end

    return parse_args(s)
end

function main()
    params = parse_cli_args()

    F_df = CSV.read(params["sourcedir"] * "/free_energy_10p.csv", DataFrame)
    directory_filter = [".ipynb_checkpoints", "Figures"]
    temperatures = Float64[]
    histograms   = DataFrame[]
    @showprogress "Reading histograms" for dir in filter(x -> !(x in directory_filter), readdir(params["sourcedir"]))
        try
            T = parse(Float64, dir)
            push!(temperatures, T)
            push!(histograms, CSV.read(params["sourcedir"] * "/" * dir * "/histogram.csv", DataFrame))
        catch e
            if e isa ArgumentError
                continue
            else
                rethrow(e)
            end
        end
    end

    MHData = MultihistogramData(2, temperatures, histograms)
    @assert all(F_df.T .== temperatures)
    MHData.free_energies = F_df.F

    Tcont = range(minimum(temperatures), maximum(temperatures), step = params["step"])
    U1  = zeros(length(Tcont))
    U2  = zeros(length(Tcont))
    M1  = zeros(length(Tcont))
    MA1 = zeros(length(Tcont))
    M2  = zeros(length(Tcont))
    MA2 = zeros(length(Tcont))

    progout = open(params["sourcedir"] * "/interpolation_progress.log", "w")
    P = Progress(length(Tcont), output = progout, showspeed = true)
    for idx in eachindex(Tcont)
        u1, u2 = interpolate_energy_second_moment_logsum(Tcont[idx], MHData; returnlinear = true)
#        ma1, ma2 = interpolate_observable_second_moment_abs_logsum(Tcont[idx], :M, MHData; returnlinear = true)
        U1[idx]  = u1
        U2[idx]  = u2
#        MA1[idx] = ma1
#        MA2[idx] = ma2

        next!(P)
    end

    df = DataFrame(
        :T   => Tcont,
        :U1  => U1,
        :U2  => U2
#        :MA1 => MA1,
#        :MA2 => MA2
    )
    CSV.write(params["sourcedir"] * "/" * params["ofile"], df)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
