#=
    for Restricted Decision Diagrams
=#
"""
    restricted_node_trim_heuristic(node::TSPTW_Restricted_Node, heuristic_packet) 

A heuristic method that assigns a relaxed bound to a node

# Arguments
- `node::TSPTW_Restricted_Node`: The node
- `heuristic_packet`: The precalculated information used by the heuristic
"""
function restricted_node_trim_heuristic(node::TSPTW_Restricted_Node, heuristic_packet) 
    return tsptw_rrb(getvisited(node), getstate(node), getvalue(node), heuristic_packet[1],heuristic_packet[2])
end

"""
    restricted_node_trim_heuristic(node::TSPTWM_Restricted_Node, heuristic_packet) 

A heuristic method that assigns a relaxed bound to a node

# Arguments
- `node::TSPTWM_Restricted_Node`: The node
- `heuristic_packet`: The precalculated information used by the heuristic
"""
function restricted_node_trim_heuristic(node::TSPTWM_Restricted_Node, heuristic_packet) 
    return tsptwm_rrb(getvisited(node), getstate(node), getvalue(node), heuristic_packet[1],heuristic_packet[2],heuristic_packet[3],heuristic_packet[4])
end

#=
    for Relaxed Decision Diagrams
=#

#=
    Subroutines (not overiding any existing functions, just useful for TSPTW)
=#
"""
    create_relaxed_root_node(model::TSPTW_Model,node::TSPTW_Relaxed_Node)

Creates and returns relaxed root node and its domain from a problem model
Returns ::TSPTW_Relaxed_Node, ::BitVector

# Arguments
- `model::TSPTW_Model`: The problem model
- `node::TSPTW_Relaxed_Node: only here to abuse multiple dispatch
"""
function create_relaxed_root_node(model::TSPTW_Model,node::TSPTW_Relaxed_Node)
    restrictednode = create_restricted_root_node(model,TSPTW_Restricted_Node())
    return TSPTW_Relaxed_Node(
        length(restrictednode),#layer::Int
        getstate(restrictednode),#state::Int 
        0.0,#lengthtoroot::T
        0.0,#lengthtoterminal::T
        falses(length(model)),#allup::BitVector
        copy(getvisited(restrictednode)),#alldown::BitVector
        falses(length(model)),#someup::BitVector
        copy(getvisited(restrictednode)),#somedown::BitVector
        true,#exact::Bool
        Vector{TSPTW_Relaxed_Node}(),#parents::Vector{TSPTW_NODE}
        Vector{TSPTW_Relaxed_Node}(),#children::Vector{TSPTW_NODE}
        0.0,#earliest completion time
        0.0#latest_start_time::Int
    ), getdomain(restrictednode)
end

"""
    create_relaxed_root_node(model::TSPTWM_Model,node::TSPTWM_Relaxed_Node)

Creates and returns relaxed root node and its domain from a problem model
Returns ::TSPTWM_Relaxed_Node, ::BitVector

# Arguments
- `model::TSPTWM_Model`: The problem model
- `node::TSPTWM_Relaxed_Node: only here to abuse multiple dispatch
"""
function create_relaxed_root_node(model::TSPTWM_Model,node::TSPTWM_Relaxed_Node)
    restrictednode = create_restricted_root_node(model,TSPTWM_Restricted_Node())
    return TSPTWM_Relaxed_Node(
        length(restrictednode),#layer::Int
        getstate(restrictednode),#state::Int 
        0.0,#lengthtoroot::T
        0.0,#lengthtoterminal::T
        falses(length(model)),#allup::BitVector
        copy(getvisited(restrictednode)),#alldown::BitVector
        falses(length(model)),#someup::BitVector
        copy(getvisited(restrictednode)),#somedown::BitVector
        true,#exact::Bool
        Vector{TSPTWM_Relaxed_Node}(),#parents::Vector{TSPTWM_NODE}
        Vector{TSPTWM_Relaxed_Node}(),#children::Vector{TSPTWM_NODE}
        0.0#latest_start_time::Int
    ), getdomain(restrictednode)
end

