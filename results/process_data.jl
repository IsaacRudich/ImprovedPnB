using Plots
using Plots.PlotMeasures
using ColorSchemes
using DataStructures

struct DataPoint
    lower_bound ::Float64
    upper_bound ::Float64
    gap         ::Float64
    time        ::Float64
end

Base.show(io::IO,node::DataPoint) = Base.print(
    io,
    "[",round(node.lower_bound, digits=2),",",round(node.upper_bound, digits=2),",",round(node.gap, digits=2),",",round(node.time, digits=2),"]"
)

"""
    read_data_from_directory(directory_path::String="./processed_output/")

Process a directory of properly formatted data and return the data

# Arguments
- `directory_path::String`: The location of the sop files (must end in '/')
"""
function read_data_from_directory(directory_path::String="./processed_output/")
    file_list = readdir(directory_path)
    data = Dict{String, Vector{DataPoint}}()
    for file_name in file_list
        read_data_from_file!(data, directory_path::String,file_name::String)
    end
    return data
end

"""
    read_data_from_file!(data::Dict{String, Vector{DataPoint}}, directory_path::String,file_name::String)

Process a file with properly formatted data and update the given data 

# Arguments
- `data::Dict{String, Vector{DataPoint}}`: The data to update
- `directory_path::String`: The location of the sop files (must end in '/')
- `file_name::String`: The name of the file to read
"""
function read_data_from_file!(data::Dict{String, Vector{DataPoint}}, directory_path::String,file_name::String)
    open(string(directory_path,file_name)) do opened_file
        file_data = read(opened_file, String)
        #lineformat = lower_bound,upper_bound,optimality_gap,time
        lines = split(file_data, '\n')

        instance_name = lines[1]
        points = Vector{DataPoint}()
        
        for i in 2:length(lines)
            line = split(lines[i], (','))
            if length(line)>=4
                new_point = DataPoint(parse(Float64,line[1]),parse(Float64,line[2]),parse(Float64,line[3]),parse(Float64,line[4]))
                push!(points, new_point)
                if new_point.gap == 0
                    break
                end
            end
        end

        data[instance_name] = points
    end
end

function get_tsptw_performance_data()
    tsptw_single = read_data_from_directory("./processed_output/TSPTW_Single_2048/")
    tsptw_single_x, tsptw_single_y = turn_processed_data_into_performance_data(tsptw_single)

    tsptw_seeded = read_data_from_directory("./processed_output/TSPTW_Seeded_Single_2048/")
    tsptw_seeded_x, tsptw_seeded_y = turn_processed_data_into_performance_data(tsptw_seeded)
    
    return [("standard_2048",tsptw_single_x, tsptw_single_y),("seeded_2048",tsptw_seeded_x, tsptw_seeded_y)]
end

function get_tsptw_time_data()
    tsptw_single = read_data_from_directory("./processed_output/TSPTW_Single_2048/")
    tsptw_single_x, tsptw_single_y =  turn_processed_data_into_time_data(tsptw_single)

    tsptw_seeded = read_data_from_directory("./processed_output/TSPTW_Seeded_Single_2048/")
    tsptw_seeded_x, tsptw_seeded_y = turn_processed_data_into_time_data(tsptw_seeded)

    return [("standard_2048",tsptw_single_x, tsptw_single_y),("seeded_2048",tsptw_seeded_x, tsptw_seeded_y)]
end

function get_tsptwm_performance_data()
    tsptwm_single = read_data_from_directory("./processed_output/TSPTWM_Single_2048/")
    tsptwm_single_x, tsptwm_single_y = turn_processed_data_into_performance_data(tsptwm_single)

    tsptwm_seeded = read_data_from_directory("./processed_output/TSPTWM_Seeded_Single_2048/")
    tsptwm_seeded_x, tsptwm_seeded_y = turn_processed_data_into_performance_data(tsptwm_seeded)
    
    return [("standard_2048",tsptwm_single_x, tsptwm_single_y),("seeded_2048",tsptwm_seeded_x, tsptwm_seeded_y)]
end

function get_tsptwm_time_data()
    tsptwm_single = read_data_from_directory("./processed_output/TSPTWM_Single_2048/")
    tsptwm_single_x, tsptwm_single_y = turn_processed_data_into_time_data(tsptwm_single)

    tsptwm_seeded = read_data_from_directory("./processed_output/TSPTWM_Seeded_Single_2048/")
    tsptwm_seeded_x, tsptwm_seeded_y = turn_processed_data_into_time_data(tsptwm_seeded)

    return [("standard_2048",tsptwm_single_x, tsptwm_single_y),("seeded_2048",tsptwm_seeded_x, tsptwm_seeded_y)]
end

