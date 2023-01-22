"""
    finish_peel_and_bound(bestknownsolution::Union{Vector{Int},Nothing}, bestknownvalue::T;start_time::Union{U,Nothing}=nothing, time_elapsed::V=0,filename::Union{Nothing,String}=nothing)where{T<:Real, U<:Real, V<:Real}

Print the optimal solution

# Arguments
- `bestknownsolution::Union{Vector{Int},Nothing}`: The solution as an ordered list of nodes
- `bestknownvalue::T`: The cost of the solution
- `start_time::U`: the time the program started (in seconds since the epoch)
- `time_elapsed::V`: additional time used (in seconds)
- `filename::Union{Nothing,String}`: An optional file to write the log statement to
"""
function finish_peel_and_bound(bestknownsolution::Union{Vector{Int},Nothing}, bestknownvalue::T;start_time::Union{U,Nothing}=nothing, time_elapsed::V=0,filename::Union{Nothing,String}=nothing)where{T<:Real, U<:Real, V<:Real}
    if !isnothing(bestknownsolution)
        log_solution(bestknownsolution, bestknownvalue,firstline="Optimal Solution Found:", filename=filename)
    end
    if !isnothing(start_time)
        logruntime(start_time, time_elapsed, filename=filename)
        logoptimalitygap(bestknownvalue, bestknownvalue, filename=filename)
    end
    println()
end

"""
    add_dd_to_queue!(queue::Vector{Tuple{Vector{Vector{T}}, U, Vector{Int}, Bool}}, block::Tuple{Vector{Vector{T}}, V, Vector{Int}, Bool}, model::W) where{T<:RelaxedFrameworkNode, U<:Real,V<:Real, W<:ProblemModel}

Adds a tuple containing a relaxed dd and related useful information to a sorted processing queue (at the correct index)

# Arguments
- `queue::Vector{Tuple{Vector{Vector{T}}, U, Vector{Int}, Bool}}`: The queue
- `block::Tuple{Vector{Vector{T}}, V, Vector{Int}, Bool}`: The block to add to the queue
- `model::W`: The sequencing problem

"""
function add_dd_to_queue!(queue::Vector{Tuple{Vector{Vector{T}}, U, Vector{Int}, Bool}}, block::Tuple{Vector{Vector{T}}, V, Vector{Int}, Bool}, model::W) where{T<:RelaxedFrameworkNode, U<:Real,V<:Real, W<:ProblemModel}
    #put worst bound at back of queue
    if isempty(queue)
        push!(queue, block)
    else
        insert!(
            queue,
            searchsorted(queue, block, by = x -> x[2],rev= (getobjectivetype(model)!=minimization)).start,
            block
        )
    end
end

