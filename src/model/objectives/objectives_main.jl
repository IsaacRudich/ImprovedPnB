@enum ObjectiveType minimization=0 maximization=1
abstract type ObjectiveFunction end

gettype(obj::T) where {T<:ObjectiveFunction} = obj.type

include("./geometry/geometry_main.jl")
include("./extensionals/extensionals_main.jl")