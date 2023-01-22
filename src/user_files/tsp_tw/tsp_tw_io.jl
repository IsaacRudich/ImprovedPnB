#=
    Instances from: https://lopez-ibanez.eu/tsptw-instances#code

    The format of the instances is as follows:

    1. Number of nodes (including the depot).
    2. Distance matrix. The first row is the distance from the depot to the other nodes. The first column is the distance from the other nodes to the depot. This distance typically represents the travel time between nodes i and j, plus the service time at node i, if one is given in the original instance. The distance matrix is not necessarily symmetrical.
    3. Time windows (earliest, latest) for each node, one per line. The first node is the depot.
    4. Optional comments prefixed by # that provide non-essential information, for example, the sum of service times. Results reported by us already include the sum of service time in the final objective value. If you wish to recover the objective values without service times, for example, previous works may report results that do not include it, just subtract the sum of service times from the values in the tables below.
=#

"""
    get_tsptw_filepath(set::Int=1,choice::Int=1)

The locations of the benchmark problems for convenience

# Arguments
- `set::Int`: which set to get the problem from {1->AFG, 2->GendreauDumas, 3->Langevin, 4->OhlmannThomas, 5->SolomonPesant, 6->SolomonPotvinBengio}
- `choice::Int`: which problem from the selected set to get
"""
function get_tsptw_filepath(set::Int=1,choice::Int=1)
    if set==1
        location = "./user_files/tsp_tw/instances/AFG/"
    elseif set==2
        location = "./user_files/tsp_tw/instances/GendreauDumas/"
    elseif set==3
        location = "./user_files/tsp_tw/instances/Langevin/"
    elseif set==4
        location = "./user_files/tsp_tw/instances/OhlmannThomas/"
    elseif set==5
        location = "./user_files/tsp_tw/instances/SolomonPesant/"
    elseif set==6
        location = "./user_files/tsp_tw/instances/SolomonPotvinBengio/"
    elseif set==7
        location = "./user_files/tsp_tw/instances/Dumas/"
    end

    file_name = readdir(location)[choice]

    return joinpath(location, file_name)
end

"""
    read_tsptw_file(filepath::String; makespan::Bool=false)

Read a properly formatted (TSPTW according to Gendreau) .txt file and return a TSPTW_Model

# Arguments
- `filepath::String`: The location of the tsptw file
- `makespan::Bool`: Whether or not to use the makespan version
"""
function read_tsptw_file(filepath::String; makespan::Bool=false)
    model = nothing
    open(filepath) do openedfile
        model = parse_tsptw_input!(read(openedfile, String),makespan)
    end
    return model
end

"""
    parse_tsptw_input!(input_data::String, makespan::Bool)

Convert the contents of a file, and return a TSPTW_Model

# Arguments
- `input_data::String`: The contents of file
- `makespan::Bool`: Whether or not to use the makespan version
"""
function parse_tsptw_input!(input_data::String, makespan::Bool)
    #split the file into lines and store each line as a node object
    lines = split(input_data, '\n')
    split_line = split(lines[1], (' ','\t','\r'))
    filter!(x -> x!="", split_line)

    #get num nodes
    dimension = parse(Int, first(split_line))

    #get distance matrix and time windows
    objective_values = Dict{Tuple{Int, Int}, Float64}()
    ready_times = Dict{Int, Int}()
    deadlines = Dict{Int, Int}()
    for line_number in 2:dimension+1
        split_line = split(lines[line_number], (' ','\t','\r'))
        filter!(x -> x!="", split_line)

        if line_number != 2
            objective_values[(line_number-1, dimension+1)] = parse(Float64, split_line[1])
        end

        for col in 2:dimension
            if line_number-1 != col
                objective_values[(line_number-1, col)] = parse(Float64, split_line[col])
            end
        end

        split_line = split(lines[line_number+dimension], (' ','\t','\r'))
        filter!(x -> x!="", split_line)

        ready_times[line_number-1] = parse(Int, split_line[1])
        deadlines[line_number-1] = parse(Int, split_line[2])
        if line_number == 2
            ready_times[dimension+1] = parse(Int, split_line[1])
            deadlines[dimension+1] = parse(Int, split_line[2])
        end
    end

    #figure out which values must come before a given value
    implied_preceders = Dict{Int, Vector{Int}}()
    implied_followers = Dict{Int, Vector{Int}}()
    @inbounds for i in 2:dimension
        implied_preceders[i] = Vector{Int}()
        implied_followers[i] = Vector{Int}()
        for j in 2:dimension
            if i != j
                if deadlines[i] < ready_times[j]
                    push!(implied_followers[i], j)
                elseif deadlines[j] < ready_times[i]
                    push!(implied_preceders[i], j)
                end
            end
        end
    end

    if makespan
        return TSPTWM_Model(
            SparseExtensionalObjective2D(SparseExtensionalFunction2D(objective_values),minimization),
            dimension+1,
            1,
            dimension+1,
            ready_times,
            deadlines,
            implied_preceders,
            implied_followers
        )
    else
        return TSPTW_Model(
            SparseExtensionalObjective2D(SparseExtensionalFunction2D(objective_values),minimization),
            dimension+1,
            1,
            dimension+1,
            ready_times,
            deadlines,
            implied_preceders,
            implied_followers
        )
    end
end