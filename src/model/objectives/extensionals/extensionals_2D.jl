struct SparseExtensionalFunction2D{T<:Real}
    components      ::Dict{Tuple{Int, Int}, T}
end

struct SparseExtensionalObjective2D<:ObjectiveFunction
    f           ::SparseExtensionalFunction2D
    type        ::ObjectiveType
end

"""
    evaluate_decision(obj::SparseExtensionalObjective2D, i1::Int, i2::Int)

Takes in a decision and returns the impact on the function

# Arguments
- `obj::SparseExtensionalObjective2D`: the function to be evaluated
- `i1::Int`: the index of the first point
- `i2::Int`: the index of the second point
"""
function evaluate_decision(obj::SparseExtensionalObjective2D, i1::Int, i2::Int)
    return obj.f.components[(i1, i2)]
end

"""
    evaluate_decisions(obj::SparseExtensionalObjective2D,decisions::Vector{Int})

Takes in a list of decisions and returns the impact on the function

# Arguments
- `obj::SparseExtensionalObjective2D`: the function to be evaluated
- `decisions::Vector{Int}`: the list
"""
function evaluate_decisions(obj::SparseExtensionalObjective2D,decisions::Vector{Int})
    sum = 0
    @inbounds for i in 1:length(decisions)-1
        sum += evaluate_decision(obj, decisions[i], decisions[i+1])
    end
    return sum
end

"""
    haskey(obj::SparseExtensionalObjective2D,i1::Int, i2::Int)

Takes in an arc and return its validity

# Arguments
- `obj::SparseExtensionalObjective2D`: the function to be evaluated
- `i1::Int`: the index of the first point
- `i2::Int`: the index of the second point
"""
function Base.haskey(obj::SparseExtensionalObjective2D,i1::Int, i2::Int)
    return Base.haskey(obj.f.components,(i1, i2))
end
