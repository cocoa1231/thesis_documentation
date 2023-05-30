using CSV
using DataFrames
using MultihistogramAnalysis
using ArgParse
using ProgressMeter

function parse_cli_args()
    s = ArgParseSettings()

    @add_arg_table!  s begin
        "--rtol"
            help = "Tolerance for the accuracy (in number of digits) of free energies."
            default = 7
            arg_type = Int
        "--ofile", "-o"
            help = "Output filename."
            default = "free_energies.csv"
            arg_type = String
        "--sourcedir", "-s"
            help = "Source directory holding folders named with temperatures."
            default = pwd()
            arg_type = String
    end

    return parse_args(s)
end


function main()
    params = parse_cli_args()

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
    @show length(histograms), length(temperatures)
    MHData = MultihistogramData(2, temperatures, histograms)

    @info "Calculating free energy estimates"
    calculate_free_energies!(MHData; rtol = 10.0^(-params["rtol"]), logsum = true)
    
    F = DataFrame(:T => temperatures, :F => MHData.free_energies)
    CSV.write(params["sourcedir"] * "/" * params["ofile"], F)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
