"""
    construct_restricted_dd(model::T, maxwidth::Int, restricted_node_data_type::Union{DataType,UnionAll};rootnode::Union{U,Nothing}=nothing,bestknownsolution::Union{Vector{Int},Nothing}=nothing,bestknownvalue::Union{V,Nothing}=nothing, heuristic_packet=nothing,debug_on::Bool=false)where{T<:ProblemModel,U<:RestrictedFrameworkNode,V<:Real}

Constructs a restricted decision diagram
Returns: bestknownsolution::Vector{Int}, bestknownvalue::Real, exact::Bool
'exact' is true if the dd is exact 

# Arguments
- `model::T`: The problem
- `maxwidth::Int`: The max width allowed in a decision diagram layer
- `restricted_node_data_type::Union{DataType,UnionAll}`: The data type to use when creating new nodes
# Optional Arrguments
- `rootnode::Union{U,Nothing}`: The starting node for the DD
- `bestknownsolution::Union{Vector{Int},Nothing}`: An optional parameter that gives the DD a starting solution
- `bestknownvalue::Union{V,Nothing}`: An optional parameter that gives the DD a starting bound
- `heuristic_packet`: Data to be passed to the heuristic function
- `debug_on::Bool`: An optional parameter that can be used to turn on debug statements in other functions
"""
function construct_restricted_dd(model::T, maxwidth::Int, restricted_node_data_type::Union{DataType,UnionAll};rootnode::Union{U,Nothing}=nothing,bestknownsolution::Union{Vector{Int},Nothing}=nothing,bestknownvalue::Union{V,Nothing}=nothing, heuristic_packet=nothing,debug_on::Bool=false)where{T<:ProblemModel,U<:RestrictedFrameworkNode,V<:Real}
    if isnothing(rootnode) #if no starting point is given construct the root from the problem model
        rootnode = create_restricted_root_node(model, restricted_node_data_type())
    end

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
                if indomain(node, i)
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
                    elseif is_better_solution_value(model, getvalue(newnode), bestknownvalue)
                        addtosortedlayer!(model, newlayer, newnode)
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
    addtosortedlayer!(model::T, layer::Vector{U}, newnode::U)where{T<:ProblemModel,U<:RestrictedFrameworkNode}

A method that generates the child node resulting from adding an arc to an existing node

# Arguments
- `model::T`: The Sequencing problem
- `layer::Vector{U}`: The list to add to
- `newNode::U`: the node to insert
"""
function addtosortedlayer!(model::T, layer::Vector{U}, newnode::U)where{T<:ProblemModel,U<:RestrictedFrameworkNode}
    if isempty(layer)
        push!(layer, newnode)
    else
        insert!(
            layer,
            searchsorted(layer, newnode, by = x -> valuerestrictednode(model, x)).start,
            newnode
        )
    end
end