"""
    order_tsptw_deadlines(model::T) where{T<:TSPTWMODEL}

Find a variable ordering for the model based on the deadlines
Return the variable ordering ::Vector{Int}

# Arguments
- `model::T`: the problem model
"""
function order_tsptw_deadlines(model::T) where{T<:TSPTWMODEL}
    #get sorted deadlines
    sorted_by_deadline = sort(collect(keys(model.deadlines)), by = x -> model.deadlines[x])

    deleteat!(sorted_by_deadline,findfirst(getstart(model), sorted_by_deadline))
    deleteat!(sorted_by_deadline,findfirst(getend(model), sorted_by_deadline))

    return sorted_by_deadline
end

"""
    order_tsptw_edge(model::T) where{T<:TSPTWMODEL}

Find a variable ordering for the model based on the edge weights
Return the variable ordering ::Vector{Int}

# Arguments
- `model::T`: the problem model
"""
function order_tsptw_edge(model::T) where{T<:TSPTWMODEL}
    sorted_by_weight = Int.(order_by_edge_weight(model))
    deleteat!(sorted_by_weight,findfirst(x -> x==getstart(model), sorted_by_weight))
    deleteat!(sorted_by_weight,findfirst(x -> x==getend(model), sorted_by_weight))
    return sorted_by_weight
end

"""
    acquire_heuristic_packet(model::TSPTW_Model)

A method that preloads and returns information useful for trimming nodes

# Arguments
- `model::TSPTW_Model`: The problem model
"""
function acquire_heuristic_packet(model::TSPTW_Model)
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
    acquire_heuristic_packet(model::TSPTWM_Model)

A method that preloads and returns information useful for trimming nodes

# Arguments
- `model::TSPTWM_Model`: The problem model
"""
function acquire_heuristic_packet(model::TSPTWM_Model)
    hp = acquire_heuristic_packet(TSPTW_Model(model))
    sorted_by_release = collect(keys(model.release_times))
    deleteat!(sorted_by_release,findfirst(x -> x==getstart(model), sorted_by_release))
    deleteat!(sorted_by_release,findfirst(x -> x==getend(model), sorted_by_release))
    sort!(sorted_by_release, by = x -> model.release_times[x], rev=true)
    associated_release_values = Vector{typeof(first(values(getobjective(model).f.components)))}()
    
    for e in sorted_by_release
        push!(associated_release_values, model.release_times[e])
    end
    return (hp[1], hp[2],sorted_by_release,associated_release_values)
end

"""
    tsptw_rrb(visited::BitVector, state::Int, startingvalue::T, values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}})where{T<:Real}

A method that takes in the current state of the tsptw and the precalculated values and returns a rough relaxed bound

# Arguments
- `visited::BitVector`: The visited nodes
- `state::Int`: The current node label
- `startingvalue::T`: the value of the starting node
- `values::Dict{Int, Vector{Tuple{Int, T}}}`: The presorted out arc values
- `lastarc::Vector{Tuple{Int, T}}`: The presorted in arc values for the last edge
"""
function tsptw_rrb(visited::BitVector, state::Int, startingvalue::T, values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}})where{T<:Real}
    rrb = startingvalue
    #add the first arc
    @inbounds for pair in values[state]
        if !visited[pair[1]]
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

    @inbounds for i in 1:lastindex(visited)-1
        if !visited[i]
            for pair in values[i]
                if !visited[pair[1]]
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
    tsptwm_rrb(visited::BitVector, state::Int, startingvalue::T, values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}}, sorted_by_release::Vector{Int},associated_release_values::Vector{T}) where{T<:Real}   

A method that takes in the current state of the tsptw and the precalculated values and returns a rough relaxed bound

# Arguments
- `visited::BitVector`: The visited nodes
- `state::Int`: The current node label
- `startingvalue::T`: the value of the starting node
- `values::Dict{Int, Vector{Tuple{Int, T}}}`: The presorted out arc values
- `lastarc::Vector{Tuple{Int, T}}`: The presorted in arc values for the last edge
- `sorted_by_release::Vector{Int}`: the release_times keys sorted in reverse order by release time + final transition
- `associated_release_values::Vector{T}`: the release times from the model
"""
function tsptwm_rrb(visited::BitVector, state::Int, startingvalue::T, values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}}, sorted_by_release::Vector{Int},associated_release_values::Vector{T}) where{T<:Real}
    rrb = tsptw_rrb(visited, state, startingvalue, values,lastarc)
    
    #getthe last arc
    last_arc = 0
    @inbounds for pair in lastarc
        if !visited[pair[1]]
            last_arc = pair[2]
            break
        end
    end

    first_arc = 0
    direct_arc = 0
    for i in 1:length(sorted_by_release)
        if !visited[sorted_by_release[i]]

            #add the first arc
            @inbounds for pair in values[i]
                if !visited[pair[1]]
                    first_arc = pair[2]
                    break
                end
            end

            #get the direct to end arc
            @inbounds for pair in lastarc
                if pair[1]==i
                    direct_arc = pair[2]
                    break
                end
            end
            
            rrb = max(
                min(
                    associated_release_values[i]+first_arc+last_arc,
                    associated_release_values[i]+direct_arc
                ),
                rrb
            )
            break
        end
    end


    return rrb
