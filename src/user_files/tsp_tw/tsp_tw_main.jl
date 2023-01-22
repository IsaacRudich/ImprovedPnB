include("./tsp_tw_types.jl")
include("./tsp_tw_heuristics.jl")
include("./tsp_tw_optional_functions.jl")
include("./tsp_tw_mandatory_functions.jl")
include("./tsp_tw_io.jl")




function solve_tsptw(makespan::Bool;set::Int=1,num::Int=1,max_width=128, widthofsearch::Int=100,peel_setting=maximal, run_parallel::Bool=false, memory_barrier::Union{Int, Nothing}=nothing, file_name::Union{String, Nothing}=nothing, time_limit::Union{Int, Nothing}=nothing,bestknownvalue::Union{T,Nothing}=nothing)where{T<:Real}
    
    #convert memory barrier from GB to bytes
    if !isnothing(memory_barrier)
        memory_barrier = (memory_barrier * (1024^3))
    end

    model = read_tsptw_file(get_tsptw_filepath(set,num), makespan = makespan)
    logfilename(get_tsptw_filepath(set,num),file_name)
    logsetting("Makespan Objective: ", makespan, filename=file_name)
    logsetting("Peel Setting: ", peel_setting, filename=file_name)
    logsetting("Max Width: ", max_width, filename=file_name)
    logsetting("Variety Search Width: ", widthofsearch, filename=file_name)
    logsetting("Parallel: ",run_parallel, filename=file_name)
    logsetting("Threads: ",Threads.nthreads(), filename=file_name)
    if !isnothing(time_limit)
        logsetting("Time Limit (seconds): ",time_limit, filename=file_name)
    end
    if !isnothing(memory_barrier)
        logsetting("Memory Limit (GB): ",memory_barrier / (1024^3), filename=file_name)
    end

    if makespan
        restricted_data_type = TSPTWM_Restricted_Node
        relaxed_data_type = TSPTWM_Relaxed_Node
    else
        restricted_data_type = TSPTW_Restricted_Node
        relaxed_data_type = TSPTW_Relaxed_Node
    end

    start = time()

    if run_parallel
        run_parallel_peel_and_bound(
            model,
            max_width,
            restricted_data_type,
            relaxed_data_type,
        
            widthofsearch = widthofsearch,

            bestknownsolution=nothing,
            bestknownvalue=bestknownvalue,
        
            peel_setting=peel_setting,
            heuristic_trimming_packet = acquire_heuristic_packet(model),
            heuristic_ordering_packet = order_tsptw_edge(model),
            seeded = !isnothing(bestknownvalue),
        
            memory_barrier = memory_barrier,
            time_limit=time_limit,
            time_elapsed=time()-start,
            logging_on=true,
            file_name=file_name,
            debug_on=false
        )
    else
        run_peel_and_bound(
            model,
            max_width,
            restricted_data_type,
            relaxed_data_type,

            widthofsearch = widthofsearch,
        
            bestknownsolution=nothing,
            bestknownvalue=bestknownvalue,
        
            peel_setting=peel_setting,
            heuristic_trimming_packet = acquire_heuristic_packet(model),
            heuristic_ordering_packet = order_tsptw_edge(model),
            seeded = !isnothing(bestknownvalue),
            
            time_limit=time_limit,
            time_elapsed=time()-start,
            logging_on=true,
            file_name=file_name,
            debug_on=false
        )
    end
end


