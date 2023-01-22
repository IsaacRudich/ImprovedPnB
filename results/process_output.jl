"""
    process_directory(directory_path::String="./output/TSPTW/single_thread/")   

Process a directory of properly formatted output files and return csv data

# Arguments
- `directory_path::String`: The location of the sop files (must end in '/')
"""
function process_directory(directory_path::String="./output/z_temp/")
    filelist = readdir(directory_path)
    for file_name in filelist
        process_output_file(directory_path::String,file_name::String)
    end
end

"""
    process_output_file(file_path::String,file_name::String)

Process a properly formatted output file and return csv data

# Arguments
- `file_path::String`: The location of the sop file
- `file_name::String`: The name of the sop file
"""
function process_output_file(file_path::String,file_name::String)
    converted_data = Vector{String}()
    open(string(file_path,file_name)) do opened_file
        converted_data = convert_data_file!(read(opened_file, String))
    end

    f = open(string("./processed_output/",file_name),"a")
        for line in converted_data
            write(f, string(line,"\n"))
        end
    close(f)
end

"""
    convert_data_file!(input_data::String)

Convert the contents of a file, and return a String[]

# Arguments
- `input_data::String`: The contents of file
"""
function convert_data_file!(input_data::String)
    new_file = Vector{String}()
    #lineformat = lower_bound,upper_bound,optimality_gap,time
    lines = split(input_data, '\n')
    instance_name = 0

    lb = 0
    ub = 0
    gap = 1
    time = 0
    for i in eachindex(lines)
        if occursin("File",lines[i])
            instance_name = split(lines[i], (' '))[3]
            push!(new_file, string(instance_name))
        elseif occursin("Initial Solution",lines[i])
            lb = 0
            ub = split(lines[i+2], (' '))[2]
            time = split(lines[i+3], (' '))[1]
            gap = 1
            push!(new_file, string(lb,",",ub,",",gap,",",time))
        elseif occursin("Data",lines[i])
            instance_name = split(lines[i], (' ',':'))[3]
            split_line = split(lines[i], (' ',','))
            lb = split_line[2]
            ub = split_line[3]
            gap = split_line[4]
            time = split(lines[i+1], (' '))[1]
            push!(new_file, string(lb,",",ub,",",gap,",",time))
        end
    end
    return new_file
end