function get_sop_performance_data()
    sop_frontier = read_data_from_directory("./processed_output/SOP_Single_2048_frontier/")
    sop_len = read_data_from_directory("./processed_output/SOP_Single_2048_len/")
    sop_maximal = read_data_from_directory("./processed_output/SOP_Single_2048_maximal/")

    sop_frontier_x, sop_frontier_y = turn_processed_data_into_performance_data(sop_frontier)
    sop_len_x, sop_len_y = turn_processed_data_into_performance_data(sop_len)
    sop_maximal_x, sop_maximal_y = turn_processed_data_into_performance_data(sop_maximal)

    old_sop_y = [0.146341463414634,0.170731707317073,0.195121951219512,0.219512195121951,0.24390243902439,0.268292682926829,0.292682926829268,0.317073170731707,0.341463414634146,0.365853658536585,0.390243902439024,0.414634146341464,0.439024390243903,0.463414634146342,0.487804878048781,0.51219512195122,0.536585365853659,0.560975609756098,0.585365853658537,0.609756097560976,0.634146341463415,0.658536585365854,0.682926829268293,0.707317073170732,0.731707317073171,0.75609756097561,0.780487804878049,0.804878048780488,0.829268292682927,0.853658536585366,0.878048780487805,0.902439024390244,0.926829268292683,0.951219512195122,0.975609756097562,1]
    old_sop_x = [0,4.16091160220994,4.39655172413793,6.01083643752117,19.5149001832385,21.200965744747,25.2929284145997,26.4164112523898,27.3326229799325,29.0322580645161,30.3822574828705,32.361963190184,37.2708510379993,39.3482831114226,41.7624521072797,42.8936962084206,47.9490806223479,48.9259816664386,48.9606497147829,53.2041074076108,53.7079599367422,54.1143007000061,54.7792222667659,59.7690941385435,61.7542728152209,63.2734530938124,63.4980988593156,63.75447254781,65.4541074439894,70.6169227017801,74.6594005449591,87.3198847262248,87.7935633516962,88.9038785834739,96.5825614819546,97.7831036548832]
    return [("frontier",sop_frontier_x, sop_frontier_y),("last exact node",sop_len_x, sop_len_y),("maximal",sop_maximal_x, sop_maximal_y),("best_of_original",old_sop_x,old_sop_y)]
end

function get_sop_time_data()
    sop_frontier = read_data_from_directory("./processed_output/SOP_Single_2048_frontier/")
    sop_len = read_data_from_directory("./processed_output/SOP_Single_2048_len/")
    sop_maximal = read_data_from_directory("./processed_output/SOP_Single_2048_maximal/")

    sop_frontier_x, sop_frontier_y = turn_processed_data_into_time_data(sop_frontier)
    sop_len_x, sop_len_y = turn_processed_data_into_time_data(sop_len)
    sop_maximal_x, sop_maximal_y = turn_processed_data_into_time_data(sop_maximal)

    return [("frontier",sop_frontier_x, sop_frontier_y),("last exact node",sop_len_x, sop_len_y),("maximal",sop_maximal_x, sop_maximal_y)]
end

function read_ddo_results(file_name::String)
    directory_path = "./ddo_results/"
    x = Vector{Float64}()
    y = Vector{Float64}()
    open(string(directory_path,file_name)) do opened_file
        file_data = read(opened_file, String)
        #lineformat = duration, proved
        lines = split(file_data, '\n')

        
        for i in 2:length(lines)
            line = split(lines[i], (' '))
            filter!(x->length(x)>1,line)
            if length(line)>=2
                push!(x,parse(Float64,line[1]))
            end
        end
    end

    sort!(x)
    for i in eachindex(x)
        push!(y,i)
    end

    return x,y
end

function get_ddo_results()
    xp,yp = read_ddo_results("tsptw.rub_locb.24.data")
    x,y = read_ddo_results("tsptw.rub_locb.data")

    return [("ddo_1_thread",x,y),("ddo_24_threads",xp,yp)]
end

function turn_processed_data_into_performance_data(data::Dict{String, Vector{DataPoint}})
    performance_data = Vector{DataPoint}()
    @inbounds for (name,list) in data
        push!(performance_data, last(list))
    end

    sort!(performance_data, by=x->x.gap)

    x = Vector{Float64}()
    y = Vector{Float64}()

    for index in 1:lastindex(performance_data)-1
        current_data = performance_data[index]
        next_data = performance_data[index+1]
        if next_data.gap > current_data.gap
            push!(x, current_data.gap)
            push!(y, index/lastindex(performance_data))
        end
    end

    last_data = last(performance_data)

    push!(x,last_data.gap)
    push!(y,1)

    return x,y
end

function turn_processed_data_into_time_data(data::Dict{String, Vector{DataPoint}})
    time_data = Vector{DataPoint}()
    @inbounds for (name,list) in data
        point = last(list)
        if point.gap != 0
            continue
        end
        for item in reverse(list)
            if item.gap == 0
                point = item
            else
                break
            end
        end
        push!(time_data, point)
    end

    sort!(time_data, by=x->x.time)

    x = Vector{Float64}()
    y = Vector{Float64}()

    counter = 0
    for point in time_data
        counter += 1
        push!(x, point.time)
        push!(y, counter)
    end

    return x,y
end

