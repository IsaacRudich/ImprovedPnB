"""
    search_relaxed_dd(model::T, relaxed_dd::Vector{Vector{U}},path_to_root::Vector{Int},maxwidth::Int,relaxed_node_data_type::Union{DataType,UnionAll};bestknownsolution::Union{Vector{Int},Nothing}=nothing,bestknownvalue::Union{V,Nothing}=nothing, heuristic_packet=nothing,debug_on::Bool=false)where{T<:ProblemModel,U<:RelaxedFrameworkNode,V<:Real}

Constructs a restricted decision diagram that respects a given relaxed diagrma
Returns: bestknownsolution::Vector{Int}, bestknownvalue::Real, exact::Bool
'exact' is true if the dd is exact 

# Arguments
- `model::T`: The problem
- `relaxed_dd::Vector{Vector{U}}`: the realxed dd to respect
- `path_to_root::Vector{Int}`: the path to the root node
- `maxwidth::Int`: The max width allowed in a decision diagram layer
- `restricted_node_data_type::Union{DataType,UnionAll}`: The data type to use when creating new restricted nodes
- `relaxed_node_data_type::Union{DataType,UnionAll}`: The data type to use when creating new relaxed nodes
# Optional Arrguments
- `bestknownsolution::Union{Vector{Int},Nothing}`: An optional parameter that gives the DD a starting solution
- `bestknownvalue::Union{V,Nothing}`: An optional parameter that gives the DD a starting bound
- `heuristic_packet`: Data to be passed to the heuristic function
- `debug_on::Bool`: An optional parameter that can be used to turn on debug statements in other functions
"""
function search_relaxed_dd(model::T, relaxed_dd::Vector{Vector{U}},path_to_root::Vector{Int},maxwidth::Int, restricted_node_data_type::Union{DataType,UnionAll},relaxed_node_data_type::Union{DataType,UnionAll};bestknownsolution::Union{Vector{Int},Nothing}=nothing,bestknownvalue::Union{V,Nothing}=nothing, heuristic_packet=nothing,debug_on::Bool=false)where{T<:ProblemModel,U<:RelaxedFrameworkNode,V<:Real}
    
    rootnode = convert_path_to_restricted_node(model,path_to_root)
    restricted_to_relaxed = Dict{restricted_node_data_type, relaxed_node_data_type}()
    restricted_to_relaxed[rootnode] = first(first(relaxed_dd))
    relaxed_to_domain = Dict{relaxed_node_data_type, BitVector}()
    relaxed_to_domain[restricted_to_relaxed[rootnode]] = getdomain(restricted_to_relaxed[rootnode])
    sizehint!(relaxed_to_domain, length(model)*maxwidth)
    sizehint!(restricted_to_relaxed, length(model)*maxwidth)

    #initialize values
    pathlength = length(rootnode)
    queue = Vector{restricted_node_data_type}([rootnode])
    sizehint!(queue, maxwidth + length(getdomain(rootnode)))
    newlayer = Vector{restricted_node_data_type}()
    newnode = restricted_node_data_type()
    sizehint!(newlayer, maxwidth + length(getdomain(rootnode)))
    exact = true

    #iterate down through the layers
    @inbounds for layerindex in 1:length(model)-pathlength
        #initialize array for new layer
        empty!(newlayer)
        #for each node in the queue
        for node in queue
            #for each unvisited location of the node
            for i in 1:length(model)
                #if i is in the domain add the new node
                if indomain(node, i) && relaxed_to_domain[restricted_to_relaxed[node]][i]
                    #generate the next node
                    newnode = makedecision(model, node, i)
                        
                    #check for empty domain
                    if i<length(model)-pathlength && isnothing(findfirst(x -> x,getdomain(newnode)))
                        continue
                    end

                    #apply any heuristic methods
                    if !isnothing(bestknownvalue) && layerindex<length(model)-pathlength-2
                        if !is_better_solution_value(model, restricted_node_trim_heuristic(newnode, heuristic_packet), bestknownvalue)
                            continue
                        end
                    end

                    #if worth adding, add it
                    if isnothing(bestknownvalue) || getobjectivetype(model)==maximization
                        addtosortedlayer!(model, newlayer, newnode)

                        restricted_to_relaxed[newnode] = getchildbylabel(restricted_to_relaxed[node], i)
                        if !Base.haskey(relaxed_to_domain,restricted_to_relaxed[newnode])
                            relaxed_to_domain[restricted_to_relaxed[newnode]] = getdomain(restricted_to_relaxed[newnode])
                        end
                    elseif is_better_solution_value(model, getvalue(newnode), bestknownvalue)
                        addtosortedlayer!(model, newlayer, newnode)

                        restricted_to_relaxed[newnode] = getchildbylabel(restricted_to_relaxed[node], i)
                        if !Base.haskey(relaxed_to_domain,restricted_to_relaxed[newnode])
                            relaxed_to_domain[restricted_to_relaxed[newnode]] = getdomain(restricted_to_relaxed[newnode])
                        end
                    end
                end
            end#end domain loop
            #trim the layyer if it is too big
            if length(newlayer)>maxwidth
                if exact
                    exact = false
                end
                newlayer = newlayer[1:maxwidth]
            end
        end#node in queue loop
        #trim queue
        if length(newlayer)>maxwidth
            if exact
                exact = false
            end
            queue = newlayer[1:maxwidth]
        elseif isempty(newlayer)
            return bestknownsolution, bestknownvalue, exact
        else
            queue = newlayer[1:length(newlayer)]
        end
    end#iterate over layers loop

    #update result
    if isnothing(bestknownvalue) || is_better_solution_value(model, getvalue(queue[1]), bestknownvalue)
        bestknownsolution = getpath(queue[1])
        bestknownvalue = getvalue(queue[1])
    end

    return bestknownsolution, bestknownvalue, exact
