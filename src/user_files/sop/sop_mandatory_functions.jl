#=
    for Restricted Decision Diagrams
=#
"""
    create_restricted_root_node(model::SOP_Model,node::SOP_Restricted_Node)

Creates and returns restricted root node from a problem model
Returns ::SOP_Restricted_Node

# Arguments
- `model::SOP_Model`: The problem model
- `node::SOP_Restricted_Node: only here to abuse multiple dispatch
"""
function create_restricted_root_node(model::SOP_Model,node::SOP_Restricted_Node)
    visited = initialize_visited(model)
    domain = initialize_domain(model)
    imposestart!(domain, visited, model)
    imposeprecedence!(domain, visited,model)
    if has_start(model)
        return SOP_Restricted_Node(Vector{Int}([getstart(model)]), zero(Int), domain,visited)
    else
        return SOP_Restricted_Node(Vector{Int}(), zero(Int), domain,visited)
    end
end

"""
    makedecision(model::SOP_Model, rootnode::SOP_Restricted_Node, decision::Int)

A method that generates the child node resulting from adding an arc to an existing restricted node
Returns ::SOP_Restricted_Node

# Arguments
- `model::SOP_Model`: The problem model
- `rootnode::SOP_Restricted_Node: The starting node for the decision
- `decision::Int`: The node being visited
"""
function makedecision(model::SOP_Model, rootnode::SOP_Restricted_Node, decision::Int)
    #update path
    newpath = push!(copy(getpath(rootnode)), decision)

    #update visited
    newvisited = copy(getvisited(rootnode))
    newvisited[decision] = true

    #update domain
    newdomain = copy(rootnode.domain)
    newdomain[decision] = false
    handle_precedence_post_decision!(newdomain, newvisited, model, decision)

    #update value
    if length(rootnode) == 0 && !has_start(model)
        return SOP_Restricted_Node(newpath, getvalue(rootnode), newdomain,newvisited)
    else
        return SOP_Restricted_Node(newpath, getvalue(rootnode) + evaluate_decision(model,getstate(rootnode), decision), newdomain,newvisited)
    end
end




#=
    for Relaxed Decision Diagrams
=#
"""
    construct_initial_relaxed_dd(model::SOP_Model)

Create an initial relaxed dd from the model
Returns ::Vector{Vector{SOP_Relaxed_Node}}

# Arguments
- `model::SOP_Model`: The problem model
- `node::SOP_Relaxed_Node: only here to abuse multiple dispatch
"""
function construct_initial_relaxed_dd(model::SOP_Model)
    rootnode, masterdomain = create_relaxed_root_node(model,SOP_Relaxed_Node())

    relaxed_dd = Vector{Vector{SOP_Relaxed_Node}}()
    sizehint!(relaxed_dd, length(model)+1)
    push!(relaxed_dd, [rootnode])

    terminalnode = SOP_Relaxed_Node(
        length(model),#layer::Int
        0,#state::Int 
        0,#lengthtoroot::T
        0,#lengthtoterminal::T
        falses(length(masterdomain)),#allup::BitVector
        falses(length(masterdomain)),#alldown::BitVector
        falses(length(masterdomain)),#someup::BitVector
        falses(length(masterdomain)),#somedown::BitVector
        false,#exact::Bool
        Vector{SOP_Relaxed_Node}(),#parents::Vector{SOP_NODE}
        Vector{SOP_Relaxed_Node}()#children::Vector{SOP_NODE}
    )

    if has_end(model)
        lastlayerloopindex = length(model)-getlayer(rootnode)
        setstate(terminalnode, getend(model))
    else
        lastlayerloopindex = length(model)-getlayer(rootnode)+1
    end

    newnode = SOP_Relaxed_Node()
    @inbounds for layer in 2:lastlayerloopindex
        push!(relaxed_dd,Vector{SOP_Relaxed_Node}())
        sizehint!(relaxed_dd[layer],length(masterdomain))
        #new node starts as a state and length
        for (index, indomain) in enumerate(masterdomain)
            if indomain
                newnode = SOP_Relaxed_Node(
                    layer,#layer::Int
                    index,#state::Int 
                    0,#lengthtoroot::T
                    0,#lengthtoterminal::T
                    falses(length(masterdomain)),#allup::BitVector
                    falses(length(masterdomain)),#alldown::BitVector
                    falses(length(masterdomain)),#someup::BitVector
                    falses(length(masterdomain)),#somedown::BitVector
                    false,#exact::Bool
                    Vector{SOP_Relaxed_Node}(),#parents::Vector{SOP_NODE}
                    Vector{SOP_Relaxed_Node}()#children::Vector{SOP_NODE}
                )
                sizehint!(getchildren(newnode), length(masterdomain))
                sizehint!(getparents(newnode), length(relaxed_dd[layer-1]))
                push!(relaxed_dd[layer],newnode)
            end
        end
        #update domain based on precedence
        @inbounds for (i, indomain) in enumerate(masterdomain)
            if !indomain && (!has_start(model) || i!=getstart(model))
                #add satisfied precedence constraints to the domain
                if layer >= get(getprecedencenumbers(model),i,0)
                    masterdomain[i] = true
                end
            end
        end
    end#layer iteration
    push!(relaxed_dd, [terminalnode])

    #add all arcs except terminal arcs and update down values
    toremove = Vector{SOP_Relaxed_Node}()
    sizehint!(toremove, length(model))
    @inbounds for layer in 1:lastindex(relaxed_dd)-2
        for parent in relaxed_dd[layer]
            if layer != 1
                update_alldiff_framework_node_down_variables!(parent,model)
            end
            for child in relaxed_dd[layer+1]
                if haskey(getobjective(model), getstate(parent), getstate(child)) && !getalldown(parent)[getstate(child)]
                    add_arc!(parent, child)
                end
            end
        end
        empty!(toremove)
        for child in relaxed_dd[layer+1]
            if isempty(getparents(child))
                push!(toremove, child)
            end
        end
        filter!(x->!(x in toremove), relaxed_dd[layer+1])
    end

    #add arcs to terminal
    if has_end(model)
        @inbounds for parent in relaxed_dd[lastindex(relaxed_dd)-1]
            if haskey(getobjective(model), getstate(parent), getend(model))
                add_arc!(parent, terminalnode)
            end
            update_alldiff_framework_node_down_variables!(parent,model)
        end
    else
        @inbounds for parent in relaxed_dd[lastindex(relaxed_dd)-1]
            add_arc!(parent, terminalnode)
            update_alldiff_framework_node_down_variables!(model, parent)
        end
    end
    update_alldiff_framework_node_down_variables!(terminalnode,model)

    #update all the up variables
    @inbounds for layer in Iterators.reverse(1:length(relaxed_dd)-1)
        @simd for node in relaxed_dd[layer]
            update_alldiff_framework_node_up_variables!(node,model)
        end
    end

    return relaxed_dd
