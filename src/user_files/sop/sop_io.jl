"""
    get_sop_file_path(num::Int;getset::Bool=false)

The locations of the benchmark problems for convenience

# Arguments
- `num::Int`: which problem from the selected set to get
- `getset::Bool`: An optional parameter that can be used to get an entire set instead of just one
"""
function get_sop_file_path(num::Int;getset::Bool=false)
    #SOPLIB: http://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/
    paths = String[
        "./user_files/sop/instances/ESC07.sop",#2125 (1)
        "./user_files/sop/instances/ESC11.sop",#2075 (2)
        "./user_files/sop/instances/ESC12.sop",#1675 (3)
        "./user_files/sop/instances/ESC25.sop",#1681 (4)
        "./user_files/sop/instances/ESC47.sop",#1288 (5)
        "./user_files/sop/instances/ESC63.sop",#62 (6)
        "./user_files/sop/instances/ESC78.sop",#18230 (7)
        "./user_files/sop/instances/br17.10.sop",#55 (8)
        "./user_files/sop/instances/br17.12.sop",#55 (9)
        "./user_files/sop/instances/ft53.1.sop",#7531 (10)
        "./user_files/sop/instances/ft53.2.sop",#8026 (11)
        "./user_files/sop/instances/ft53.3.sop",#10262 (12)
        "./user_files/sop/instances/ft53.4.sop",#14425 (13)
        "./user_files/sop/instances/ft70.1.sop",#39313 (14)
        "./user_files/sop/instances/ft70.2.sop",#[40101,40419]  (15)
        "./user_files/sop/instances/ft70.3.sop",#42535  (16)
        "./user_files/sop/instances/ft70.4.sop",#53530  (17)
        "./user_files/sop/instances/kro124p.1.sop",#[38762,39420]  (18)
        "./user_files/sop/instances/kro124p.2.sop",#[39841,41336]  (19)
        "./user_files/sop/instances/kro124p.3.sop",#[43904,49499]  (20)
        "./user_files/sop/instances/kro124p.4.sop",#[73021,76103]  (21)
        "./user_files/sop/instances/p43.1.sop",#28140  (22)
        "./user_files/sop/instances/p43.2.sop",#28480  (23)
        "./user_files/sop/instances/p43.3.sop",#28835 (24)
        "./user_files/sop/instances/p43.4.sop",#83005  (25)
        "./user_files/sop/instances/prob.42.sop",#243 (26)
        "./user_files/sop/instances/prob.100.sop",#[1045,1163]  (27)
        "./user_files/sop/instances/rbg048a.sop",#351 (28)
        "./user_files/sop/instances/rbg050c.sop",#467 (29)
        "./user_files/sop/instances/rbg109a.sop",#1038 (30)
        "./user_files/sop/instances/rbg150a.sop",#1750 (31)
        "./user_files/sop/instances/rbg174a.sop",#2033 (32)
        "./user_files/sop/instances/rbg253a.sop",#2950 (33)
        "./user_files/sop/instances/rbg323a.sop",#3140 (34)
        "./user_files/sop/instances/rbg341a.sop",#2568 (35)
        "./user_files/sop/instances/rbg358a.sop",#2545 (36)
        "./user_files/sop/instances/rbg378a.sop",#[2809,2816]  (37)
        "./user_files/sop/instances/ry48p.1.sop",#15805 (38)
        "./user_files/sop/instances/ry48p.2.sop",#[16074,16666]  (39)
        "./user_files/sop/instances/ry48p.3.sop",#[19490,19894]  (40)
        "./user_files/sop/instances/ry48p.4.sop"#31446  (41)
    ]
    if getset
        return paths
    else
        return paths[num]
    end
end

"""
    read_sop_file(filepath::String)

Read a properly formatted (SOP according to TSPLIB) .sop file and return a SequencingModel

# Arguments
- `filepath::String`: The location of the sop file
"""
function read_sop_file(filepath::String)
    model = nothing
    open(filepath) do openedfile
        model = parse_sop_input!(read(openedfile, String))
    end
    return model
end

