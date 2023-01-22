@enum PeelSetting frontier lastexactnode maximal

include("./construct_restricted_dd.jl")
include("./diagram_search.jl")
include("./refine_relaxed_dd.jl")
include("./peel_and_bound_subroutines.jl")
include("./peel_and_bound.jl")
include("./parallel_peel_and_bound.jl")