end

"""
    splitnode!(node::SOP_Relaxed_Node, maxwidth::Int, model::SOP_Model, iterationcounter::Int, heuristic_ordering_packet::Vector{Int}, toremove::Vector{SOP_Relaxed_Node})
Split a node during relaxation

# Arguments
- `node::SOP_Relaxed_Node`: the node to split
- `maxwidth::Int`: the max width of a layer
- `iterationcounter::Int`: The number of times the update queue function has been called on this layer
- `model::SOP_Model`: the problem being evaluated
- `heuristic_ordering_packet::Vector{Int}`: pre-calculated heuristic information
- `toremove::Vector{SOP_Relaxed_Node}`: pre-allocated for performance, contents dont matter
"""
function splitnode!(node::SOP_Relaxed_Node, maxwidth::Int, model::SOP_Model, iterationcounter::Int, heuristic_ordering_packet::Vector{Int}, toremove::Vector{SOP_Relaxed_Node})
    assignment = heuristic_ordering_packet[iterationcounter+1]

    newnode = SOP_Relaxed_Node(
            getlayer(node), #layer
            getstate(node), #state
            getlengthtoroot(node), #to root
            getlengthtoterminal(node), #to terminal
            copy(getallup(node)), #allup
            BitVector(undef,length(getalldown(node))), #alldown
            copy(getsomeup(node)), #someup
            BitVector(undef,length(getsomedown(node))), #somedown
            getexactness(node), #exact
            Vector{SOP_Relaxed_Node}(), #parents
            Vector{SOP_Relaxed_Node}() #children
    )
    #pre-allocate proper memory
    sizehint!(getparents(newnode),maxwidth)
    sizehint!(getchildren(newnode),maxwidth)

    #add new arcs out
    @inbounds for child in getchildren(node)
        add_arc!(newnode,child)
    end

    #redirect each incoming arc where it should go
    empty!(toremove)
    @inbounds for parent in getparents(node)
        if getalldown(parent)[assignment]
            add_arc!(parent,newnode)
            push!(toremove,parent)
            remove_arc!(getchildren(parent),node)
        end
    end
    remove_arcs!(getparents(node), toremove)
    return newnode
end