"""
peel_and_remove!(
    model::T,
    dd::Vector{Vector{U}},
    frontier_node::U,
    frontier_node_index::Int,
    bestknownvalue::Union{V,Nothing},
    path_to_root::Vector{Int},
    preallocatedfilterlist::Vector{U},
    heuristic_trimming_packet,
    logging_on::Bool,
    debug_on::Bool
)where{T<:ProblemModel,U<:RelaxedFrameworkNode,V<:Real}

A version of the peel process that deletes the peeled dd as it is created
Returns (dd, bound, relaxed_solution, dd_exact), bestknownsolution, bestknownvalue
(dd, bound, relaxed_solution, dd_exact): is a Tuple{Vector{Vector{U}}, Real, Vector{Int}, Bool} storing all the updated info for 'dd'
bestknownsolution, bestknownvalue: are Vector{Int}, Real

# Arguments
- `model::T`: The sequencing problem
- `dd::Vector{Vector{U}}`: The starting diagram
- `frontier_node::U`: The node start from
- `frontier_node_index::Int`: The index of the layer of 'dd' that 'frontier_node' is on
- `bestknownvalue::Union{V,Nothing}`: The value of the best known feasible solution
- `path_to_root::Vector{Int}`: the path to the root node
- `preallocatedfilterlist::Vector{U}`: Preallocated list for performance, contents do not matters
- `heuristic_trimming_packet`: Optional data to be passed to the rrbFunction
- `logging_on::Bool`: An parameter that can be used to turn off logging to the console and local file
- `debug_on::Bool`: An parameter that can be used to turn on debug statements in other functions
"""
function peel_and_remove!(
    model::T,
    dd::Vector{Vector{U}},
    frontier_node::U,
    frontier_node_index::Int,
    bestknownvalue::Union{V,Nothing},
    path_to_root::Vector{Int},
    preallocatedfilterlist::Vector{U},
    heuristic_trimming_packet,
    logging_on::Bool,
    debug_on::Bool
)where{T<:ProblemModel,U<:RelaxedFrameworkNode,V<:Real}
    bestknownsolution = Vector{Int}()

    #remove the node from the dd
    delete_arcs_to_parents!(frontier_node)
    delete_arcs_to_children!(frontier_node)
    filter!(x->x!=frontier_node, dd[frontier_node_index])

    #iterate downwards
    @inbounds for i in (frontier_node_index+1):length(dd)
        for node in dd[i]
            if isempty(getparents(node))
                delete_arcs_to_children!(node)
            end
        end
        filter!(x->!isempty(getparents(x)), dd[i])
        for node in dd[i]
            update_down_variables!(node,model)
            filteroutarcs!(node,model,bestknownvalue,heuristic_trimming_packet, preallocatedfilterlist)
        end
    end

    #update upwards values
    if !isempty(last(dd))
        bottom_up_update!(model,dd)
        bound = getlengthtoroot(first(last(dd)))
        relaxed_solution = vcat(path_to_root,find_optimal_path(model, dd))

        #check if solution is feasible
        if check_solution_validity(model, relaxed_solution) && is_better_solution_value(model, retrieve_relaxed_bound(model, dd),bestknownvalue)
            bestknownsolution = relaxed_solution
            bestknownvalue = retrieve_relaxed_bound(model, dd)
            setexactness(first(last(dd)),true)
        end

        if !isnothing(bound) && is_better_solution_value(model, bound, bestknownvalue)
            dd_exact = false
        else
            dd = nothing
            bound = bestknownvalue
            relaxed_solution = nothing
            dd_exact = true
        end
    else
        dd = nothing
        bound = bestknownvalue
        relaxed_solution = nothing
        dd_exact = true
    end

    return (dd, bound, relaxed_solution, dd_exact), bestknownsolution, bestknownvalue
end


