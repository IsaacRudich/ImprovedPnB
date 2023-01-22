#export JULIA_NUM_THREADS=4 (before starting julia)
#or start julia with: julia --threads 4

"""

    run_parallel_peel_and_bound(
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

        memory_barrier::Union{Nothing, Int} = nothing,
        time_limit::Union{Nothing, W}=nothing,
        time_elapsed::X=0.0,
        logging_on::Bool=true,
        file_name::Union{Nothing,String}=nothing,
        debug_on::Bool=false
    )where{T<:ProblemModel,U<:Real,W<:Real,X<:Real}

Solve a problem to optimality using a peel and bound scheme and multiple threads
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
- `memory_barrier::Union{Nothing, Int}`: An optional paramter that provides a limit to how much memory the queue will use
- `time_limit::Union{Nothing, W}`: An optional parameter that adds a time limit
- `time_elapsed::X`: An optional parameter denoting how much time passed already
- `logging_on::Bool`: An optional parameter that can be used to turn off logging to the console and local file
- `file_name::Union{Nothing,String}`: The file to write results to
- `debug_on::Bool`: An optional parameter that can be used to turn on debug statements in other functions
"""
function run_parallel_peel_and_bound(
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

    memory_barrier::Union{Nothing, Int} = nothing,
    time_limit::Union{Nothing, W}=nothing,
    time_elapsed::X=0.0,
    logging_on::Bool=true,
    file_name::Union{Nothing,String}=nothing,
    debug_on::Bool=false
)where{T<:ProblemModel,U<:Real,W<:Real,X<:Real}
    if isnothing(memory_barrier)
        memory_barrier = Sys.total_memory()
    end

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

    queue_lock = ReentrantLock()
    count_lock = ReentrantLock()
    solution_lock = ReentrantLock()
    pathmap_lock = ReentrantLock()
    bound_tracker_lock = ReentrantLock()
    bound_tracker = Vector{Float64}()
    best_bound = Ref(best_bound)
    running_jobs = Ref(0)
    bestknownvalue = Ref{Union{Nothing,valuetype}}(bestknownvalue)
    bestknownsolution = Ref{Union{Nothing,Vector{Int}}}(bestknownsolution)
    passablecopy = nothing
    #process queue

    errors = Vector{Any}()
    error_lock = ReentrantLock()
    logged_bound = best_bound[]
    logged_solution_value = bestknownvalue[]

    count_check = false

    while !isempty(queue) || running_jobs[] > 0
        if !isempty(errors)
            throw(first(errors))
        end

        begin
            lock(bound_tracker_lock)
            if logged_bound!= best_bound[] || logged_solution_value!=bestknownvalue[]
                try
                    logged_bound = best_bound[]
                    logged_solution_value = bestknownvalue[]
                finally
                    unlock(bound_tracker_lock)
                end
                if logging_on 
                    logoptimalitygap(logged_bound, logged_solution_value, filename=file_name)
                    logruntime(start_time, time_elapsed, filename=file_name)
                    begin
                        lock(queue_lock)
                        try
                            logqueuelength(length(queue),filename=file_name)
                        finally
                            unlock(queue_lock)
                        end
                    end
                end
            else
                unlock(bound_tracker_lock)
            end
        end

        count_check = false
        begin
            lock(count_lock)
            try
                if running_jobs[] >= Threads.nthreads() || isempty(queue)
                    count_check = true
                end
            finally
                unlock(count_lock)
            end
        end
        
        if count_check
            sleep(.001)
            continue
        end
        
        currentblock = nothing

        begin
            lock(queue_lock)
            try
                if !isempty(queue)
                    # print("Working: ", bound_tracker, " ")
                    # print("Queue: ")
                    # for b in queue
                    #     print(b[2]," ")
                    # end
                    # println()

                    currentblock = popfirst!(queue)

                    #println("Memory: ",round(Sys.free_memory()/memory_barrier,digits=2))
                    # if Sys.free_memory()/memory_barrier > .00
                    #     currentblock = popfirst!(queue)
                    # else
                    #     currentblock = pop!(queue)
                    # end
                end
            finally
                unlock(queue_lock)
            end
        end
       
        if !isnothing(currentblock)
            if isnothing(bestknownsolution[])
                passablecopy = nothing
            else
                passablecopy = copy(bestknownsolution[])
            end
 
            task = Threads.@spawn begin
                try
                    result = async_peel_and_bound_node!(model,max_width,true,queue,path_to_map,queue_lock, solution_lock,count_lock, pathmap_lock,running_jobs,bound_tracker_lock, bound_tracker, best_bound, currentblock,passablecopy,bestknownvalue[],restricted_node_data_type,relaxed_node_data_type,bestknownsolution,bestknownvalue,peel_setting,heuristic_trimming_packet,heuristic_ordering_packet,time_limit,start_time,time_elapsed,logging_on,file_name,debug_on)
                catch e
                    begin
                        lock(error_lock)
                        try
                            push!(errors, e)
                        finally
                            unlock(error_lock)
                        end
                    end
                   
                end
            end
            
            begin
                lock(count_lock)
                try
                    running_jobs[] += 1
                    # if logging_on
                    #     println("Running Jobs: ", running_jobs[], " | Queue: ", length(queue), " | Local Bound: ", currentblock[2])
                    # end
                finally
                    unlock(count_lock)
                end
            end
        end

        #time limit block
        if timedout()
            return bestknownsolution[], bestknownvalue[], best_bound[]
        end
        
    end#end process queue
    
    if logging_on
        finish_peel_and_bound(bestknownsolution[], bestknownvalue[],start_time=start_time, time_elapsed=time_elapsed, filename=file_name)
        logruntime(start_time, time_elapsed, filename=file_name)
    end

    return bestknownsolution[], bestknownvalue[], bestknownvalue[]
