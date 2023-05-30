using HierarchicalLattices
using CSV
using DataFrames
using Graphs
using MetaGraphs
using StatsBase
using Statistics
using Trapz
using Logging

function create_histogram_df(histogram_fit)
	xdata = histogram_fit.edges[1]
	ydata = histogram_fit.edges[2]

	xx = [x for _ in ydata[1:end-1] for x in xdata[1:end-1]]
	yy = [y for y in ydata[1:end-1] for x in xdata[1:end-1]]
	zz = vec(histogram_fit.weights)

	return DataFrame(
		:M => xx,
		:U => yy,
		:f => zz
	)
end

function simulate_and_return_hist!(wolffdata, nsteps, temperature;
		showprogress = false, verbose = false, progressoutput = stdout)
	wolff!(wolffdata, nsteps, temperature; showprogress = showprogress, verbose = verbose, progressoutput = progressoutput)

	M = @view(wolffdata.magnetization_history[1:end])
	U = @view(wolffdata.internalenergy_history[1:end])

	min_M, max_M = minimum(M), maximum(M)
	min_U, max_U = minimum(U), maximum(U)
	dU = round(minimum(filter(!=(0), unique(abs.(diff(U))))), digits = 3)
	dM = round(minimum(filter(x -> x != 0 && x > 1e-2, unique(abs.(diff(M))))), digits = 3)

	if verbose
		@info "Fitting histogram"
	end
	hist = fit(Histogram, (M, U), (min_M:dM:max_M+dM, min_U:dU:max_U+dU))
	hist_df = create_histogram_df(hist)

	return hist_df
end

function run_and_save(wolffdata, nsteps, temperature, params; showprogress = false, verbose = false, progressoutput = stdout)
	N = length(wolffdata.lattice.final_state.vprops)
	df = simulate_and_return_hist!(wolffdata, nsteps, temperature; showprogress = showprogress, verbose = verbose, progressoutput = progressoutput)
	hist = Tables.columntable(df)
	df = nothing

    # Write metadata file
    if !isdir(string(temperature))
        mkdir(string(temperature))
    end

    open(string(temperature) * "/metadata.ini", "w") do f
        write(f, "[Lattice]\n")
        write(f, "order $(params[:order])\n")
        write(f, "depth $(params[:depth])\n")
        write(f, "coupling $(params[:coupling])")
        write(f, "nsteps $(nsteps)\n")
        write(f, "nspins $N\n\n")

        write(f, "[Autocorrelation]\n")
        write(f, "autotime $(params[:autocortime])\n")
    end

    CSV.write(string(temperature) * "/histogram.csv", hist)

	hist = nothing
	wolffdata.magnetization_history = Float64[]
	wolffdata.internalenergy_history = Float64[]

	GC.gc()
end

function start_simulation_and_logger(wolffdata, nsteps, T, params; showprogress = true, verbose = true)
	if !isdir(string(T))
		mkdir(string(T))
	end

	logfile_path = string(T) * "/simlog.log"
	progressfile_path = string(T) * "/simprog.log"
	logio = open(logfile_path, "w")
	progio = open(progressfile_path, "w")

	logger = SimpleLogger(logio)
	with_logger(logger) do
		run_and_save(wolffdata, nsteps, T, params; showprogress = showprogress, verbose = verbose, progressoutput = progio)
	end
	close(logio)
	close(progio)
end