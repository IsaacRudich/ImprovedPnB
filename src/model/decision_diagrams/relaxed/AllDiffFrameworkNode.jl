abstract type AllDiffFrameworkNode <: RelaxedFrameworkNode end
#node must be mutable
#required values from parent: id-> UUID,  exact -> Bool
#=additional required values: 
    layer -> Int, state -> Int, 
    lengthtoroot -> <:Real, lengthtoterminal -> <:Real
    allup -> BitVector, alldown -> BitVector, someup -> BitVector, somedown-> BitVector , 
    parents -> Vector{<:Node}, children -> Vector{<:Node}
=#

Base.show(io::IO,node::T) where{T<:AllDiffFrameworkNode} = Base.print(
    io,
    "\n   layer: ", node.layer, ", state: ", node.state, "\n",
    "   allup: ", sum(node.allup), ", alldown: ", sum(node.alldown), "\n",
    "   someup: ", sum(node.someup), ", somedown: ", sum(node.somedown), "\n",
    "   lengthtoroot: ", node.lengthtoroot,", lengthtoterminal: ", node.lengthtoterminal, "\n",
    "   isexact: ", node.exact, ", arcsIn: ", length(node.parents), ", arcsOut: ", length(node.children), "\n",
)
getlayer(node::T) where{T<: AllDiffFrameworkNode}  = node.layer
getstate(node::T) where{T<: AllDiffFrameworkNode}  = node.state
setstate(node::T,num::Int) where{T<: AllDiffFrameworkNode} = node.state = num

getlengthtoroot(node::T) where{T<: AllDiffFrameworkNode}  = node.lengthtoroot
getlengthtoterminal(node::T) where{T<: AllDiffFrameworkNode}  = node.lengthtoterminal
setlengthtoroot(node::T,num::U) where{T<: AllDiffFrameworkNode,U<:Real}  = node.lengthtoroot = num
setlengthtoterminal(node::T,num::U) where{T<: AllDiffFrameworkNode,U<:Real}  = node.lengthtoterminal = num

getallup(node::T) where{T<:AllDiffFrameworkNode}  = node.allup
getalldown(node::T) where{T<:AllDiffFrameworkNode}  = node.alldown
getsomeup(node::T) where{T<:AllDiffFrameworkNode}  = node.someup
getsomedown(node::T) where{T<:AllDiffFrameworkNode}  = node.somedown

getexactness(node::T) where{T<:AllDiffFrameworkNode}  = node.exact
setexactness(node::T,isexact::Bool) where{T<:AllDiffFrameworkNode} = node.exact = isexact

getparents(node::T) where{T<: AllDiffFrameworkNode}  = node.parents
getfirstparent(node::T) where{T<: AllDiffFrameworkNode}  = getparents(node)[1]
getchildren(node::T) where{T<: AllDiffFrameworkNode}  = node.children
getfirstchild(node::T) where{T<: AllDiffFrameworkNode}  = getchildren(node)[1]

function show_out_arc_labels(node::T) where{T<:AllDiffFrameworkNode}
    str = ""
    for child in getchildren(node)
        str = string(str, getstate(child), " ")
    end
    return str
end

function show_in_arc_labels(node::T) where{T<:AllDiffFrameworkNode}
    str = ""
    for parent in getparents(node)
        str = string(str, getstate(parent), " ")
    end
    return str
end

"""
    add_arc(parent::T,child::T)where{T<:AllDiffFrameworkNode, U<:AllDiffFrameworkNode}

Adds an arc from parent to child

# Arguments
- `parent::T`: the parent node
- `child::U`: the child node
"""
function add_arc!(parent::T,child::U )where{T<:AllDiffFrameworkNode, U<:AllDiffFrameworkNode}
    push!(getchildren(parent), child)
    push!(getparents(child), parent)
end

"""
    remove_arcs!(toedit::Vector{T}, toremove::Vector{T})where{T<:AllDiffFrameworkNode}

Remove a list of arcs from a list of arc

# Arguments
- `toedit::Vector{T}`: the list of arcs
- `toremove::Vector{T}`: the list of arcs to remove
"""
function remove_arcs!(toedit::Vector{T}, toremove::Vector{T}) where{T<:AllDiffFrameworkNode}
    filter!(x -> !(x in toremove), toedit)
end

"""
    remove_arc!(toedit::Vector{T}, toremove::T)where{T<:AllDiffFrameworkNode}

Remove an arc from a list

# Arguments
- `toedit::Vector{T}`: the list of arcs
- `toremove::Vector{T}`: the arc to remove
"""
function remove_arc!(toedit::Vector{T}, toremove::T) where{T<:AllDiffFrameworkNode}
    filter!(x->x!=toremove, toedit)
