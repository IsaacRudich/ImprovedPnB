abstract type RestrictedAllDiffNode <:RestrictedFrameworkNode end
#=
required values from parent
    id                      ::UUID
    path                    ::Vector{Int}
    value                   ::T
    domain                  ::BitVector
added values
    visited                 ::BitVector
=#

getvisited(node::T) where{T<:RestrictedAllDiffNode} = node.visited

"""
    initialize_domain(model::T)where{T<:SequencingModel}

initalize the domain given a sequencing problem

# Arguments
- `model::T`: the problem instance
"""
function initialize_domain(model::T)where{T<:SequencingModel}
    return trues(length(model))
end

"""
    initialize_visited(model::T)where{T<:SequencingModel}

initalize the visited labels given a sequencing problem

# Arguments
- `model::T`: the problem instance
"""
function initialize_visited(model::T)where{T<:SequencingModel}
    return falses(length(model))
end