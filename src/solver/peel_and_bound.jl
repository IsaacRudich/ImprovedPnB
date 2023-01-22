"""

    run_peel_and_bound(
        model::T,
        max_width::Int,
        restricted_node_data_type::Union{DataType,UnionAll},
        relaxed_node_data_type::Union{DataType,UnionAll};

        widthofsearch::Int,

        bestknownsolution::Union{Array{Int},Nothing}=nothing,
        bestknownvalue::Union{U,Nothing}=nothing,

        peel_setting::PeelSetting=frontier,
        heuristic_trimming_packet = nothing,
        heuristic_ordering_packet = nothing,
        seeded::Bool = false,

        time_limit::Union{Nothing, W}=nothing,
        time_elapsed::X=0.0,
        logging_on::Bool=true,
        file_name::Union{Nothing,String}=nothing,
        debug_on::Bool=false
    )where{T<:ProblemModel,U<:Real,W<:Real,X<:Real}

Solve a problem to optimality using a peel and bound scheme
Returns bestknownsolution::Vector{Int}, bestknownvalue::Real, bound::Real

# Arguments
- `model::T`: The problem problem
- `max_width::Int`: The max width allowed in a decision diagram layer
- `restricted_node_data_type::Union{DataType,UnionAll}`: The data type to use when creating new restriced nodes
- `relaxed_node_data_type::Union{DataType,UnionAll}`: The data type to use when creating new relaxed nodes
# Optional Arrguments
- `widthofsearch::Int`: The width of the variety search
- `bestknownsolution::Union{Array{Int},Nothing}`: An optional parameter that gives the DD a starting solution
- `bestknownvalue::Union{U,Nothing}`: An optional parameter, The value of the best known feasible solution
- `peel_setting::PeelSetting`:Which heuristic to use to decide where to start the peel from, defaults to 'frontier'
- `heuristic_trimming_packet`: An optional parameter that provides data to be passed to a heuristic domain trimming function
- `heuristic_ordering_packet`: An optional parameter that provides data to be passed to a heuristic split ordering function
- `seeded::Bool`: If true, then the initial search for a good strating solution is skipped
- `time_limit::Union{Nothing, W}`: An optional parameter that adds a time limit
- `time_elapsed::X`: An optional parameter denoting how much time passed already
- `logging_on::Bool`: An optional parameter that can be used to turn off logging to the console and local file
- `file_name::Union{Nothing,String}`: The file to write results to
- `debug_on::Bool`: An optional parameter that can be used to turn on debug statements in other functions
"""
function run_peel_and_bound(
    model::T,
    max_width::Int,
    restricted_node_data_type::Union{DataType,UnionAll},
    relaxed_node_data_type::Union{DataType,UnionAll};

    widthofsearch::Int=100,

    bestknownsolution::Union{Array{Int},Nothing}=nothing,
    bestknownvalue::Union{U,Nothing}=nothing,

    peel_setting::PeelSetting=frontier,
    heuristic_trimming_packet = nothing,
    heuristic_ordering_packet = nothing,
    seeded::Bool = false,

    time_limit::Union{Nothing, W}=nothing,
    time_elapsed::X=0.0,
    logging_on::Bool=true,
    file_name::Union{Nothing,String}=nothing,
    debug_on::Bool=false
)where{T<:ProblemModel,U<:Real,W<:Real,X<:Real}
    start_time = time()
    best_bound = nothing
    preallocatedfilterlist = Vector{relaxed_node_data_type}()
    sizehint!(preallocatedfilterlist, max_width)
    #initialize path map
    path_to_map = Dict{relaxed_node_data_type, Vector{Int}}()
    timedout() = is_timed_out(time_limit,start_time, time_elapsed)

    restricted_dd(rootnode,debug_on) = construct_restricted_dd(model, max_width, restricted_node_data_type,rootnode=rootnode,bestknownsolution=bestknownsolution,bestknownvalue=bestknownvalue, heuristic_packet=heuristic_trimming_packet,debug_on=debug_on)
    relaxed_dd(relaxed_dd,path_to_root,debug_on) = refine_relaxed_dd(model, max_width, relaxed_node_data_type, restricted_node_data_type,relaxed_dd, bestknownsolution, bestknownvalue, path_to_root,heuristic_trimming_packet, heuristic_ordering_packet,time_limit, time_elapsed,start_time, debug_on)
    clean_search(dd, path) = search_relaxed_dd(model, dd,path,max_width,restricted_node_data_type,relaxed_node_data_type,bestknownsolution=bestknownsolution,bestknownvalue=bestknownvalue, heuristic_packet=heuristic_trimming_packet,debug_on=debug_on)
    clean_variety_search(dd, path) = variety_search_relaxed_dd(model, dd,path,max_width,restricted_node_data_type,relaxed_node_data_type,widthofsearch=widthofsearch, bestknownsolution=bestknownsolution,bestknownvalue=bestknownvalue, heuristic_packet=heuristic_trimming_packet,debug_on=debug_on)

    clean_peel!(dd, relaxed_solution, node, node_index, path_to_root, path_to_frontier,debug_on) = peel_dd!(model, max_width, relaxed_node_data_type, restricted_node_data_type, dd, relaxed_solution, node, node_index, bestknownvalue, path_to_root, path_to_frontier, preallocatedfilterlist, heuristic_trimming_packet, heuristic_ordering_packet, time_limit, time_elapsed, start_time, logging_on, debug_on, true)
    clean_peel_and_remove!(dd,frontier_node, frontier_node_index,bestknownvalue,path_to_root,logging_on,debug_on) = peel_and_remove!(model, dd, frontier_node, frontier_node_index, bestknownvalue,path_to_root,preallocatedfilterlist, heuristic_trimming_packet, logging_on, debug_on)
    
    #get initial bounds
    if isnothing(bestknownvalue)
        bestknownsolution, bestknownvalue, exact = restricted_dd(nothing,debug_on)
        if exact
            if logging_on
                finish_peel_and_bound(bestknownsolution, bestknownvalue,start_time=start_time, time_elapsed=time_elapsed, filename=file_name)
                logruntime(start_time, time_elapsed, filename=file_name)
            end
            return bestknownsolution, bestknownvalue, bestknownvalue
        end
    end
    if timedout()
        return bestknownsolution, bestknownvalue, 0
    end
    if !seeded
        #improve initial bounds using rrb
        if !isnothing(bestknownvalue)
            bestknownsolution, bestknownvalue, exact = restricted_dd(nothing,debug_on)
        end
        #if solution is found finish
        if exact
            if logging_on
                finish_peel_and_bound(bestknownsolution, bestknownvalue,start_time=start_time, time_elapsed=time_elapsed, filename=file_name)
                logruntime(start_time, time_elapsed, filename=file_name)
            end
            return bestknownsolution, bestknownvalue, bestknownvalue
        end
        if timedout()
            return bestknownsolution, bestknownvalue, 0
        end
        if logging_on
            if !isnothing(bestknownsolution)
                log_solution(bestknownsolution, bestknownvalue,firstline="Initial Solution:", filename=file_name)
            end
            logruntime(start_time, time_elapsed, filename=file_name)
        end
    end
    
    #generate initial relaxed DD
    relaxed_dd, relaxed_bound, relaxed_solution, bestknownsolution, bestknownvalue, exact = relaxed_dd(construct_initial_relaxed_dd(model),Vector{Int}(),debug_on)

    if exact || relaxed_bound == bestknownvalue
        if logging_on
            finish_peel_and_bound(bestknownsolution, bestknownvalue,start_time=start_time, time_elapsed=time_elapsed, filename=file_name)
            logruntime(start_time, time_elapsed, filename=file_name)
        end
        return bestknownsolution, bestknownvalue, bestknownvalue
    elseif timedout()
        return bestknownsolution, bestknownvalue, 0
    else
        best_bound = relaxed_bound
        if logging_on
            logoptimalitygap(best_bound, bestknownvalue, filename=file_name)
            logruntime(start_time, time_elapsed, filename=file_name)
        end
    end

    if !seeded
        #search relaxed DD
        bestknownsolution, newbestknownvalue, exact = clean_search(relaxed_dd,Vector{Int}())
        if exact 
            bestknownvalue = newbestknownvalue
            if logging_on
                finish_peel_and_bound(bestknownsolution, bestknownvalue,start_time=start_time, time_elapsed=time_elapsed, filename=file_name)
                logruntime(start_time, time_elapsed, filename=file_name)
            end
            return bestknownsolution, bestknownvalue, bestknownvalue
        elseif bestknownvalue != newbestknownvalue
            bestknownvalue = newbestknownvalue
            if logging_on
                log_solution(bestknownsolution, bestknownvalue,firstline="Improved Solution:", filename=file_name)
                logoptimalitygap(best_bound, bestknownvalue, filename=file_name)
                logruntime(start_time, time_elapsed, filename=file_name)
            end
        end

        bestknownsolution, newbestknownvalue = clean_variety_search(relaxed_dd,Vector{Int}())
        if bestknownvalue != newbestknownvalue
            bestknownvalue = newbestknownvalue
            if logging_on
                log_solution(bestknownsolution, bestknownvalue,firstline="Improved Solution:", filename=file_name)
                logoptimalitygap(best_bound, bestknownvalue, filename=file_name)
                logruntime(start_time, time_elapsed, filename=file_name)
            end
            if bestknownvalue == best_bound
                finish_peel_and_bound(bestknownsolution, bestknownvalue,start_time=start_time, time_elapsed=time_elapsed, filename=file_name)
                logruntime(start_time, time_elapsed, filename=file_name)
                return bestknownsolution, bestknownvalue, bestknownvalue
            end
        end
    end

    #initialize queue
    ddtype = Vector{Vector{relaxed_node_data_type}}
    valuetype = typeof(best_bound)
    queue = Vector{Tuple{ddtype, valuetype, Vector{Int}, Bool}}()
    push!(queue, (relaxed_dd, best_bound, relaxed_solution, false))
    path_to_map[first(first(relaxed_dd))] = Vector{Int}()

    if logging_on
        logqueuelength(length(queue),filename=file_name)
    end

    #process queue
    while !isempty(queue)
        currentvalue = bestknownvalue
        currentblock = popfirst!(queue)

        if peel_setting == frontier
            frontier_node, frontier_node_index = getfrontiernode(currentblock[1], currentblock[3])
        elseif peel_setting == lastexactnode
            frontier_node, frontier_node_index = getlastexactnode(currentblock[1], currentblock[3])
        elseif peel_setting == maximal
            frontier_node, frontier_node_index = getmaximalpeelnode(currentblock[1], currentblock[3])
        end
        path_to_root, path_root = getpathtoroot(frontier_node)
        path_to_map[frontier_node] = append!(copy(get(path_to_map,path_root,Vector{Int}())),path_to_root)
        filteroutarcs!(frontier_node,model,bestknownvalue,heuristic_trimming_packet, preallocatedfilterlist)

        path_to_frontier_inclusive = vcat(path_to_map[frontier_node],[getstate(frontier_node)])
        block_root = first(first(currentblock[1]))

        bestknownsolution, bestknownvalue, restrictedexact = restricted_dd(convert_path_to_restricted_node(model,path_to_frontier_inclusive),debug_on)

        #time limit block
        if timedout()
            return bestknownsolution, bestknownvalue, best_bound
        end

        #time limit block
        if timedout()
            return bestknownsolution, bestknownvalue, best_bound
        end

        if restrictedexact
            #delete the node
            dd_info, bestpeeledsolution, bestpeeledvalue = clean_peel_and_remove!(currentblock[1],frontier_node, frontier_node_index,bestknownvalue,path_to_map[block_root],logging_on,debug_on)

            if !dd_info[4] && is_better_solution_value(model, dd_info[2],bestknownvalue)
                if timedout()
                    return bestknownsolution, bestknownvalue, best_bound
                end
                add_dd_to_queue!(queue, dd_info, model)
            elseif is_better_solution_value(model, bestpeeledvalue, bestknownvalue)
                bestknownvalue = bestpeeledvalue
                bestknownsolution = bestpeeledsolution
            end
        else
            #peel the dd
            dd_info, new_dd_info, bestpeeledsolution, bestpeeledvalue = clean_peel!(currentblock[1], currentblock[3], frontier_node, frontier_node_index, path_to_map[block_root],path_to_map[frontier_node],debug_on)

            if is_better_solution_value(model,bestpeeledvalue, bestknownvalue)
                bestknownvalue = bestpeeledvalue
                bestknownsolution = bestpeeledsolution
            end

            #add the DDs to the queue
            if !dd_info[4] && is_better_solution_value(model,dd_info[2], bestknownvalue)
                if timedout()
                    return bestknownsolution, bestknownvalue, best_bound
                end
                bestknownsolution, bestknownvalue, searchexact = clean_search(currentblock[1],vcat(path_to_map[block_root],[getstate(block_root)]))
                if !searchexact 
                    add_dd_to_queue!(queue, dd_info, model)
                end
            end
            if !new_dd_info[4] && is_better_solution_value(model,new_dd_info[2], bestknownvalue)
                if timedout()
                    return bestknownsolution, bestknownvalue, best_bound
                end
                path_to_map[first(first(new_dd_info[1]))] = copy(path_to_map[frontier_node])
                bestknownsolution, bestknownvalue, searchexact = clean_search(new_dd_info[1],path_to_frontier_inclusive)
                if !searchexact 
                    add_dd_to_queue!(queue, new_dd_info, model)
                end
            end
        end

        while !isempty(queue) && is_better_solution_value(model, bestknownvalue, last(queue)[2])
            deleteat!(queue, length(queue))
        end

        if !isempty(queue)
            if logging_on && is_better_solution_value(model, bestknownvalue, currentvalue)
                if !isnothing(bestknownsolution)
                    log_solution(bestknownsolution, bestknownvalue,firstline="Improved Solution:", filename=file_name)
                end
                logoptimalitygap(first(queue)[2], bestknownvalue, filename=file_name)
                logruntime(start_time, time_elapsed, filename=file_name)
                logqueuelength(length(queue),filename=file_name)
            elseif logging_on && is_better_solution_value(model, best_bound, first(queue)[2])
                logoptimalitygap(first(queue)[2], bestknownvalue, filename=file_name)
                logruntime(start_time, time_elapsed, filename=file_name)
                logqueuelength(length(queue),filename=file_name)
            end
            best_bound = first(queue)[2]
        end

        #time limit block
        if timedout()
            return bestknownsolution, bestknownvalue, best_bound
        end
    end#end process queue
    
    if logging_on
        finish_peel_and_bound(bestknownsolution, bestknownvalue,start_time=start_time, time_elapsed=time_elapsed, filename=file_name)
        logruntime(start_time, time_elapsed, filename=file_name)
    end

    return bestknownsolution, bestknownvalue, bestknownvalue
end