end

"""
    delete_arcs_to_parents!(node::T)where{T<:AllDiffFrameworkNode}

Remove all arcs going to parents from both the node and the parents

# Arguments
- `node::T`: the node to cut off
"""
function delete_arcs_to_parents!(node::T) where{T<:AllDiffFrameworkNode}
    @inbounds @simd for parent in getparents(node)
        @inline remove_arc!(getchildren(parent),node)
    end
    empty!(getparents(node))
end

"""
    delete_arcs_to_children!(node::T)where{T<:AllDiffFrameworkNode}

Remove all arcs going to children from both the node and the children

# Arguments
- `node::T`: the node to cut off
"""
function delete_arcs_to_children!(node::T) where{T<:AllDiffFrameworkNode}
    @inbounds @simd for child in getchildren(node)
        @inline remove_arc!(getparents(child),node)
    end
    empty!(getchildren(node))
end

"""
    update_alldiff_framework_node_down_variables!(node::T, model::U) where{T<:AllDiffFrameworkNode,U<:SequencingModel}

Update alldown, somedown, exactness, and lengthtoroot

# Arguments
- `node::T`: the node to update
- `model::U`: the problem model
"""
function update_alldiff_framework_node_down_variables!(node::T, model::U) where{T<:AllDiffFrameworkNode,U<:SequencingModel}
    getalldown(node) .= false
    getsomedown(node) .= false
    setexactness(node, true)

    getsomedown(node)[getstate(node)] = true
    getalldown(node)[getstate(node)] = true

    setlengthtoroot(node, getlengthtoroot(getfirstparent(node)) + evaluate_decision(model, getstate(getfirstparent(node)),getstate(node)))
    #union domains with parents and check for exactness
    @inbounds for parent in getparents(node)
        broadcast!(|,getsomedown(node),getsomedown(node),getsomedown(parent))
        broadcast!(|,getalldown(node),getalldown(node),getalldown(parent))
        if !getexactness(parent)
            setexactness(node,false)
        end
        if is_better_solution_value(model, getlengthtoroot(parent) + evaluate_decision(model, getstate(parent),getstate(node)), getlengthtoroot(node))
            setlengthtoroot(node, getlengthtoroot(parent) + evaluate_decision(model, getstate(parent),getstate(node)))
        end
    end
    #check each all down to make sure its valid
    @inbounds for i in eachindex(getalldown(node))
        if i != getstate(node) && getalldown(node)[i]
            for p in getparents(node)
                if !getalldown(p)[i]
                    getalldown(node)[i]=false
                    break
                end
            end
        end
    end
    #final check for exactness (first part is just a check to see if the second part should run)
    if getexactness(node) && (getsomedown(node) != getalldown(node) || getlayer(node)!=sum(getalldown(node)))
        setexactness(node,false)
    end
end

"""
    update_alldiff_framework_node_up_variables!(node::T,model::U) where{T<:AllDiffFrameworkNode,U<:SequencingModel}

Update allup, someup, and lengthtoterminal

# Arguments
- `node::T`: the node to update
- `model::U`: the problem model
"""
function update_alldiff_framework_node_up_variables!(node::T,model::U) where{T<:AllDiffFrameworkNode,U<:SequencingModel}
    getallup(node) .= false
    getsomeup(node) .= false

    @inbounds for child in getchildren(node)
        getsomeup(node)[getstate(child)] = true
        getallup(node)[getstate(child)] = true
    end
    
    setlengthtoterminal(node, getlengthtoterminal(getfirstchild(node)) + evaluate_decision(model,getstate(node),getstate(getfirstchild(node))))
    #union domains with children
    @inbounds for child in getchildren(node)
        broadcast!(|,getsomeup(node),getsomeup(node),getsomeup(child))
        broadcast!(|,getallup(node),getallup(node),getallup(child))

        if is_better_solution_value(model,getlengthtoterminal(child) + evaluate_decision(model,getstate(node),getstate(child)), getlengthtoterminal(node))
            setlengthtoterminal(node, getlengthtoterminal(child) + evaluate_decision(model,getstate(node),getstate(child)))
        end
    end

    #check each all up to make sure its valid
    @inbounds for i in eachindex(getallup(node))
        if i != getstate(node) && getallup(node)[i]
            for c in getchildren(node)
                if !getallup(c)[i]
                    getallup(node)[i]=false
                    break
                end
            end
        end
    end