"""
    filter_out_arc_check(parent::TSPTW_Relaxed_Node, child::TSPTW_Relaxed_Node, model::TSPTW_Model, bestknownvalue::Union{Nothing, T}, values::Dict{Int, Vector{Tuple{Int, U}}},lastarc::Vector{Tuple{Int, V}})where{T<:Real,U<:Real,V<:Real}
Check if an arc is removable, return true if it is

# Arguments
- `parent::TSPTW_Relaxed_Node`: the parent node
- `child::TSPTW_Relaxed_Node`: the child node
- `model::TSPTW_Model`: the sequencing problem being evaluated
- `bestknownvalue::Union{Nothing, T}`: the best known solution value
- `values::Dict{Int, Vector{Tuple{Int, U}}}`: pre-calculated heuristic information
- `lastarc::Vector{Tuple{Int, V}}`: pre-calculated heuristic information
"""
function filter_out_arc_check(parent::TSPTW_Relaxed_Node, child::TSPTW_Relaxed_Node, model::TSPTW_Model, bestknownvalue::Union{Nothing, T}, values::Dict{Int, Vector{Tuple{Int, U}}},lastarc::Vector{Tuple{Int, V}})where{T<:Real,U<:Real,V<:Real}
    #default checks that can be done on any sequencing problem 
    @inline if filter_out_arc_alldiff_check(parent, child, model, bestknownvalue)
        return true
    end

    #handle timewindow constraints
    @inline if filter_out_arc_timewindow_check(parent,child,model)
        return true
    end

    #handle heuristic bounding 
    if length(model)-getlayer(child)>2
        if !isnothing(bestknownvalue) && getlayer(child)!=length(model)
            if is_better_solution_value(model, bestknownvalue, tsptw_rrb(model, parent, child, values,lastarc))
                return true
            end
        end
    end

    #cannot remove
    return false
end

"""
    filter_out_arc_check(parent::TSPTWM_Relaxed_Node, child::TSPTWM_Relaxed_Node, model::TSPTWM_Model, bestknownvalue::Union{Nothing, T}, values::Dict{Int, Vector{Tuple{Int, U}}},lastarc::Vector{Tuple{Int, V}},sorted_by_release::Vector{Int},associated_release_values::Vector{W})where{T<:Real,U<:Real,V<:Real,W<:Real}
Check if an arc is removable, return true if it is

# Arguments
- `parent::TSPTWM_Relaxed_Node`: the parent node
- `child::TSPTWM_Relaxed_Node`: the child node
- `model::P`: the sequencing problem being evaluated
- `bestknownvalue::Union{Nothing, T}`: the best known solution value
- `values::Dict{Int, Vector{Tuple{Int, U}}}`: pre-calculated heuristic information
- `lastarc::Vector{Tuple{Int, V}}`: pre-calculated heuristic information
- `sorted_by_release::Vector{Int}`: the release_times keys sorted in reverse order by release time + final transition
- `associated_release_values::Vector{W}`: the release times from the model
"""
function filter_out_arc_check(parent::TSPTWM_Relaxed_Node, child::TSPTWM_Relaxed_Node, model::TSPTWM_Model, bestknownvalue::Union{Nothing, T}, values::Dict{Int, Vector{Tuple{Int, U}}},lastarc::Vector{Tuple{Int, V}},sorted_by_release::Vector{Int},associated_release_values::Vector{W})where{T<:Real,U<:Real,V<:Real,W<:Real}
    #default checks that can be done on any sequencing problem 
    @inline if filter_out_arc_alldiff_check(parent, child, model, bestknownvalue)
        return true
    end

    #handle timewindow constraints
    @inline if filter_out_arc_timewindow_check(parent,child,model)
        return true
    end

    #handle heuristic bounding 
    if length(model)-getlayer(child)>2
        if !isnothing(bestknownvalue) && getlayer(child)!=length(model)
            if is_better_solution_value(model, bestknownvalue, tsptwm_rrb(model, parent, child, values,lastarc, sorted_by_release, associated_release_values))
                return true
            end
        end
    end

    #cannot remove
    return false
end

"""
    filter_out_arc_timewindow_check(parent::TSPTW_Relaxed_Node,child::TSPTW_Relaxed_Node,model::U)where{U<:SequencingModel}
Check if an arc is removable using timewindows

# Arguments
- `parent::TSPTW_Relaxed_Node`: the parent node
- `child::TSPTW_Relaxed_Node`: the child node
- `model::U`: the sequencing problem being evaluated
"""
function filter_out_arc_timewindow_check(parent::TSPTW_Relaxed_Node,child::TSPTW_Relaxed_Node,model::U)where{U<:SequencingModel}
    if max(
        getreleasetimes(model)[getstate(child)],
        get_ect(parent) + evaluate_decision(model,getstate(parent), getstate(child))
    ) > (get_lst(child))
        return true
    end
    
    return false
end
