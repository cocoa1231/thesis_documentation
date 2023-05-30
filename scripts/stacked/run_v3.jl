using Distributed
using Logging

@info "Loading functions and libs everywhere"
@everywhere include("includes_v3.jl")

@info "Creating lattice everywhere"
@everywhere begin
	order = 4
	depth = 15
	coupling = parse(Float64, splitpath(pwd())[end])
	save_interval = 50
	thermalization_steps = 100

	lattice = DiamondLattice(diamond_ising_lattice(order, :infty), order)
	N = length(lattice.final_state.vprops)
	nsteps = 100_000_000
	WD = WolffData(lattice, Float64[], Float64[], save_interval, thermalization_steps)
end

function removeprocs()
	t = rmprocs(workers()...; waitfor = 60)
	wait(t)
end

f = open("Tcrit.txt", "r")
Tc = parse(Float64, readline(f))
close(f)

Trange = range(Tc-2, Tc+2, step = 0.1)

@info "Running tasks"
@sync for t in Trange
	params = Dict(
		:order => order,
		:depth => depth,
		:coupling => coupling,
		:autocortime => false
	)
	@async @spawnat :any start_simulation_and_logger(WD, nsteps, t, params; showprogress = true, verbose = true)
end

@everywhere GC.gc()

@info "Removing processes"
t = rmprocs(workers()...; waitfor = 60)
wait(t)

exit(0)