end

"""
    filter_out_arc_alldiff_check(parent::T, child::T, model::P, bestknownvalue::Union{Nothing, U})where{T<:AllDiffFrameworkNode,P<:SequencingModel,U<:Real}
Check if an arc is removable

# Arguments
- `parent::T`: the parent node
- `child::T`: the child node
- `model::P`: the sequencing problem being evaluated
- `bestknownvalue::Union{Nothing, U}`: the best known solution value
"""
function filter_out_arc_alldiff_check(parent::T, child::V, model::P, bestknownvalue::Union{Nothing, U}) where{T<:AllDiffFrameworkNode,V<:AllDiffFrameworkNode,P<:SequencingModel,U<:Real}
    #the label  is used in every path to the root
    @inbounds if getalldown(parent)[getstate(child)]
        return true
    end
    #the label is used in every path to the terminal
    @inbounds if getallup(child)[getstate(child)]
        return true
    end
    #the number of remaining decisions matches the number of remaining labels, and this one is in use
    @inbounds if getsomeup(child)[getstate(child)] && sum(getsomeup(child)) == (length(model)-getlayer(child))
        return true
    end
    #total available paths passing through the arc is less than total number of decisions
    pathsthrough = getsomedown(parent) .| getsomeup(child)
    pathsthrough[getstate(child)] = true
    if sum(pathsthrough) < length(model)
        return true
    end

    #if the best feasible solution is better than the best optimal path through the arc
    @inbounds if !isnothing(bestknownvalue)
        if !is_better_solution_value(model, getlengthtoroot(parent) + getlengthtoterminal(child) + evaluate_decision(model, getstate(parent),getstate(child)), bestknownvalue)
            return true
        end
    end

    return false
end

"""
    find_optimal_path(model::T, dd::Vector{Vector{U}})where{T<:SequencingModel,U<:AllDiffFrameworkNode}
Find the optimal path through a decision diagram
Return optimal_path::Vector{Int}

# Arguments
- `model::P`: the sequencing problem being evaluated
- `dd::Vector{Vector{T}}`: a relaxed decision diagram
"""
function find_optimal_path(model::T, dd::Vector{Vector{U}}) where{T<:SequencingModel,U<:AllDiffFrameworkNode}
    optimal_path = Vector{Int}()
    sizehint!(optimal_path, length(dd))
    current_node = first(last(dd))

    if !has_end(model)
        @inbounds for parent in getparents(current_node)
            if getlengthtoroot(parent) == getlengthtoroot(current_node)
                current_node = parent
                break
            end
        end
    end

    @inbounds while !isempty(getparents(current_node))
        for parent in getparents(current_node)
            if getlengthtoroot(parent)+evaluate_decision(model, getstate(parent),getstate(current_node)) == getlengthtoroot(current_node)
                push!(optimal_path, getstate(current_node))
                current_node = parent
                break
            end
        end
    end

    if has_start(model) || getlayer(first(first(dd)))!=1
        push!(optimal_path,getstate(first(first(dd))))
    end

    reverse!(optimal_path)

    return optimal_path
end

"""
    getfrontiernode(dd::Vector{Vector{T}}, relaxedsolution::Vector{Int})where{T<:AllDiffFrameworkNode}

Get the deepest layer indexed exact node from the best path through the diagram
Return (<:AllDiffFrameworkNode, Int)

# Arguments
- `dd::Vector{Vector{T}}`: The dd to search
- `relaxedsolution::Vector{Int}`: The problem solution
"""
function getfrontiernode(dd::Vector{Vector{T}}, relaxedsolution::Vector{Int})where{T<:AllDiffFrameworkNode}
    currentnode = first(first(dd))
    for i in getlayer(currentnode):length(relaxedsolution)
        for child in getchildren(currentnode)
            if relaxedsolution[i+1] == getstate(child)
                if getexactness(child)
                    currentnode = child
                    break
                else
                    return currentnode, (i - getlayer(first(first(dd))) + 1)
                end
            end
        end
    end
end