"""
    parse_sop_input!(input_data::String)

Convert the contents of a file, and return a SequencingModel

# Arguments
- `input_data::String`: The contents of file
"""
function parse_sop_input!(input_data::String)
    #split the file into lines and store each line as a node object
    lines = split(input_data, '\n')

    #values
    dimension = 0
    objective_values = Dict{Tuple{Int, Int}, Int}()
    precedence_p2f = Dict{Int, Vector{Int}}()#map of priors to followers
    precedence_f2p = Dict{Int, Vector{Int}}()#map of followers to priors

    #bools for reaing file
    matrix_section_heading = false
    matrix_section = false

    #counter for reading file
    n = 1

    #main loop
    for i in eachindex(lines)
        splitLine = split(lines[i], (' ','\t','\r'))
        filter!(x -> x!="", splitLine)
        if length(splitLine)>=1
            if occursin("EDGE_WEIGHT_SECTION",splitLine[1])
                matrix_section_heading = true
            elseif matrix_section_heading
                matrix_section_heading = false
                matrix_section = true
                dimension = parse(Int,splitLine[1])
            elseif matrix_section && n <= dimension
                for j in eachindex(splitLine)
                    value  = splitLine[j]
                    if length(value)>=1
                        val = parse(Int,value)
                        #if precedence constraint
                        if val == -1 && n!=1 && j!=1
                            if Base.haskey(precedence_p2f,j)
                                push!(precedence_p2f[j],n)
                            else
                                precedence_p2f[j] = [n]
                            end
                            if Base.haskey(precedence_f2p,n)
                                push!(precedence_f2p[n],j)
                            else
                                precedence_f2p[n] = [j]
                            end
                        elseif n != j && val!= -1 #else if it does not point to itself
                            objective_values[(n, j)] = val
                        end
                    end
                end
                n = n+1
            end
        end
    end
    delete!(objective_values, (1, dimension))
    precedence_numbers = get_precedence_numbers(precedence_f2p)
    for i in 2:dimension
        if !Base.haskey(precedence_numbers,i)
            precedence_numbers[i] = 1
        else
            precedence_numbers[i] += 1
        end
    end
    return SOP_Model(
        SparseExtensionalObjective2D(SparseExtensionalFunction2D(objective_values),minimization),
        dimension,
        1,
        dimension,
        precedence_p2f,
        precedence_f2p,
        precedence_numbers
    )
end

"""
    print_sop_solution(best_known_solution::Vector{Int}, best_known_value::T) where T<:Real

Print a SOP solution to the terminal

# Arguments
- `best_known_solution::Vector{Int}`: The solution as an ordered list of nodes
- `best_known_value::T`: The cost of the solution
"""
function print_sop_solution(best_known_solution::Vector{Int}, best_known_value::T) where T<:Real
    println()
    print("Sequence: ",)
    for i in 1:length(best_known_solution)
        print(best_known_solution[i], " ")
    end
    if isinteger(best_known_value)
        println("\nCost: ", Int(best_known_value))
    else
        println("\nCost: ", best_known_value)
    end
end

"""
    write_sop_solution(best_known_solution::Vector{Int}, best_known_value::T, filename::String; time::Union{U,Nothing}=nothing, timeunit::Union{String,Nothing}=nothing) where{T<:Real, U<:Real}

Print a SOP solution to the terminal

# Arguments
- `best_known_solution::Vector{Int}`: The solution as an ordered list of nodes
- `best_known_value::T`: The cost of the solution
- `best_known_bound::T`: The best known relaxed bound
- `filename::String`: The file to write to
- `time::U`: The time elapsed
- `timeunit`: The unit of time being used
"""
function write_sop_solution(best_known_solution::Vector{Int}, best_known_value::T, best_known_bound::T, filename::String; time::Union{U,Nothing}=nothing, timeunit::Union{String,Nothing}=nothing) where{T<:Real, U<:Real}
    f = open(filename,"a")
        write(f, "Seqeunce: ")
        for i in 1:length(best_known_solution)
            write(f,string(best_known_solution[i], " "))
        end
        if isinteger(best_known_value)
            write(f,"\nCost: ", string(Int(best_known_value)))
        else
            write(f,"\nCost: ", string(best_known_value))
        end
        if isinteger(best_known_bound)
            write(f,"\nRelaxed Bound: ", string(Int(best_known_bound)))
        else
            write(f,"\nRelaxed Bound: ", string(best_known_bound))
        end
        write(f,"\n")
        if !isnothing(time)
            write(f, "Time Elapsed: ", string(time), " $timeunit\n")
        end
    close(f)
end

function get_sop_solution(num::Int)
    bks = Int[
        2125,
        2075,
        1675,
        1681,
        1288,
        62,
        18230,
        55,
        55,
        7531,
        8026,
        10262,
        14425,
        39313,
        40419,
        42535,
        53530,
        39420,
        41336,
        49499,
        76103,
        28140,
        28480,
        28835,
        83005,
        243,
        1163,
        351,
        467,
        1038,
        1750,
        2033,
        2950,
        3140,
        2568,
        2545,
        2816,
        15805,
        16666,
        19894,
        31446
    ]

    return bks[num]
end