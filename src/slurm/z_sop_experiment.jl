include("./PeelAndBound.jl")

run_sop_experiment(parse(Int,ARGS[1]), false,maximal,seed_solver=true)