"""
    getlastexactnode(dd::Vector{Vector{T}}, relaxedsolution::Vector{Int})where{T<:AllDiffFrameworkNode}

Get the first node from the best path through the diagram that is a parent to a non-exact node

# Arguments
- `dd::Vector{Vector{T}}`: The dd to search
- `relaxedsolution::Vector{Int}`: The problem solution
"""
function getlastexactnode(dd::Vector{Vector{T}}, relaxedsolution::Vector{Int})where{T<:AllDiffFrameworkNode}
    currentnode = first(first(dd))
    for i in getlayer(currentnode):length(relaxedsolution)
        nextnode = nothing
        for child in getchildren(currentnode)
            if relaxedsolution[i+1] == getstate(child)
                if getexactness(child)
                    nextnode = child
                else
                    return currentnode, (i - getlayer(dd[1][1]) + 1)
                end
            elseif !getexactness(child)
                return currentnode, (i - getlayer(dd[1][1]) + 1)
            end
        end
        currentnode = nextnode
    end
end

"""
    getmaximalpeelnode(dd::Vector{Vector{T}}, relaxedsolution::Vector{Int})where{T<:AllDiffFrameworkNode}

Get the second node from the best path through the diagram

# Arguments
- `dd::Vector{Vector{T}}`: The dd to search
- `relaxedsolution::Vector{Int}`: The problem solution
"""
function getmaximalpeelnode(dd::Vector{Vector{T}}, relaxedsolution::Vector{Int})where{T<:AllDiffFrameworkNode}
    currentnode = first(first(dd))
    for child in getchildren(currentnode)
        if relaxedsolution[getlayer(currentnode)+1] == getstate(child)
            return child, 2
        end
    end
end

"""
    getpathtoroot(node::T)where{T<:AllDiffFrameworkNode}

Get a path from the current node to the root
Returns Vector{Int}, T

# Arguments
- `node::T`: the node in question
"""
function getpathtoroot(node::T)where{T<:AllDiffFrameworkNode}
    path = Vector{Int}()
    sizehint!(path, length(getallup(node)))

    while !isempty(getparents(node))
        node = getfirstparent(node)
        push!(path, getstate(node))
    end
    reverse!(path)
    
    return path, node
end

"""
    updatequeue!(queue::Vector{U}, layer::Vector{U},iterationcounter::Int,model::T, heuristic_ordering_packet::Vector{Int}) where{T<:SequencingModel, U<:AllDiffFrameworkNode}

Determines which nodes from the layer should go in the refinement queue, and in which order

# Arguments
- `queue::Vector{U}`: The queue to update
- `layer::Vector{U}`: The nodes to choose from
- `iterationcounter::Int`: The number of times this function has been called on this layer
- `model::T`: The problem model
- `heuristic_ordering_packet::Any`: Pre-calculated heuristic information
"""
function updatequeue!(queue::Vector{U}, layer::Vector{U},iterationcounter::Int,model::T, heuristic_ordering_packet::Vector{Int}) where{T<:SequencingModel, U<:AllDiffFrameworkNode}
    while isempty(queue) && iterationcounter<length(heuristic_ordering_packet)-1
        if isempty(queue)
            iterationcounter += 1
        end
        assignment = heuristic_ordering_packet[iterationcounter+1]
        @inbounds for node in layer
            if getstate(node)!=assignment && getsomedown(node)[assignment] && !getalldown(node)[assignment]
                for parent in getparents(node)
                    if getalldown(parent)[assignment]
                        push!(queue, node)
                        break
                    end
                end
            end
        end
    end
    return iterationcounter
end

"""
    retrieve_relaxed_bound(model::T, dd::Vector{Vector{U}})where{T<:SequencingModel,U<:AllDiffFrameworkNode}

Get the relaxed bound given by a decision diagram

# Arguments
- `model::T`: The problem model
- `dd::Vector{Vector{U}}`: The decision diagram
"""
function retrieve_relaxed_bound(model::T, dd::Vector{Vector{U}})where{T<:SequencingModel,U<:AllDiffFrameworkNode}
    return getlengthtoroot(first(last(dd)))
end

"""
    getdomain(node::U) where{U<:AllDiffFrameworkNode,V<:Real}

Determine if a given value is in the domain 

# Arguments
- `node::U`: The node whose domain is to be retrieved
"""
function getdomain(node::U) where{U<:AllDiffFrameworkNode}
    domain = zeros(length(getallup(node)))
    @inbounds @simd for child in getchildren(node)
        domain[getstate(child)] = true
    end
    return domain
end

"""
    getchildbylabel(node::U, label::Int) where{U<:AllDiffFrameworkNode}

Find the child reached by the arc with the given label 

# Arguments
- `node::U`: The parent node
- `label::Int`: The label of the out arc
"""
function getchildbylabel(node::U, label::Int) where{U<:AllDiffFrameworkNode}
    @inbounds for child in getchildren(node)
        if getstate(child) == label
            return child
        end
    end
end