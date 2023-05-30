begin
    using HierarchicalLattices
    using CSV
    using DataFrames
    using Graphs
    using MetaGraphs
    using StatsBase
    using Statistics
    using Trapz
    
    O = 5
    nsweeps = 3_000_000
    sweepstep = 10
    sweepulim = 100
end


function create_histogram_df(histogram_fit)
	xdata = histogram_fit.edges[1]
	ydata = histogram_fit.edges[2]

	xx = [x for y in ydata[1:end-1] for x in xdata[1:end-1]]
	yy = [y for y in ydata[1:end-1] for x in xdata[1:end-1]]
	zz = vec(histogram_fit.weights)

	return DataFrame(
		:M => xx,
		:U => yy,
		:f => zz
	)
end

function generate_autocor_data(M, sweepstep, sweepulim)
    step = sweepstep * N
    ulim = sweepulim * N
    xdata = collect(1:step:ulim)
    ydata = autocor(M, xdata)
    return xdata, ydata
end

function estimate_autocor(sweep, autocorfn; rtol = 1e-2, maxiters = 1000)
    err = 2rtol
    upperlim = 2
    oldestimate = trapz(sweep[1:upperlim], autocorfn[1:upperlim])
    newestimate = 0
    while err > rtol
        upperlim += 1
        newestimate = trapz(sweep[1:upperlim], autocorfn[1:upperlim])
        rtol = newestimate - oldestimate
        if upperlim > maxiters || upperlim  >= length(autocorfn)
            break
        end
    end
    return newestimate
end

if abspath(PROGRAM_FILE) == @__FILE__
    # Temperature Range
    Ts = [1:0.1:4;]

    L = diamond_ising_lattice(O, :zero)
    N = length(vertices(L))
    lattice = IsingData(L, O)

    for (idx, T) in enumerate(Ts)
        @info "T = $T"
        # Copy over the final state for next run
        global lattice = IsingData(deepcopy(lattice.final_state))

        # Evolve lattice
        @info "Evolving Lattice"
	    metropolis!(lattice, nsweeps*N, T, showprogress = true)
        fill_data!(lattice, :M, showprogress = true)
        fill_data!(lattice, :U, showprogress = true)

        @info "Calculating Autocorrelation Time..."
        sweep, autocorfn = generate_autocor_data(lattice.magnetization_history, sweepstep, sweepulim)
        autocor_time = 10*estimate_autocor(sweep, autocorfn) * N
        A = round(Integer, autocor_time)
        if A < N*nsweeps
            M = @view(lattice.magnetization_history[2*A:end])
            U = @view(lattice.internalenergy_history[2*A:end])
        else
            M = @view(lattice.magnetization_history[1:end])
            U = @view(lattice.internalenergy_history[1:end])
        end


        # Write metadata file
        if !isdir(string(T))
            mkdir(string(T))
        end
        open(string(T) * "/metadata.ini", "w") do f
            write(f, "[Lattice]\n")
            write(f, "T $T\n")
            write(f, "order $O\n")
            write(f, "nsweeps $nsweeps\n")
            write(f, "nspins $N\n\n")

            write(f, "[Autocorrelation]\n")
            write(f, "autotime $autocor_time\n")
            write(f, "upperlim $sweepulim\n")
            write(f, "stepsize $sweepstep\n")
        end

        # Fit Histogram
        min_M, max_M = minimum(M), maximum(M)
        min_U, max_U = minimum(U), maximum(U)
        dM = 2
        dU = 4
        energybins = min_U:dU:max_U+dU
        magnetbins = min_M:dM:max_M+dM

        @info "Fitting Histogram..."
        hist = fit(Histogram, (M, U), (magnetbins, energybins))
        hist_df = create_histogram_df(hist)

        @info "Writing Histogram to CSV..."
        CSV.write(string(T) * "/histogram.csv", hist_df)

        GC.gc()
    end

end