end








function async_peel_and_bound_node!(
    model::T,
    max_width::Int,

    do_bounding::Bool,
    queue::Vector{Tuple{Vector{Vector{Y}}, U, Vector{Int}, Bool}},
    path_to_map::Dict{Y, Vector{Int}},
    queue_lock::ReentrantLock, 
    solution_lock::ReentrantLock,
    count_lock::ReentrantLock, 
    pathmap_lock::ReentrantLock,
    job_count::Ref{Int}, 

    bound_tracker_lock::ReentrantLock,
    bound_tracker::Vector{Z},
    best_bound::Ref{Z2},

    currentblock::Tuple{Vector{Vector{Y}}, U2, Vector{Int}, Bool},

    bestknownsolution::Union{Vector{Int},Nothing},
    bestknownvalue::Union{U3,Nothing},

    restricted_node_data_type::Union{DataType,UnionAll},
    relaxed_node_data_type::Union{DataType,UnionAll},

    solution_ref::Ref{Union{Nothing,Vector{Int}}}, 
    value_ref::Ref{Union{Nothing,B}}, 

    peel_setting::PeelSetting=frontier,
    heuristic_trimming_packet = nothing,
    heuristic_ordering_packet = nothing,

    time_limit::Union{Nothing, W}=nothing,
    start_time::X=0.0,
    time_elapsed::X=0.0,
    logging_on::Bool=true,
    file_name::Union{Nothing,String}=nothing,
    debug_on::Bool=false
)where{T<:ProblemModel,U<:Real,U2<:Real,U3<:Real,W<:Real,X<:Real,Y<:RelaxedFrameworkNode, Z<:Real,Z2<:Real,B<:Real}
    begin
        lock(bound_tracker_lock)
        try
            #println("Adding: ", currentblock[2], " to ",bound_tracker)
            push!(bound_tracker, currentblock[2])
        finally
            unlock(bound_tracker_lock)
        end
    end

    timedout() = is_timed_out(time_limit,start_time, time_elapsed)

    restricted_dd(rootnode,debug_on) = construct_restricted_dd(model, max_width, restricted_node_data_type,rootnode=rootnode,bestknownsolution=bestknownsolution,bestknownvalue=bestknownvalue, heuristic_packet=heuristic_trimming_packet,debug_on=debug_on)
    relaxed_dd(relaxed_dd,path_to_root,debug_on) = refine_relaxed_dd(model, max_width, relaxed_node_data_type, restricted_node_data_type, relaxed_dd, bestknownsolution, bestknownvalue, path_to_root,heuristic_trimming_packet, heuristic_ordering_packet,time_limit, time_elapsed,start_time, debug_on)
    clean_search(dd, path) = search_relaxed_dd(model, dd,path,max_width,restricted_node_data_type,relaxed_node_data_type,bestknownsolution=bestknownsolution,bestknownvalue=bestknownvalue, heuristic_packet=heuristic_trimming_packet,debug_on=debug_on)

    clean_peel!(dd, relaxed_solution, node, node_index,path_to_root, path_to_frontier,debug_on) = peel_dd!(model, max_width, relaxed_node_data_type, restricted_node_data_type,dd, relaxed_solution, node, node_index, bestknownvalue, path_to_root, path_to_frontier,preallocatedfilterlist, heuristic_trimming_packet, heuristic_ordering_packet, time_limit, time_elapsed, start_time, logging_on, debug_on,do_bounding)
    clean_peel_and_remove!(dd,frontier_node, frontier_node_index,bestknownvalue,path_to_root,logging_on,debug_on) = peel_and_remove!(model, dd, frontier_node, frontier_node_index, bestknownvalue,path_to_root, preallocatedfilterlist, heuristic_trimming_packet, logging_on, debug_on)
    
    preallocatedfilterlist = Vector{relaxed_node_data_type}()
    sizehint!(preallocatedfilterlist, max_width)

    if peel_setting == frontier
        frontier_node, frontier_node_index = getfrontiernode(currentblock[1], currentblock[3])
    elseif peel_setting == lastexactnode
        frontier_node, frontier_node_index = getlastexactnode(currentblock[1], currentblock[3])
    elseif peel_setting == maximal
        frontier_node, frontier_node_index = getmaximalpeelnode(currentblock[1], currentblock[3])
    end
    path_to_root, path_root = getpathtoroot(frontier_node)
    begin
        lock(pathmap_lock)
        try
            path_to_map[frontier_node] = append!(copy(get(path_to_map,path_root,Vector{Int}())),path_to_root)
        finally
            unlock(pathmap_lock)
        end
    end
    filteroutarcs!(frontier_node,model,bestknownvalue,heuristic_trimming_packet, preallocatedfilterlist)

    path_to_frontier_inclusive = vcat(path_to_map[frontier_node],[getstate(frontier_node)])
    block_root = first(first(currentblock[1]))

    bestknownsolution, bestknownvalue, restrictedexact = restricted_dd(convert_path_to_restricted_node(model,path_to_frontier_inclusive),debug_on)

    #time limit block
    if timedout()
        return bestknownsolution, bestknownvalue
    end

    if restrictedexact
        #delete the node
        dd_info, bestpeeledsolution, bestpeeledvalue = clean_peel_and_remove!(currentblock[1],frontier_node, frontier_node_index,bestknownvalue,path_to_map[block_root],logging_on,debug_on)

        if !dd_info[4] && is_better_solution_value(model, dd_info[2],bestknownvalue)
            #time limit block
            if timedout()
                return bestknownsolution, bestknownvalue
            end
            begin
                lock(queue_lock)
                try
                    add_dd_to_queue!(queue, dd_info, model)
                finally
                    unlock(queue_lock)
                end
            end
        elseif is_better_solution_value(model, bestpeeledvalue, bestknownvalue)
            bestknownvalue = bestpeeledvalue
            bestknownsolution = bestpeeledsolution
        end
    else
        #peel the dd
        dd_info, new_dd_info, bestpeeledsolution, bestpeeledvalue = clean_peel!(currentblock[1], currentblock[3], frontier_node, frontier_node_index,path_to_map[block_root],path_to_map[frontier_node],debug_on)

        if is_better_solution_value(model,bestpeeledvalue, bestknownvalue)
            bestknownvalue = bestpeeledvalue
            bestknownsolution = bestpeeledsolution
        end

        #add the DDs to the queue
        if !dd_info[4] && is_better_solution_value(model,dd_info[2], bestknownvalue)
            #time limit block
            if timedout()
                return bestknownsolution, bestknownvalue
            end
            bestknownsolution, bestknownvalue, searchexact = clean_search(currentblock[1],vcat(path_to_map[block_root],[getstate(block_root)]))
            if !searchexact 
                begin
                    lock(queue_lock)
                    try
                        add_dd_to_queue!(queue, dd_info, model)
                    finally
                        unlock(queue_lock)
                    end
                end
            end
        end
        if !new_dd_info[4] && is_better_solution_value(model,new_dd_info[2], bestknownvalue)
            #time limit block
            if timedout()
                return bestknownsolution, bestknownvalue
            end
            path_to_map[first(first(new_dd_info[1]))] = copy(path_to_map[frontier_node])
            bestknownsolution, bestknownvalue, searchexact = clean_search(new_dd_info[1],path_to_frontier_inclusive)
            if !searchexact 
                begin
                    lock(queue_lock)
                    try
                        add_dd_to_queue!(queue, new_dd_info, model)
                    finally
                        unlock(queue_lock)
                    end
                end
            end
        end
    end

    #time limit block
    if timedout()
        return bestknownsolution, bestknownvalue
    end

    while !isempty(queue) && is_better_solution_value(model, bestknownvalue, last(queue)[2])
        begin
            lock(queue_lock)
            try
                deleteat!(queue, length(queue))
            finally
                unlock(queue_lock)
            end
        end
    end

    #update solution value
    if is_better_solution_value(model, bestknownvalue, value_ref[])
        begin
            lock(solution_lock)
            try
                value_ref[] = bestknownvalue
                solution_ref[] = bestknownsolution
                # if logging_on
                #     if !isnothing(bestknownsolution)
                #         log_solution(bestknownsolution, bestknownvalue,firstline="Improved Solution:", filename=file_name)
                #     end
                #     logruntime(start_time, time_elapsed, filename=file_name)
                # end
            finally
                unlock(solution_lock)
            end
        end
    end

    begin
        lock(bound_tracker_lock)
        try
            #println("Removing: ", currentblock[2], " from ",bound_tracker)
            deleteat!(bound_tracker, findfirst(x -> x==currentblock[2], bound_tracker))
            btb = bestknownvalue
            for b in bound_tracker
                if is_better_solution_value(model, b, btb)
                    btb = b
                end
            end
            if !isempty(queue) && is_better_solution_value(model, first(queue)[2], btb)
                btb = first(queue)[2]
            end
            if is_better_solution_value(model, best_bound[], btb) && btb != bestknownvalue
                best_bound[] = btb
                # if logging_on
                #     logoptimalitygap(btb, value_ref[], filename=file_name)
                #     logruntime(start_time, time_elapsed, filename=file_name)
                #     logqueuelength(length(queue),filename=file_name)
                # end
            end
        finally
            unlock(bound_tracker_lock)
        end
    end

    #update job count
    begin
        lock(count_lock)
        try
            #println("P",Threads.threadid(), " has finished a task")
            job_count[] -= 1
        finally
            unlock(count_lock)
        end
    end
    # sleep(.001)
    return bestknownsolution, bestknownvalue
end