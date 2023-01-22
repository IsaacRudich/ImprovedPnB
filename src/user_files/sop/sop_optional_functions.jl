#=
    for Restricted Decision Diagrams
=#
"""
    restricted_node_trim_heuristic(node::SOP_Restricted_Node, heuristic_packet) 

A heuristic method that assigns a relaxed bound to a node

# Arguments
- `node::SOP_Restricted_Node`: The node
- `heuristic_packet`: The precalculated information used by the heuristic
"""
function restricted_node_trim_heuristic(node::SOP_Restricted_Node, heuristic_packet) 
    return sop_rrb(getvisited(node), getstate(node), getvalue(node), heuristic_packet[1],heuristic_packet[2])
end

#=
    for Relaxed Decision Diagrams
=#

#=
    Subroutines (not overiding any existing functions, just useful for SOP)
=#
"""
    create_relaxed_root_node(model::SOP_Model,node::SOP_Relaxed_Node)

Creates and returns relaxed root node and its domain from a problem model
Returns ::SOP_Relaxed_Node, ::BitVector

# Arguments
- `model::SOP_Model`: The problem model
- `node::SOP_Relaxed_Node: only here to abuse multiple dispatch
"""
function create_relaxed_root_node(model::SOP_Model,node::SOP_Relaxed_Node)
    restrictednode = create_restricted_root_node(model,SOP_Restricted_Node())
    return SOP_Relaxed_Node(
        length(restrictednode),#layer::Int
        getstate(restrictednode),#state::Int 
        0,#lengthtoroot::T
        0,#lengthtoterminal::T
        falses(length(model)),#allup::BitVector
        copy(getvisited(restrictednode)),#alldown::BitVector
        falses(length(model)),#someup::BitVector
        copy(getvisited(restrictednode)),#somedown::BitVector
        true,#exact::Bool
        Vector{SOP_Relaxed_Node}(),#parents::Vector{SOP_NODE}
        Vector{SOP_Relaxed_Node}()#children::Vector{SOP_NODE}
    ), getdomain(restrictednode)
end

"""
    filter_out_arc_check(parent::SOP_Relaxed_Node, child::SOP_Relaxed_Node, model::SOP_Model, bestknownvalue::Union{Nothing, T}, values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}})where{T<:Real}
Check if an arc is removable, return true if it is

# Arguments
- `parent::T`: the parent node
- `child::T`: the child node
- `model::P`: the sequencing problem being evaluated
- `bestknownvalue::Union{Nothing, U}`: the best known solution value
- `values::Dict{Int, Vector{Tuple{Int, T}}}`: pre-calculated heuristic information
- `lastarc::Vector{Tuple{Int, T}}`: pre-calculated heuristic information
"""
function filter_out_arc_check(parent::SOP_Relaxed_Node, child::SOP_Relaxed_Node, model::SOP_Model, bestknownvalue::Union{Nothing, T}, values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}})where{T<:Real}
    #default checks that can be done on any sequencing problem 
    @inline if filter_out_arc_alldiff_check(parent, child, model, bestknownvalue)
        return true
    end

    #handle precedence constraints
    @inline if filter_out_arc_precedence_check(parent,child,model)
        return true
    end

    #handle heuristic bounding 
    if length(model)-getlayer(child)>2
        if !isnothing(bestknownvalue) && getlayer(child)!=length(model)
            if is_better_solution_value(model, bestknownvalue, sop_rrb(model, parent, child, values,lastarc))
                return true
            end
        end
    end

    #cannot remove
    return false
end