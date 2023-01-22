"""
    acquire_heuristic_packet(model::SOP_Model)

A method that preloads and returns information useful for trimming nodes

# Arguments
- `model::SOP_Model`: The problem model
"""
function acquire_heuristic_packet(model::SOP_Model)
    getobjective(model)
    paramtype = valtype(getobjective(model).f.components)
    values = Dict{Int, Vector{Tuple{Int, paramtype}}}()
    lastarc = Vector{Tuple{Int,paramtype}}()
    for (states,objvalue) in getobjective(model).f.components
        startstate = states[1]
        endstate = states[2]
        if endstate == getend(model)
            insert!(
                lastarc,
                searchsorted(lastarc, (startstate, objvalue), by = x -> x[2]).start,
                (startstate, objvalue)
            )
        else
            if Base.haskey(values,startstate)
                insert!(
                    values[startstate],
                    searchsorted(values[startstate], (endstate, objvalue), by = x -> x[2]).start,
                    (endstate, objvalue)
                )
            else
                values[startstate] = [(endstate, objvalue)]
            end
        end
        
    end
    return (values, lastarc)
end

"""
    sop_rrb(visited::BitVector, state::Int, startingvalue::T, values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}})where{T<:Real}

A method that takes in the current state of the sop and the precalculated values and returns a rough relaxed bound

# Arguments
- `visited::BitVector`: The visited nodes
- `state::Int`: The current node label
- `startingvalue::T`: the value of the starting node
- `values::Dict{Int, Vector{Tuple{Int, T}}}`: The presorted out arc values
- `lastarc::Vector{Tuple{Int, T}}`: The presorted in arc values for the last edge
"""
function sop_rrb(visited::BitVector, state::Int, startingvalue::T, values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}})where{T<:Real}
    rrb = startingvalue
    #add the first arc
    @inbounds for pair in values[state]
        if !visited[pair[1]] && pair[1]!=length(visited)
            rrb += pair[2]
            break
        end
    end
    #add the last arc
    @inbounds for pair in lastarc
        if !visited[pair[1]]
            rrb += pair[2]
            break
        end
    end

    worstvalue = 0
    @inbounds for i in 1:length(visited)-1
        if !visited[i]
            for pair in values[i]
                if !visited[pair[1]] && pair[1]!=length(visited)
                    rrb += pair[2]
                    if pair[2] > worstvalue
                        worstvalue = pair[2]
                    end
                    break
                end
            end
        end
    end
    rrb -= worstvalue
    return rrb
end

"""
    sop_rrb(model::SOP_Model, parent::SOP_Relaxed_Node,child::SOP_Relaxed_Node,values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}})where{T<:Real}
Takes in an arc from a relaxed DD of the sop, and the precalculated values, then returns a rough relaxed bound

# Arguments
- `model::SOP_Model`: the problem model
- `parent::SOP_Relaxed_Node`: the parent node
- `child::SOP_Relaxed_Node`: the child node
- `values::Dict{Int, Vector{Tuple{Int, T}}}`: pre-calculated heuristic information
- `lastarc::Vector{Tuple{Int, T}}`: pre-calculated heuristic information
"""
function sop_rrb(model::SOP_Model, parent::SOP_Relaxed_Node,child::SOP_Relaxed_Node,values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}})where{T<:Real}
    rrb = evaluate_decision(model,getstate(parent), getstate(child))
    visited = copy(getalldown(parent))
    visited[getstate(child)] = true
    #add the first arc
    @inbounds for pair in values[getstate(child)]
        if !visited[pair[1]] && pair[1]!=length(visited)
            rrb += pair[2]
            break
        end
    end
    #add the last arc
    @inbounds for pair in lastarc
        if !visited[pair[1]]
            rrb += pair[2]
            break
        end
    end

    worstvalues = Vector{Int}()
    sizehint!(worstvalues, length(model))
    @inbounds for i in 1:lastindex(visited)-1
        if !visited[i]
            valuefound = false
            for pair in values[i]
                if !visited[pair[1]] && pair[1]!=length(visited)
                    if isempty(worstvalues)
                        push!(worstvalues, pair[2])
                    else
                        insert!(
                            worstvalues,
                            searchsorted(worstvalues, pair[2]).start,
                            pair[2]
                        )
                    end
                    valuefound = true
                    break
                end
            end
            if !valuefound
                if isempty(worstvalues)
                    push!(worstvalues, 0)
                else
                    insert!(
                        worstvalues,
                        searchsorted(worstvalues, typemax(Int)).start,
                        typemax(Int)
                    )
                end
            end
        end
    end
    worstvalues = worstvalues[1:(length(visited)-getlayer(child)-2)]
    rrb += sum(worstvalues)
    return rrb
end

"""
    order_sop_precedence_to_edge(model::SOP_Model)

Find a variable ordering for the model based on the edge weights and precedence graph
Return the variable ordering ::Vector{Int}

# Arguments
- `model::SOP_Model`: the sequencing problem to be evaluated
"""
function order_sop_precedence_to_edge(model::SOP_Model)
    obj_type = valtype(model.objective.f.components)
    sorted_keys = order_by_edge_weight(model)
    #put jobs into the order by precedence and then average edge weight
    final_order = Vector{obj_type}()
    follower_numbers = getprecedencenumbers(model)
    max_length = maximum(values(follower_numbers))
    while max_length>0
        @inbounds for i in 1:length(sorted_keys)
            if sorted_keys[i] in keys(follower_numbers) && follower_numbers[sorted_keys[i]]==max_length
                push!(final_order, sorted_keys[i])
            end
        end
        max_length = max_length - 1
    end
    @inbounds for i in 1:length(sorted_keys)
        if !(sorted_keys[i] in final_order)
            push!(final_order, sorted_keys[i])
        end
    end
    return final_order
end