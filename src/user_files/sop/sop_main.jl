include("./sop_types.jl")
include("./sop_heuristics.jl")
include("./sop_optional_functions.jl")
include("./sop_mandatory_functions.jl")
include("./sop_io.jl")

function solve_sop(;num::Int=4,max_width=64, widthofsearch::Int=100, peel_setting=maximal, run_parallel::Bool=false, memory_barrier::Union{Int, Nothing}=nothing, file_name::Union{String, Nothing}=nothing, time_limit::Union{Int, Nothing}=nothing,bestknownvalue::Union{T,Nothing}=nothing)where{T<:Real}
    #convert memory barrier from GB to bytes
    if !isnothing(memory_barrier)
        memory_barrier = (memory_barrier * (1024^3))
    end
    
    model = read_sop_file(get_sop_file_path(num))
    logfilename(get_sop_file_path(num),file_name)
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

    start = time()

    if run_parallel
        run_parallel_peel_and_bound(
            model,
            max_width,
            SOP_Restricted_Node,
            SOP_Relaxed_Node,
        
            widthofsearch = widthofsearch, 

            bestknownsolution=nothing,
            bestknownvalue=bestknownvalue,
        
            peel_setting=peel_setting,
            heuristic_trimming_packet = acquire_heuristic_packet(model),
            heuristic_ordering_packet = order_sop_precedence_to_edge(model),
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
            SOP_Restricted_Node,
            SOP_Relaxed_Node,

            widthofsearch = widthofsearch, 
        
            bestknownsolution=nothing,
            bestknownvalue=bestknownvalue,
        
            peel_setting=peel_setting,
            heuristic_trimming_packet = acquire_heuristic_packet(model),
            heuristic_ordering_packet = order_sop_precedence_to_edge(model),
            seeded = !isnothing(bestknownvalue),
            
            time_limit=time_limit,
            time_elapsed=time()-start,
            logging_on=true,
            file_name=file_name,
            debug_on=false
        )
    end
end



function run_sop_experiment(instance::Int, runparallel::Bool, peel_setting::PeelSetting=maximal;seed_solver::Bool=false)
    bestknownvalue = nothing
    if seed_solver
        bestknownvalue = get_sop_solution(instance)
    end
    
    if peel_setting == frontier
        tag = "frontier_"
    elseif peel_setting == maximal
        tag = "maximal_"
    elseif peel_setting == lastexactnode
        tag = "len_"
    end

    solve_sop(
        num=4,
        max_width=1024,
        peel_setting=peel_setting,
        run_parallel=runparallel,
        memory_barrier=640, 
        file_name = nothing, 
        time_limit=60,
        widthofsearch=5
    )

    fn = ""
    if runparallel
        if instance<10
            fn = string("output/SOP/parallel/",tag,"0",instance,"_multi_thread_sop.txt")
        else
            fn = string("output/SOP/parallel/",tag,instance,"_multi_thread_sop.txt")
        end
    else
        if instance<10
            fn = string("output/SOP/single_thread/",tag,"0",instance,"_single_thread_sop.txt")
        else
            fn = string("output/SOP/single_thread/",tag,instance,"_single_thread_sop.txt")
        end
    end
    if runparallel 
        mw = 2048
    else
        mw = 2048
    end
    solve_sop(
        num=instance,
        max_width=mw,
        peel_setting=peel_setting,
        run_parallel=runparallel,
        memory_barrier=640, 
        file_name = fn, 
        time_limit=3600,
        widthofsearch=5,
        bestknownvalue = bestknownvalue
    )
end

run_sop_experiment1(instance::Int, runparallel::Bool) = run_sop_experiment(instance, runparallel, frontier)
run_sop_experiment2(instance::Int, runparallel::Bool) = run_sop_experiment(instance, runparallel, maximal)
run_sop_experiment3(instance::Int, runparallel::Bool) = run_sop_experiment(instance, runparallel, lastexactnode)