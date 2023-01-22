"""

    refine_relaxed_dd(
        model::T,
        maxwidth::Int,
        relaxed_node_data_type::Union{DataType,UnionAll},
        restricted_node_data_type::Union{DataType,UnionAll},
        dd::Vector{Vector{U}},
        bestknownsolution::Union{Vector{Int},Nothing},
        bestknownvalue::Union{V,Nothing},
        path_to_root::Vector{Int},
        heuristic_trimming_packet,
        heuristic_ordering_packet,
        time_limit::Union{Nothing, W},
        time_elapsed::X,
        start_time::Y,
        debug_on::Bool
    )where{T<:ProblemModel,U<:RelaxedFrameworkNode,V<:Real, W<:Real, X<:Real}

Refine a relaxed decision diagram to exactness or maxwidth, whichever comes first
Returns dd::Vector{Vector{RelaxedSequencingNode}}, bound::Real, relaxedsolution::Vector{Int}, bestknownsolution::Vector{Int}, bestknownvalue::Real, exact::Bool
'exact' is true if the diagram exactly represents the problem (or subproblem) it was given, or if the relaxed solution is feasible

# Arguments
- `model::T`: The problem problem
- `max_width::Int`: The max width allowed in a decision diagram layer
- `relaxed_node_data_type::Union{DataType,UnionAll}`: The data type to use when creating new relaxed nodes
- `restricted_node_data_type::Union{DataType,UnionAll}`: The data type to use when creating new restricted nodes
- `dd::Vector{Vector{U}}`: The dd to refine
- `bestknownsolution::Union{Array{Int},Nothing}`: gives the DD a starting solution
- `bestknownvalue::Union{U,Nothing}`: value of the best known feasible solution
- `path_to_root::Vector{Int}`: the path to the root node if there is one
- `peel_setting::PeelSetting`:Which heuristic to use to decide where to start the peel from, defaults to 'frontier'
- `heuristic_trimming_packet`: provides data to be passed to a heuristic domain trimming function
- `heuristic_ordering_packet`: provides data to be passed to a heuristic split ordering function
- `time_limit::Union{Nothing, W}`: adds a time limit if not nothing
- `time_elapsed::X`: how much time passed already
- `start_time::X`: the time the program started to run
- `debug_on::Bool`: parameter that can be used to turn on debug statements in other functions
"""
function refine_relaxed_dd(
    model::T,
    maxwidth::Int,
    relaxed_node_data_type::Union{DataType,UnionAll},
    restricted_node_data_type::Union{DataType,UnionAll},
    dd::Vector{Vector{U}},
    bestknownsolution::Union{Vector{Int},Nothing},
    bestknownvalue::Union{V,Nothing},
    path_to_root::Vector{Int},
    heuristic_trimming_packet,
    heuristic_ordering_packet,
    time_limit::Union{Nothing, W},
    time_elapsed::X,
    start_time::X,
    debug_on::Bool
)where{T<:ProblemModel,U<:RelaxedFrameworkNode,V<:Real, W<:Real, X<:Real}
    timedout() = is_timed_out(time_limit,start_time, time_elapsed)

    #pre-allocate memory
    queue = Vector{relaxed_node_data_type}()
    sizehint!(queue, maxwidth)
    iterationcounter = 1
    newnode = relaxed_node_data_type()
    preallocatedfilterlist = Vector{relaxed_node_data_type}()
    sizehint!(preallocatedfilterlist, maxwidth)

    #for each layer
    for i in 1:length(dd)-1
        iterationcounter = 0
        empty!(queue)
        iterationcounter = updatequeue!(queue, dd[i],iterationcounter,model,  heuristic_ordering_packet)
        while !isempty(queue)
            #only run this loop if the dd isnt too wide (or it is layer 2 which must be made exact)
            if lastindex(dd[i])<maxwidth || i==2
                #for each node to refine
                for node in queue
                    #split node into two new nodes
                    newnode = splitnode!(node, maxwidth, model, iterationcounter, heuristic_ordering_packet, preallocatedfilterlist)
        
                    update_down_variables!(node,model)
                    update_down_variables!(newnode,model)

                    #trim useless arcs
                    filteroutarcs!(node,model,bestknownvalue,heuristic_trimming_packet, preallocatedfilterlist)
                    filteroutarcs!(newnode,model,bestknownvalue,heuristic_trimming_packet, preallocatedfilterlist)

                    #if newNode has remaining out arcs, add it to the dd
                    if !isempty(getchildren(newnode))
                        push!(dd[i], newnode)
                    else #delete in arcs so parent nodes may be removed in subsequent passes
                        delete_arcs_to_parents!(newnode)
                    end
                    #if old node has no out arcs, remove it from the dd
                    if isempty(getchildren(node))
                        delete_arcs_to_parents!(node)
                        filter!(x->x!=node, dd[i])
                    end
                    #continue until max width of layer is reached except on the first layer
                    if length(dd[i])>=maxwidth && i!= 2
                        break
                    end
                    #timeout check
                    if timedout()
                        return Vector{Vector{relaxed_node_data_type}}(), 0, bestknownsolution,bestknownsolution,bestknownvalue, false
                    end
                end#queue loop
            else
                break
            end#if statement
            #continue until max width of layer is reached except on the first layer
            if length(dd[i])>=maxwidth && i!= 2
                break
            end
            #timeout checks
            if timedout()
                return Vector{Vector{relaxed_node_data_type}}(), 0, bestknownsolution,bestknownsolution,bestknownvalue, false
            end
            empty!(queue)
            iterationcounter = updatequeue!(queue, dd[i],iterationcounter,model,  heuristic_ordering_packet)
        end #queue check

        #timeout checks
        if timedout()
            return Vector{Vector{relaxed_node_data_type}}(), 0, bestknownsolution,bestknownsolution,bestknownvalue, false
        end

        #remove nodes without parents
        if i<length(dd)
            @inbounds for node in dd[i+1]
                if isempty(getparents(node))
                    delete_arcs_to_children!(node)
                end
            end
            filter!(x->length(getparents(x))!=0, dd[i+1])
        end

        #prep the next layer
        @inbounds for node in dd[i+1]
            update_down_variables!(node,model)
            filteroutarcs!(node,model,bestknownvalue,heuristic_trimming_packet, preallocatedfilterlist)
            if isempty(getchildren(node)) && i+1 != length(dd)
                delete_arcs_to_parents!(node)
            end
        end

        filter!(x->length(getparents(x))!=0, dd[i+1])

        #timeout check
        if timedout()
            return Vector{Vector{relaxed_node_data_type}}(), 0, bestknownsolution,bestknownsolution,bestknownvalue, false
        end

    end#end layer iteration
    #check if empty
    if isempty(last(dd))
        return Vector{Vector{relaxed_node_data_type}}(), bestknownvalue, bestknownsolution,bestknownsolution,bestknownvalue, true
    end
    #timeout check
    if timedout()
        return Vector{Vector{relaxed_node_data_type}}(), 0, bestknownsolution,bestknownsolution,bestknownvalue, false
    end

    #iteratively delete nodes going up
    bottom_up_update!(model,dd)

    relaxedsolution = vcat(path_to_root,find_optimal_path(model, dd))

    #check if solution is feasible
    if check_solution_validity(model, relaxedsolution) && is_better_solution_value(model, retrieve_relaxed_bound(model, dd),bestknownvalue)
        bestknownsolution = relaxedsolution
        bestknownvalue = retrieve_relaxed_bound(model, dd)
        setexactness(first(last(dd)),true)
    end
    
    return dd, retrieve_relaxed_bound(model, dd),relaxedsolution,bestknownsolution, bestknownvalue, getexactness(first(last(dd)))