function summarize_processed_data(data::Dict{String, Vector{DataPoint}}, file_name::String)
    summary = Vector{Tuple{String, Float64, Float64, Float64, Float64}}()
   
    for (name, point) in data
        if last(point).gap == 0 && length(point)>1 && point[lastindex(point)-1].gap == 0
            point = point[lastindex(point)-1]
        else
            point = last(point)
        end
        push!(summary, (name, point.lower_bound, point.upper_bound, point.gap, point.time))
    end

    f = open(string("./summaries/",file_name),"w")
        for line in summary
            write(f, string(line[1]," ",line[2]," ",line[3]," ",line[4]," ",line[5],"\n"))
        end
    close(f)
end

function generate_summaries()
    summarize_processed_data(read_data_from_directory("./processed_output/TSPTW_Single_2048/"),"tsptw_single_2048")
    summarize_processed_data(read_data_from_directory("./processed_output/TSPTWM_Single_2048/"),"makespan_single_2048")
    summarize_processed_data(read_data_from_directory("./processed_output/TSPTW_Seeded_Single_2048/"),"tsptw_seeded_single_2048")
    summarize_processed_data(read_data_from_directory("./processed_output/TSPTWM_Seeded_Single_2048/"),"makespan_seeded_single_2048")
end

function graph_data_performance(data::Vector{Tuple{String, Vector{Float64}, Vector{Float64}}};name::String="./performance_profile.pdf", ylims::Tuple{Float64,Float64}=(0.0,1.05), xlims::Tuple{Int,Int}=(0,100), ytick::Float64=.1,xtick::Float64=20.0)
    cs = palette(ColorSchemes.rainbow, 7)
    ms = [:star4,:rect, :diamond, :utriangle, :circle,:x,:+]

    p = plot(
        ylims=ylims,xlims=xlims,
        legendfontsize = 8,
        xlabel="Optimality Gap", ylabel="Percentage of Instances",
        size = (790,420),dpi=600,
        legend= :bottomright,
        yformatter = n -> string(round(n*100),"%"),xformatter = n -> string(round(n),"%"),
        bottom_margin = 40px,left_margin = 40px,right_margin = 40px,
        xticks = range(xlims[1], stop = xlims[2], step = xtick),
        yticks = range(ylims[1], stop = ylims[2], step = ytick)
    )
    for (i,points) in enumerate(data)
        p = plot!(
            points[2],points[3],label=points[1],
            color=cs[i],marker=ms[i],
            markersize = 3, markerstrokewidth=.5,
            legend_spacing = 0px,
            grid = true
        )
    end
    display(p)
    savefig(name)
end

function graph_data_time(data::Vector{Tuple{String, Vector{Float64}, Vector{Float64}}};name::String="./performance_profile.pdf", ylims::Tuple{Int,Int}=(0,300), xlims::Tuple{Int,Int}=(0,1800),ytick::Float64=20.0,xtick::Float64=200.0, legend::Any=:bottomright)
    cs = palette(ColorSchemes.rainbow, 7)
    cs = [cs[1],cs[7],cs[3],cs[5]]
    ms = [:star4, :utriangle, :circle,:x,:+,:rect, :diamond]

    p = plot(ylims=ylims,xlims=xlims,
        legendfontsize = 8,
        xlabel="Duration (sec)", ylabel="# Instances Solved to Optimality", 
        size = (790,420),dpi=600, legend= legend,
        bottom_margin = 40px,left_margin = 40px,right_margin = 40px,
        xticks = range(xlims[1], stop = xlims[2], step = xtick),
        yticks = range(ylims[1], stop = ylims[2], step = ytick)
        
    )

    for (i,points) in enumerate(data)
        p = scatter!(
            points[2],points[3],label=points[1],
            color=cs[i],marker=ms[i],
            markersize = 4, markerstrokewidth=1.5,
            legend_spacing = 0px,
            grid = true
        )
    end
    display(p)
    savefig(name)
end

function graph_tsptw_data()
    graph_data_performance(get_tsptw_performance_data(),name="./tsptw_performance_profiles.pdf", ylims=(0.6,1.0), xlims=(0,100))
    graph_data_time(vcat(get_tsptw_time_data(),get_ddo_results()),name="./tsptw_solved_instances.pdf",ylims=(200,320),xlims=(0,1800),xtick=200.0, legend=:topleft)
end

function graph_tsptwm_data()
    graph_data_performance(get_tsptwm_performance_data(),name="./makespan_performance_profiles.pdf", ylims=(0.93,1.0), xlims=(0,100),ytick=.01)
    graph_data_time(vcat(get_tsptwm_time_data()),name="./makespan_solved_instances.pdf",xlims=(000,3600),ylims=(360,460),xtick=400.0)
end

function graph_sop_data()
    graph_data_performance(get_sop_performance_data(),name="./sop_performance_profiles.pdf", ytick=.2)
    graph_data_time(get_sop_time_data(),name="./sop_solved_instances.pdf", ylims=(0,11),ytick=2.0)
end