end

"""
    variety_search_relaxed_dd(model::T, relaxed_dd::Vector{Vector{U}},path_to_root::Vector{Int},maxwidth::Int,relaxed_node_data_type::Union{DataType,UnionAll}; widthofsearch::Int=5, bestknownsolution::Union{Vector{Int},Nothing}=nothing,bestknownvalue::Union{V,Nothing}=nothing, heuristic_packet=nothing,debug_on::Bool=false)where{T<:ProblemModel,U<:RelaxedFrameworkNode,V<:Real}

Constructs a restricted decision diagram that respects a given relaxed diagrma
Returns: bestknownsolution::Vector{Int}, bestknownvalue::Real, exact::Bool
'exact' is true if the dd is exact 

# Arguments
- `model::T`: The problem
- `relaxed_dd::Vector{Vector{U}}`: the realxed dd to respect
- `path_to_root::Vector{Int}`: the path to the root node
- `maxwidth::Int`: The max width allowed in a decision diagram layer
- `restricted_node_data_type::Union{DataType,UnionAll}`: The data type to use when creating new restricted nodes
- `relaxed_node_data_type::Union{DataType,UnionAll}`: The data type to use when creating new relaxed nodes
# Optional Arrguments
- `widthofsearch::Int`: width of the variety search
- `bestknownsolution::Union{Vector{Int},Nothing}`: An optional parameter that gives the DD a starting solution
- `bestknownvalue::Union{V,Nothing}`: An optional parameter that gives the DD a starting bound
- `heuristic_packet`: Data to be passed to the heuristic function
- `debug_on::Bool`: An optional parameter that can be used to turn on debug statements in other functions
"""
function variety_search_relaxed_dd(model::T, relaxed_dd::Vector{Vector{U}},path_to_root::Vector{Int},maxwidth::Int, restricted_node_data_type::Union{DataType,UnionAll},relaxed_node_data_type::Union{DataType,UnionAll}; widthofsearch::Int=100, bestknownsolution::Union{Vector{Int},Nothing}=nothing,bestknownvalue::Union{V,Nothing}=nothing, heuristic_packet=nothing,debug_on::Bool=false)where{T<:ProblemModel,U<:RelaxedFrameworkNode,V<:Real}

    rootnode = convert_path_to_restricted_node(model,path_to_root)
    relaxed_to_domain = Dict{relaxed_node_data_type, BitVector}()
    relaxed_to_domain[first(first(relaxed_dd))] = getdomain(first(first(relaxed_dd)))
    sizehint!(relaxed_to_domain, length(model)*maxwidth)

    #initialize values
    pathlength = length(rootnode)
    queue = Dict{relaxed_node_data_type, Vector{restricted_node_data_type}}(first(first(relaxed_dd)) => [rootnode])
    sizehint!(queue, maxwidth + length(getdomain(rootnode)))
    newlayer = Dict{relaxed_node_data_type, Vector{restricted_node_data_type}}()
    newnode = restricted_node_data_type()
    sizehint!(newlayer, maxwidth + length(getdomain(rootnode)))

    #iterate down through the layers
    @inbounds for layerindex in 1:length(model)-pathlength
        #initialize array for new layer
        empty!(newlayer)
        #for each node in the queue
        for (relaxed_node, nodes) in queue
            for node in nodes
                #for each unvisited location of the node
                for i in 1:length(model)
                    #if i is in the domain add the new node
                    if indomain(node, i) && relaxed_to_domain[relaxed_node][i]
                        #generate the next node
                        newnode = makedecision(model, node, i)
                            
                        #check for empty domain
                        if i<length(model)-pathlength && isnothing(findfirst(x -> x,getdomain(newnode)))
                            continue
                        end

                        #apply any heuristic methods
                        if !isnothing(bestknownvalue) && layerindex<length(model)-pathlength-2
                            if !is_better_solution_value(model, restricted_node_trim_heuristic(newnode, heuristic_packet), bestknownvalue)
                                continue
                            end
                        end

                        #if worth adding, add it
                        if isnothing(bestknownvalue) || getobjectivetype(model)==maximization
                            relaxed_child = getchildbylabel(relaxed_node, i)
                            if !Base.haskey(relaxed_to_domain,relaxed_child)
                                relaxed_to_domain[relaxed_child] = getdomain(relaxed_child)
                                newlayer[relaxed_child] = Vector{restricted_node_data_type}() 
                            end
                            addtosortedlayer!(model, newlayer[relaxed_child], newnode)
                        elseif is_better_solution_value(model, getvalue(newnode), bestknownvalue)
                            relaxed_child = getchildbylabel(relaxed_node, i)
                            if !Base.haskey(relaxed_to_domain,relaxed_child)
                                relaxed_to_domain[relaxed_child] = getdomain(relaxed_child)
                                newlayer[relaxed_child] = Vector{restricted_node_data_type}() 
                            end
                            addtosortedlayer!(model, newlayer[relaxed_child], newnode)
                        end
                    end
                end#end domain loop
            end
        end#node in queue loop
        @inbounds for (rn, ns) in newlayer
            if length(ns)>widthofsearch
                newlayer[rn] = ns[1:widthofsearch]
            end
        end
        if isempty(newlayer)
            return bestknownsolution, bestknownvalue
        else
            queue = newlayer
            newlayer = nothing
            newlayer = Dict{relaxed_node_data_type, Vector{restricted_node_data_type}}()
            sizehint!(newlayer, maxwidth + length(getdomain(rootnode)))
        end
    end#iterate over layers loop

    queue = collect(values(queue))[1]

    #update result
    if isnothing(bestknownvalue) || is_better_solution_value(model, getvalue(queue[1]), bestknownvalue)
        bestknownsolution = getpath(queue[1])
        bestknownvalue = getvalue(queue[1])
    end

    return bestknownsolution, bestknownvalue
end