end


"""
    tsptw_rrb(model::TSPTW_Model, parent::TSPTW_Relaxed_Node,child::TSPTW_Relaxed_Node,values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}})where{T<:Real}
Takes in an arc from a relaxed DD of the tsptw, and the precalculated values, then returns a rough relaxed bound

# Arguments
- `model::TSPTW_Model`: the problem model
- `parent::TSPTW_Relaxed_Node`: the parent node
- `child::TSPTW_Relaxed_Node`: the child node
- `values::Dict{Int, Vector{Tuple{Int, T}}}`: pre-calculated heuristic information
- `lastarc::Vector{Tuple{Int, T}}`: pre-calculated heuristic information
"""
function tsptw_rrb(model::TSPTW_Model, parent::TSPTW_Relaxed_Node,child::TSPTW_Relaxed_Node,values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}})where{T<:Real}
    rrb = evaluate_decision(model,getstate(parent), getstate(child))
    visited = copy(getalldown(parent))
    visited[getstate(child)] = true
    #add the first arc
    @inbounds for pair in values[getstate(child)]
        if !visited[pair[1]]
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

    worstvalues = Vector{Float64}()
    sizehint!(worstvalues, length(model))

    @inbounds for i in 1:lastindex(visited)-1
        if !visited[i]
            for pair in values[i]
                if !visited[pair[1]]
                    if isempty(worstvalues)
                        push!(worstvalues, pair[2])
                    else
                        insert!(
                            worstvalues,
                            searchsorted(worstvalues, pair[2]).start,
                            pair[2]
                        )
                    end
                    break
                end
            end
        end
    end
    worstvalues = worstvalues[1:(length(visited)-getlayer(child)-2)]
    rrb += sum(worstvalues)
    return rrb
end


"""
    tsptwm_rrb(model::TSPTWM_Model, parent::TSPTWM_Relaxed_Node,child::TSPTWM_Relaxed_Node,values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}},sorted_by_release::Vector{Int},associated_release_values::Vector{T})where{T<:Real}
Takes in an arc from a relaxed DD of the tsptw, and the precalculated values, then returns a rough relaxed bound

# Arguments
- `model::TSPTWM_Model`: the problem model
- `parent::TSPTWM_Relaxed_Node`: the parent node
- `child::TSPTWM_Relaxed_Node`: the child node
- `values::Dict{Int, Vector{Tuple{Int, T}}}`: pre-calculated heuristic information
- `lastarc::Vector{Tuple{Int, T}}`: pre-calculated heuristic information
- `sorted_by_release::Vector{Int}`: the release_times keys sorted in reverse order by release time + final transition
- `associated_release_values::Vector{T}`: the release times from the model
"""
function tsptwm_rrb(model::TSPTWM_Model, parent::TSPTWM_Relaxed_Node,child::TSPTWM_Relaxed_Node,values::Dict{Int, Vector{Tuple{Int, T}}},lastarc::Vector{Tuple{Int, T}},sorted_by_release::Vector{Int},associated_release_values::Vector{T})where{T<:Real}
    rrb = evaluate_decision(model,getstate(parent), getstate(child))
    visited = copy(getalldown(parent))
    visited[getstate(child)] = true
    #add the first arc
    @inbounds for pair in values[getstate(child)]
        if !visited[pair[1]]
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

    worstvalues = Vector{Float64}()
    sizehint!(worstvalues, length(model))

    @inbounds for i in 1:lastindex(visited)-1
        if !visited[i]
            for pair in values[i]
                if !visited[pair[1]]
                    if isempty(worstvalues)
                        push!(worstvalues, pair[2])
                    else
                        insert!(
                            worstvalues,
                            searchsorted(worstvalues, pair[2]).start,
                            pair[2]
                        )
                    end
                    break
                end
            end
        end
    end
    worstvalues = worstvalues[1:(length(visited)-getlayer(child)-2)]
    rrb += sum(worstvalues)

    #do easy check for later release time
    visited = copy(getsomedown(parent))
    visited[getstate(child)] = true
    for i in 1:length(sorted_by_release)
        if !visited[sorted_by_release[i]]
            rrb = max(associated_release_values[i],rrb)
            break
        end
    end

    return rrb
end