"""

    peel_dd!(
        model::T,
        max_width::Int,
        relaxed_node_data_type::Union{DataType,UnionAll},
        restricted_node_data_type::Union{DataType,UnionAll},
        dd::Vector{Vector{U}},
        relaxed_solution::Vector{Int},
        frontier_node::U,
        frontier_node_index::Int,
        bestknownvalue::Union{V,Nothing},
        path_to_root::Vector{Int},
        path_to_frontier::Vector{Int},
        preallocatedfilterlist::Vector{U},
        heuristic_trimming_packet,
        heuristic_ordering_packet,
        time_limit::Union{Nothing, W},
        time_elapsed::X,
        start_time::X,
        logging_on::Bool,
        debug_on::Bool,
        do_bounding::Bool
    )where{T<:ProblemModel,U<:RelaxedFrameworkNode,V<:Real}

Peel a diagram given the node to start from, and the diagram
Returns (dd, bound, relaxed_solution, dd_exact), (new_dd, peeled_bound, peeled_relaxed_solution, peeled_exact), bestknownsolution, bestknownvalue
(dd, bound, relaxed_solution, dd_exact): is a Tuple{Vector{Vector{U}}, Real, Vector{Int}, Bool} storing all the updated info for 'dd'
(new_dd, peeled_bound, peeled_relaxed_solution, peeled_exact): is also a Tuple{Vector{Vector{U}}, Real, Vector{Int}, Bool} storing all the info for the peeled dd
bestknownsolution, bestknownvalue: are Vector{Int}, Real

# Arguments
- `model::T`: The sequencing problem
- `max_width::Int`: The max width allowed in a decision diagram layer
- `relaxed_node_data_type::Union{DataType,UnionAll}`:
- `restricted_node_data_type::Union{DataType,UnionAll}`:
- `dd::Vector{Vector{U}}`: The starting diagram
- `relaxed_solution::::Vector{Int}`: The best path through 'dd'
- `frontier_node::U`: The node start from
- `frontier_node_index::Int`: The index of the layer of 'dd' that 'frontier_node' is on
- `bestknownvalue::Union{V,Nothing}`: The value of the best known feasible solution
- `path_to_root::Vector{Int}`: the path to the root node
- `path_to_frontier::Vector{Int}`: the path to the frontier node
- `preallocatedfilterlist::Vector{U}`: pre-allocated for performance
- `heuristic_trimming_packet`: optional heuristic data
- `heuristic_ordering_packet`: optional heuristic data
- `time_limit::Union{Nothing, W}`:
- `time_elapsed::X`:
- `start_time::X`:
- `logging_on::Bool`: An optional parameter that can be used to turn off logging to the console and local file
- `debug_on::Bool`: An optional parameter that can be used to turn on debug statements in other functions
- `do_bounding::Bool`: a boolean that if false will skip the refinement step of the peel and bound process
"""
function peel_dd!(
    model::T,
    max_width::Int,
    relaxed_node_data_type::Union{DataType,UnionAll},
    restricted_node_data_type::Union{DataType,UnionAll},
    dd::Vector{Vector{U}},
    relaxed_solution::Vector{Int},
    frontier_node::U,
    frontier_node_index::Int,
    bestknownvalue::Union{V,Nothing},
    path_to_root::Vector{Int},
    path_to_frontier::Vector{Int},
    preallocatedfilterlist::Vector{U},
    heuristic_trimming_packet,
    heuristic_ordering_packet,
    time_limit::Union{Nothing, W},
    time_elapsed::X,
    start_time::X,
    logging_on::Bool,
    debug_on::Bool,
    do_bounding::Bool
)where{T<:ProblemModel,U<:RelaxedFrameworkNode,V<:Real,W<:Real,X<:Real}
    bestknownsolution = Vector{Int}()

    relaxed_dd(relaxed_dd,pathtoroot,debug_on) = refine_relaxed_dd(model, max_width, relaxed_node_data_type, restricted_node_data_type,relaxed_dd, bestknownsolution, bestknownvalue, pathtoroot,heuristic_trimming_packet, heuristic_ordering_packet,time_limit, time_elapsed,start_time, debug_on)
    filter!(x->x!=frontier_node, dd[frontier_node_index])
    delete_arcs_to_parents!(frontier_node)

    new_dd = Vector{Vector{relaxed_node_data_type}}()
    sizehint!(new_dd,length(model)+1-frontier_node_index)
    push!(new_dd, [frontier_node])

    arc_map = Dict{relaxed_node_data_type, Vector{relaxed_node_data_type}}()
    
    for i in 1:length(relaxed_solution)-getlayer(frontier_node)
        empty!(arc_map)
        #create a map of child nodes to the arcs that should go with them
        for node in new_dd[i]
            @inbounds for child in getchildren(node)
                if Base.haskey(arc_map, child)
                    push!(arc_map[child], node)
                else
                    arc_map[child] = [node]
                    sizehint!(arc_map[child],max_width)
                end
            end
        end

        #iterate over each child node of the current layer and peel it
        push!(new_dd, Vector{relaxed_node_data_type}())
        sizehint!(last(new_dd), max_width)
        
        for key in keys(arc_map)
            new_node = peel_node!(model, key, max_width, arc_map[key],bestknownvalue,heuristic_trimming_packet,preallocatedfilterlist)
            #check the peeled node to make sure it is worth adding
            @inbounds if !isempty(getchildren(new_node)) || length(model)==getlayer(new_node)
                push!(new_dd[i+1], new_node)
            else #delete in arcs so parent nodes may be removed in subsequent passes
                delete_arcs_to_parents!(new_node)
            end
            #check the old node to make sure it doesnt need to be removed
            @inbounds if isempty(getchildren(key)) && (i+frontier_node_index)<length(dd)
                #delete in arcs so parent nodes may be removed in subsequent passes
                delete_arcs_to_parents!(key)
                filter!(x->x!=key, dd[i+frontier_node_index])
            elseif isempty(getparents(key))
                #delete out arcs so child nodes may be removed in subsequent passes
                delete_arcs_to_children!(key)
                filter!(x->x!=key, dd[i+frontier_node_index])
            end
        end

        for node in dd[i+frontier_node_index]
            if isempty(getparents(node))
                delete_arcs_to_children!(node)
            end
        end

        filter!(x->!isempty(getparents(x)), dd[i+frontier_node_index])
        
        for node in dd[i+frontier_node_index]
            update_down_variables!(node,model)
        end
    end#iterate through the layers

    #check and update the two DDs
    if !isempty(last(dd))
        bottom_up_update!(model,dd)
        bound = getlengthtoroot(first(last(dd)))
        relaxed_solution = vcat(path_to_root,find_optimal_path(model, dd))

        #check if solution is feasible
        if check_solution_validity(model, relaxed_solution) && is_better_solution_value(model, retrieve_relaxed_bound(model, dd),bestknownvalue)
            bestknownsolution = relaxed_solution
            bestknownvalue = retrieve_relaxed_bound(model, dd)
            setexactness(first(last(dd)),true)
        end

        if !isnothing(bound) && is_better_solution_value(model, bound, bestknownvalue)
            if do_bounding
                dd, bound, relaxed_solution, bestknownsolution, bestknownvalue, dd_exact = relaxed_dd(dd,path_to_root,debug_on)
                if dd_exact
                    empty!(dd)
                end
            else
                dd_exact = false
            end
        else
            dd = nothing
            bound = bestknownvalue
            relaxed_solution = nothing
            dd_exact = true
        end
    else
        dd = nothing
        bound = bestknownvalue
        relaxed_solution = nothing
        dd_exact = true
    end

    if !isempty(last(new_dd))
        bottom_up_update!(model,new_dd)
        peeled_bound = getlengthtoroot(first(last(new_dd)))
        peeled_relaxed_solution = vcat(path_to_root,find_optimal_path(model, new_dd))

        #check if solution is feasible
        if check_solution_validity(model, peeled_relaxed_solution) && is_better_solution_value(model, retrieve_relaxed_bound(model, new_dd),bestknownvalue)
            bestknownsolution = peeled_relaxed_solution
            bestknownvalue = retrieve_relaxed_bound(model, new_dd)
            setexactness(first(last(new_dd)),true)
        end

        if !isnothing(peeled_bound) && is_better_solution_value(model, peeled_bound, bestknownvalue)
            if do_bounding
                new_dd, peeled_bound, peeled_relaxed_solution, bestknownsolution, bestknownvalue, peeled_exact = relaxed_dd(new_dd,path_to_frontier,debug_on)
                if peeled_exact
                    empty!(new_dd)
                end
            else
                peeled_exact = false
            end
        else
            new_dd = nothing
            peeled_bound = bestknownvalue
            peeled_relaxed_solution = nothing
            peeled_exact = true
        end
    else
        new_dd = nothing
        peeled_bound = bestknownvalue
        peeled_relaxed_solution = nothing
        peeled_exact = true
    end

    return (dd, bound, relaxed_solution, dd_exact), (new_dd, peeled_bound, peeled_relaxed_solution, peeled_exact), bestknownsolution, bestknownvalue
end