"""
    peel_node!(model::SOP_Model, node::SOP_Relaxed_Node, max_width::Int, parents::Vector{SOP_Relaxed_Node},bestknownvalue::Union{T,Nothing},heuristic_trimming_packet,preallocatedfilterlist::Vector{SOP_Relaxed_Node})where{T<:Real}

Peels a node, like splitting a node, but the sorting of arcs is pre-determined
Returns peeled_node::SOP_Relaxed_Node, the new node

# Arguments
- `model::SOP_Model`: The sequencing problem
- `node::SOP_Relaxed_Node`: The node to peel
- `max_width::Int`: the max width alllowed by the diagram
- `parents::Vector{SOP_Relaxed_Node}`: The set of 'in' arcs belonging to the new node
- `bestknownvalue::Union{T,Nothing}`: The value of the best known feasible solution
- `heuristic_trimming_packet`: Optional data to be passed to a trim function
- `preallocatedfilterlist::Vector{SOP_Relaxed_Node}`: pre-allocated for performance
"""
function peel_node!(model::SOP_Model, node::SOP_Relaxed_Node, max_width::Int, parents::Vector{SOP_Relaxed_Node},bestknownvalue::Union{T,Nothing},heuristic_trimming_packet,preallocatedfilterlist::Vector{SOP_Relaxed_Node})where{T<:Real}
    peeled_node = SOP_Relaxed_Node(
        getlayer(node), #layer
        getstate(node), #state
        getlengthtoroot(node), #to root
        getlengthtoterminal(node), #to terminal
        copy(getallup(node)), #allup
        BitVector(undef,length(getalldown(node))), #alldown
        copy(getsomeup(node)), #someup
        BitVector(undef,length(getsomedown(node))), #somedown
        getexactness(node), #exact
        Vector{SOP_Relaxed_Node}(), #parents
        Vector{SOP_Relaxed_Node}() #children
    )

    #pre-allocate proper memory
    sizehint!(getparents(peeled_node),max_width)
    sizehint!(getchildren(peeled_node),max_width)

    #add new arcs out
    @inbounds for child in getchildren(node)
        add_arc!(peeled_node,child)
    end

    #fix the destination of the in arc for the new node
    @inbounds for parent in parents
        add_arc!(parent,peeled_node)
        remove_arc!(getchildren(parent),node)
    end
    #get rid of the extra incoming arcs
    remove_arcs!(getparents(node), parents)

    update_down_variables!(peeled_node,model)
    filteroutarcs!(peeled_node,model,bestknownvalue,heuristic_trimming_packet, preallocatedfilterlist)

    if isempty(getparents(node))
        delete_arcs_to_children!(node)
    elseif isempty(getchildren(node)) && getlayer(node) != length(model)
        delete_arcs_to_parents!(node)
    else
        update_down_variables!(node,model)
        filteroutarcs!(node,model,bestknownvalue,heuristic_trimming_packet, preallocatedfilterlist)
    end

    return peeled_node
end

"""
    update_down_variables!(node::SOP_Relaxed_Node, model::SOP_Model)
Update node variables that only use information from above

# Arguments
- `node::SOP_Relaxed_Node`: the node to update
- `model::SOP_Model`: the problem being evaluated
"""
function update_down_variables!(node::SOP_Relaxed_Node, model::SOP_Model)
    update_alldiff_framework_node_down_variables!(node, model)
end

"""
    update_up_variables!(node::SOP_Relaxed_Node, model::SOP_Model)
Update node variables that only use information from below

# Arguments
- `node::SOP_Relaxed_Node`: the node to update
- `model::SOP_Model`: the problem being evaluated
"""
function update_up_variables!(node::SOP_Relaxed_Node, model::SOP_Model)
    update_alldiff_framework_node_up_variables!(node, model)
end 

"""
    filteroutarcs!(node::SOP_Relaxed_Node,model::SOP_Model,bestknownvalue::Union{Nothing, U},heuristic_packet, tofilter::Vector{SOP_Relaxed_Node})where{U<:Real}
Remove out arcs that cannot contain the optimal solution

# Arguments
- `node::SOP_Relaxed_Node`: the parent node
- `model::SOP_Model`: the sequencing problem being evaluated
- `bestknownvalue::Union{Nothing, U}`: the best known solution value
- `heuristic_packet`: pre-calculated heuristic information
- `tofilter::Vector{SOP_Relaxed_Node}`: pre-allocated for performance, contents dont matter
"""
function filteroutarcs!(node::SOP_Relaxed_Node,model::SOP_Model,bestknownvalue::Union{Nothing, U},heuristic_packet, tofilter::Vector{SOP_Relaxed_Node})where{U<:Real}
    empty!(tofilter)
    for child in getchildren(node)
        if filter_out_arc_check(node, child, model, bestknownvalue, heuristic_packet[1], heuristic_packet[2])
            push!(tofilter, child)
        end
    end
    remove_arcs!(getchildren(node), tofilter)
    @inbounds @simd for child in tofilter
        remove_arc!(getparents(child), node)
    end
end

"""
    check_solution_validity(model::T, solution::Vector{Int})where{T<:SOP_Model}

Check if a solution satisfies all the constraints

# Arguments
- `model::T`: The problem model
- `seq::Vector{Int}`: The sequence to check
"""
function check_solution_validity(model::T, solution::Vector{Int})where{T<:SOP_Model}
    return (check_all_diff_validity(solution) && check_precedence_validity(model, solution))
end


"""
    convert_path_to_restricted_node(model::T,path::Vector{Int})where{T<:SOP_Model}

Get the restricted node created by following a path

# Arguments
- `model::T`: The problem model
- `path::Vector{Int}`: The path to base the node on
"""
function convert_path_to_restricted_node(model::T,path::Vector{Int})where{T<:SOP_Model}
    new_restricted_root = create_restricted_root_node(model, SOP_Restricted_Node())
        
    if has_start(model)
        for i in 2:lastindex(path)
            new_restricted_root = makedecision(model, new_restricted_root, path[i])
        end
    else
        for d in path
            new_restricted_root = makedecision(model, new_restricted_root, d)
        end
    end

    return new_restricted_root
end