function run_tsptw_experiment(setnum::Int, instance::Int, runparallel::Bool;seed_solver::Bool=false)
    bestknownvalue = nothing
    if seed_solver
        bestknownvalue = get_tsptw_solution(setnum, instance, false)
    end

    tag = ""
    if setnum==1
        tag = "AFG_"
    elseif setnum==2
        tag = "GD_"
    elseif setnum==3
        tag = "L_"
    elseif setnum==4
        tag = "OT_"
    elseif setnum==5
        tag = "SP_"
    elseif setnum==6
        tag = "SPB_"
    end

    solve_tsptw(
        false,
        set=1,
        num=20,
        max_width=2048,
        peel_setting=maximal,
        run_parallel=runparallel,
        memory_barrier=640, 
        file_name = nothing, 
        time_limit=nothing,
        widthofsearch=100
    )
    fn = ""
    instancename = ""#last(split(get_tsptw_filepath(setnum,instance),"/"))
    if runparallel
        if instance<10
            fn = string("output/TSPTW/parallel/",tag,"0",instance,instancename,"_multi_thread_tsptw.txt")
        else
            fn = string("output/TSPTW/parallel/",tag,instance,instancename,"_multi_thread_tsptw.txt")
        end
    else
        if instance<10
            fn = string("output/TSPTW/single_thread/",tag,"0",instance,instancename,"_single_thread_tsptw.txt")
        else
            fn = string("output/TSPTW/single_thread/",tag,instance,instancename,"_single_thread_tsptw.txt")
        end
    end
    if runparallel 
        mw = 2048
    else
        mw = 2048
    end
    solve_tsptw(
        false,
        set=setnum,
        num=instance,
        max_width=mw,
        peel_setting=maximal,
        run_parallel=runparallel,
        memory_barrier=640, 
        file_name = fn, 
        time_limit=3600,
        widthofsearch=100,
        bestknownvalue = bestknownvalue
    )
end

function run_tsptwm_experiment(setnum::Int, instance::Int, runparallel::Bool;seed_solver::Bool=false)
    bestknownvalue = nothing
    if seed_solver
        bestknownvalue = get_tsptw_solution(setnum, instance, true)
    end

    tag = ""
    if setnum==1
        tag = "AFG_"
    elseif setnum==2
        tag = "GD_"
    elseif setnum==3
        tag = "L_"
    elseif setnum==4
        tag = "OT_"
    elseif setnum==5
        tag = "SP_"
    elseif setnum==6
        tag = "SPB_"
    elseif setnum==7
        tag = "D_"
    end

    solve_tsptw(
        true,
        set=1,
        num=20,
        max_width=2048,
        peel_setting=maximal,
        run_parallel=runparallel,
        memory_barrier=640, 
        file_name = nothing, 
        time_limit=nothing,
        widthofsearch=100
    )
    fn = ""
    instancename = ""#last(split(get_tsptw_filepath(setnum,instance),"/"))
    if runparallel
        if instance<10
            fn = string("output/TSPTWM/parallel/",tag,"0",instance,instancename,"_multi_thread_tsptw.txt")
        else
            fn = string("output/TSPTWM/parallel/",tag,instance,instancename,"_multi_thread_tsptw.txt")
        end
    else
        if instance<10
            fn = string("output/TSPTWM/single_thread/",tag,"0",instance,instancename,"_single_thread_tsptw.txt")
        else
            fn = string("output/TSPTWM/single_thread/",tag,instance,instancename,"_single_thread_tsptw.txt")
        end
    end
    if runparallel 
        mw = 2048
    else
        mw = 2048
    end
    solve_tsptw(
        true,
        set=setnum,
        num=instance,
        max_width=mw,
        peel_setting=maximal,
        run_parallel=runparallel,
        memory_barrier=640, 
        file_name = fn, 
        time_limit=3600,
        widthofsearch=100,
        bestknownvalue = bestknownvalue
    )
end

function get_tsptw_solution(set::Int, num::Int, makespan::Bool)
    filename = last(split(get_tsptw_filepath(set,num),"/"))
    value = 0

    open("./user_files/tsp_tw/instances/solutions.txt") do openedfile
        data = read(openedfile, String)
        lines = split(data, '\n')

        for line in lines
            line = split(line, (' ','\t'))
            name = line[1]
            if filename == name
                if makespan
                    value = parse(Float64, line[3])
                else
                    value = parse(Float64, line[2])
                end
                break
            end
        end
    end

    return value
end