end

"""
    bottom_up_update!(model::T, dd::Vector{Vector{U}})where{T<:ProblemModel,U<:RelaxedFrameworkNode}
Update the upwards variables and delete useless arcs

# Arguments
- `model::T`: the sequencing problem being evaluated
- `dd::Vector{Vector{U}}`: the dd to update
"""
function bottom_up_update!(model::T, dd::Vector{Vector{U}})where{T<:ProblemModel,U<:RelaxedFrameworkNode}
    #remove garbage nodes
    for i in Iterators.reverse(2:length(dd)-1)
        for node in dd[i]
            if isempty(getchildren(node))
                delete_arcs_to_parents!(node)
            end
        end
        filter!(x->length(getparents(x))!=0, dd[i])
    end
    filter!(x->length(getchildren(x))!=0, dd[1])
    filter!(x->length(getparents(x))!=0, dd[length(dd)])

    #update values for remaining nodes
    for i in Iterators.reverse(1:length(dd)-1)
        for node in dd[i]
            update_up_variables!(node, model)
        end
    end
end

"""
    getlastexactlayer(dd::Vector{Vector{T}}) where{T<:RelaxedFrameworkNode}

Get the last exact layer of a dd
Returns ::Vector{T}

# Arguments
- `dd::Vector{Vector{T}}`: The dd to search
"""
function getlastexactlayer(dd::Vector{Vector{T}}) where{T<:RelaxedFrameworkNode}
    currentlayer = dd[1]
    for layer in dd
        for node in layer
            if !node.exact
                return currentlayer
            end
        end
        currentlayer = layer
    end
end

#=
    For Debugging
=#
function containsoptimal(model::P,dd::Vector{Vector{U}}, path_to::Vector{Int}, optimal_solution::Vector{Int})where{P<:SequencingModel,U<:RelaxedFrameworkNode}
    solution_value = 0

    for (i,e) in enumerate(path_to)
        if optimal_solution[i] != e
            #println("Does Not Contain Optimal Solution")
            return false
        elseif i>1
            solution_value += evaluate_decision(model, optimal_solution[i-1],optimal_solution[i])
        end
    end

    cn = first(first(dd))
    if getstate(cn)!=optimal_solution[lastindex(path_to)+1]
        #println("Does Not Contain Optimal Solution")
        return false
    end
    if !isempty(path_to)
        solution_value += evaluate_decision(model, optimal_solution[lastindex(path_to)],optimal_solution[lastindex(path_to)+1])
    end

    contains_optimal = false
    for i in lastindex(path_to)+2:lastindex(optimal_solution)
        for child in getchildren(cn)
            if getstate(child)==optimal_solution[i]
                contains_optimal = true
                cn = child
                solution_value += evaluate_decision(model, optimal_solution[i-1],optimal_solution[i])
                break
            end
        end
        if contains_optimal
            contains_optimal = false
        else
            #println("Does Not Contain Optimal Solution")
            return false
        end
    end
    #println(cn)
    #println(solution_value, " ", getlengthtoroot(cn))
    #println("Contains Optimal Solution")
    return true
end