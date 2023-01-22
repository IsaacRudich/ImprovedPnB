abstract type RelaxedFrameworkNode <: Node end
#required values from parent: id-> UUID,  
#=additional required values: 
    exact -> Bool,
    layer -> Int
=#
getexactness(node::T) where{T<: RelaxedFrameworkNode}  = node.exact
setexactness(node::T,isexact::Bool) where{T<: RelaxedFrameworkNode} = node.exact = isexact

"""
    updatequeue!(queue::Vector{T}, layer::Vector{T},iterationcounter::Int,model::U, heuristic_ordering_packet::Any)where{T<:RelaxedFrameworkNode,U<:ProblemModel}

Determines which nodes from the layer should go in the refinement queue, and in which order

# Arguments
- `queue::Vector{T}`: The queue to update
- `layer::Vector{T}`: The nodes to choose from
- `iterationcounter::Int`: The number of times this function has been called on this layer
- `model::U`: The problem model
- `heuristic_ordering_packet::Any`: Pre-calculated heuristic information
"""
function updatequeue!(queue::Vector{T}, layer::Vector{T},iterationcounter::Int,model::U, heuristic_ordering_packet::Any)where{T<:RelaxedFrameworkNode,U<:ProblemModel}
    @inbounds for node in layer
        push!(queue, node)
    end
end