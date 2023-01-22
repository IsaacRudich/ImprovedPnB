"""
    log_solution(best_known_solution::Vector{Int}, best_known_value::T;firstline::Union{String, Nothing}=nothing,filename::Union{Nothing,String}=nothing) where T<:Real

Print a solution to the terminal

# Arguments
- `best_known_solution::Vector{Int}`: The solution as an ordered list of nodes
- `best_known_value::T`: The cost of the solution
- `firstline::Union{String, Nothing}`:An optional preface to the solution
- `filename::Union{Nothing,String}`: An optional file to write the log statement to
"""
function log_solution(best_known_solution::Vector{Int}, best_known_value::T;firstline::Union{String, Nothing}=nothing,filename::Union{Nothing,String}=nothing) where T<:Real
    if !isnothing(firstline)
        println(firstline)
    end
    print("Sequence: ",)
    for i in 1:length(best_known_solution)
        print(best_known_solution[i], " ")
    end
    if isinteger(best_known_value)
        println("\nCost: ", Int(best_known_value))
    else
        println("\nCost: ", best_known_value)
    end
    if !isnothing(filename)
        f = open(filename,"a")
            if !isnothing(firstline)
                write(f, string(firstline, "\n"))
            end
            write(f, "Sequence: ")
            for i in 1:length(best_known_solution)
                write(f, string(best_known_solution[i], " "))
            end
            if isinteger(best_known_value)
                write(f, string("\nCost: ", Int(best_known_value),"\n"))
            else
                write(f, string("\nCost: ", best_known_value,"\n"))
            end
        close(f)
    end
end

"""
    logoptimalitygap(lower::Union{T,Nothing}, upper::Union{U,Nothing};filename::Union{Nothing,String}=nothing)where{T<:Real,U<:Real}

Print an optimality gap to the terminal

# Arguments
- `lower::Union{T,Nothing}`: The smaller number
- `upper::Union{U,Nothing}`: The larger number
- `filename::Union{Nothing,String}`: An optional file to write the log statement to
"""
function logoptimalitygap(lower::Union{T,Nothing}, upper::Union{U,Nothing};filename::Union{Nothing,String}=nothing)where{T<:Real,U<:Real}
    if !isnothing(lower) && !isnothing(upper)
        println("Bounds: [",lower,",",upper,"]")
        println("Optimality Gap: ",round((upper-lower)/upper,digits=4)*100,"%")
        if !isnothing(filename)
            f = open(filename,"a")
                write(f, string("Bounds: [",lower,",",upper,"]", "\n"))
                write(f, string("Optimality Gap: ",round((upper-lower)/upper,digits=4)*100,"%", "\n"))
                write(f, string("Data: ",lower,",",upper,",",round((upper-lower)/upper,digits=4)*100,"\n"))
            close(f)
        end
    elseif !isnothing(lower)
        println("Bounds: [",lower,",","NA","]")
        if !isnothing(filename)
            f = open(filename,"a")
                write(f, string("Bounds: [",lower,",","NA","]", "\n"))
                write(f, string("Data: ",lower,",",typemax(Int64),",",round((typemax(Int64)-lower)/typemax(Int64),digits=4)*100,"\n"))
            close(f)
        end
    elseif !isnothing(upper)
        println("Bounds: [","NA",",",upper,"]")
        if !isnothing(filename)
            f = open(filename,"a")
                write(f, string("Bounds: [","NA",",",upper,"]", "\n"))
                write(f, string("Data: ",0,",",upper,",",round((upper-0)/upper,digits=4)*100,"\n"))
            close(f)
        end
    end
end


"""
    log_dd_widths(dd::Vector{Vector{RelaxedSequencingNode}})

Print the width of each layer of a dd to the terminal

# Arguments
- `dd::Vector{Vector{RelaxedSequencingNode}}`: The dd
"""
function log_dd_widths(dd::Vector{Vector{T}}) where{T<:Node}
    print("DD Layer Widths: [")
    if !isempty(dd)
        print(length(dd[1]))
        for i in 2:length(dd)
            print(",",length(dd[i]))
        end
    end
    println("]")
end


"""
    logruntime(start_time::U, additional_time_elapsed::V;filename::Union{Nothing,String}=nothing)where{U<:Real, V<:Real}

logs the current runtime

# Arguments
- `start_time::U`: the time the program started (in seconds since the epoch)
- `additional_time_elapsed::V`: additional time used (in seconds)
- `filename::Union{Nothing,String}`: An optional file to write the log statement to
"""
function logruntime(start_time::U, additional_time_elapsed::V;filename::Union{Nothing,String}=nothing)where{U<:Real, V<:Real}
    println(round(time() - start_time + additional_time_elapsed, digits=2), " seconds")
    if !isnothing(filename)
        f = open(filename,"a")
            write(f, string(round(time() - start_time + additional_time_elapsed, digits=2), " seconds", "\n"))
        close(f)
    end
end

"""
    logqueuelength(q_length::Int;filename::Union{Nothing,String}=nothing)

Log the length of the queue

# Arguments
- `q_length::Int`: the queue length
- `filename::Union{Nothing,String}`: An optional file to write the log statement to
"""
function logqueuelength(q_length::Int;filename::Union{Nothing,String}=nothing)
    println("Nodes In Queue: ", q_length)
    if !isnothing(filename)
        f = open(filename,"a")
            write(f, string("Nodes In Queue: ",q_length, "\n"))
        close(f)
    end
end

"""
    logfilename(instance_location::String,filename::Union{Nothing,String}=nothing)

Log an instance name from its location

# Arguments
- `instance_location::String`: the instance location
- `filename::Union{Nothing,String}`: An optional file to write the log statement to
"""
function logfilename(instance_location::String,filename::Union{Nothing,String}=nothing)
    println("File Name: ",last(split(instance_location,"/")))
    if !isnothing(filename)
        f = open(filename,"a")
            write(f, string("File Name: ",last(split(instance_location,"/")), "\n"))
        close(f)
    end
end

"""
    logsetting(text::String, setting::Any; filename::Union{Nothing,String}=nothing)

Log a file name

# Arguments
- `text::String`: the descriptive text
- `setting::Any`: the setting
- `filename::Union{Nothing,String}`: An optional file to write the log statement to
"""
function logsetting(text::String, setting::Any; filename::Union{Nothing,String}=nothing)
    println(text, setting)
    if !isnothing(filename)
        f = open(filename,"a")
            write(f, string(text,setting, "\n"))
        close(f)
    end
end