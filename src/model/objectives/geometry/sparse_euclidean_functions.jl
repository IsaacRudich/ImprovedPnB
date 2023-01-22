struct Euc2DFunction
    components  ::Dict{Int, Point2D}
    rounded     ::Bool
end

struct Euc3DFunction
    components  ::Dict{Int, Point3D}
    rounded     ::Bool
end

struct Euc2DObjective<:ObjectiveFunction
    f           ::Euc2DFunction
    type        ::ObjectiveType
end

struct Euc3DObjective<:ObjectiveFunction
    f           ::Euc3DFunction
    type        ::ObjectiveType
end

Euc2DObjective(map::Dict{Int, Point2D}, rounded::Bool,type::ObjectiveType) = Euc2DObjective(Euc2DFunction(map,rounded),type)
Euc3DObjective(map::Dict{Int, Point3D}, rounded::Bool,type::ObjectiveType) = Euc3DObjective(Euc3DFunction(map,rounded),type)

"""
    evaluate_decision(f::Euc2DFunction, i1::Int, i2::Int)

Takes in a decision and returns the impact on the function

# Arguments
- `f::Euc2DFunction`: the function to be evaluated
- `i1::Int`: the index of the first point
- `i2::Int`: the index of the second point
"""
function evaluate_decision(f::Euc2DFunction, i1::Int, i2::Int)
    if f.rounded
        return euclidean_2D_rounded(i1::Int,i2::Int, f.components)
    else
        return euclidean_2D(i1::Int,i2::Int, f.components)
    end
end

"""
    evaluateDecision(f::Euc3DFunction, i1::Int, i2::Int)

Takes in a decision and returns the impact on the function

# Arguments
- `f::Euc3DFunction`: the function to be evaluated
- `i1::Int`: the index of the first point
- `i2::Int`: the index of the second point
"""
function evaluate_Decision(f::Euc3DFunction, i1::Int, i2::Int)
    if f.rounded
        return euclidean_3D_rounded(i1::Int,i2::Int, f.components)
    else
        return euclidean_3D(i1::Int,i2::Int, f.components)
    end
end

"""
    evaluate_decision(o::Union{Euc2DObjective,Euc3DObjective}, i1::Int, i2::Int)

Takes in a decision and returns the impact on the objective

# Arguments
- `f::Union{Euc2DObjective,Euc3DObjective}`: the objective to be evaluated
- `i1::Int`: the index of the first point
- `i2::Int`: the index of the second point
"""
function evaluate_decision(o::Union{Euc2DObjective,Euc3DObjective}, i1::Int, i2::Int)
    evaluate_decision(o.f, i1, i2)
end

"""
    evaluate_decisions(o::Union{Euc2DObjective,Euc3DObjective}, decisions::Vector{T})where{T<:Int}

Takes in a sequence of decsions and returns the value of that sequence
Returns: <:Real

# Arguments
- `f::Union{Euc2DObjective,Euc3DObjective}`: the objective to be evaluated
- `decisions::Vector{T}`: the index of the first point
"""
function evaluate_decisions(o::Union{Euc2DObjective,Euc3DObjective}, decisions::Vector{T})where{T<:Int}
    value = 0
    @inbounds for i in 1:length(decisions)-1
        value += evaluate_decision(o.f, decisions[i], decisions[i+1])
    end
    return value
end
