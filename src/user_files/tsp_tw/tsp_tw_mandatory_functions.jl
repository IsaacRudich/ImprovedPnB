#=
    for Restricted Decision Diagrams
=#
"""
    create_restricted_root_node(model::TSPTW_Model,node::TSPTW_Restricted_Node)

Creates and returns restricted root node from a problem model
Returns ::TSPTW_Restricted_Node

# Arguments
- `model::TSPTW_Model`: The problem model
- `node::TSPTW_Restricted_Node: only here to abuse multiple dispatch
"""
function create_restricted_root_node(model::TSPTW_Model,node::TSPTW_Restricted_Node)
    visited = initialize_visited(model)
    domain = initialize_domain(model)
    imposestart!(domain, visited, model)
    domain[getend(model)] = false

    @inbounds @simd for i in 2:lastindex(domain)-1
        if !isempty(get_preceders(model)[i])
            domain[i] = false
        end
    end

    return TSPTW_Restricted_Node(Vector{Int}([getstart(model)]), zero(Int), domain,visited,0)
end

"""
    create_restricted_root_node(model::TSPTWM_Model,node::TSPTWM_Restricted_Node)

Creates and returns restricted root node from a problem model
Returns ::TSPTWM_Restricted_Node

# Arguments
- `model::TSPTWM_Model`: The problem model
- `node::TSPTWM_Restricted_Node: only here to abuse multiple dispatch
"""
function create_restricted_root_node(model::TSPTWM_Model,node::TSPTWM_Restricted_Node)
    visited = initialize_visited(model)
    domain = initialize_domain(model)
    imposestart!(domain, visited, model)
    domain[getend(model)] = false

    @inbounds @simd for i in 2:lastindex(domain)-1
        if !isempty(get_preceders(model)[i])
            domain[i] = false
        end
    end

    return TSPTWM_Restricted_Node(Vector{Int}([getstart(model)]), zero(Int), domain,visited)
end

"""
    makedecision(model::TSPTW_Model, rootnode::TSPTW_Restricted_Node, decision::Int)

A method that generates the child node resulting from adding an arc to an existing restricted node
Returns ::TSPTW_Restricted_Node

# Arguments
- `model::TSPTW_Model`: The problem model
- `rootnode::TSPTW_Restricted_Node: The starting node for the decision
- `decision::Int`: The node being visited
"""
function makedecision(model::TSPTW_Model, rootnode::TSPTW_Restricted_Node, decision::Int)
    #update path
    newpath = push!(copy(getpath(rootnode)), decision)

    #update visited
    newvisited = copy(getvisited(rootnode))
    newvisited[decision] = true

    #update value
    newvalue = getvalue(rootnode) + evaluate_decision(model,getstate(rootnode), decision)
    newtime = max(
        get_time(rootnode) + evaluate_decision(model,getstate(rootnode), decision),
        getreleasetimes(model)[decision]
    )

    #check if node is still valid
    for (i, e) in enumerate(newvisited)
        if !e && (newtime+evaluate_decision(model, decision, i) > getdeadlines(model)[i])
            return TSPTW_Restricted_Node(
                newpath, 
                newvalue, 
                falses(length(rootnode.domain)),
                newvisited,
                newtime
            )
        end
    end

    #update domain
    newdomain = copy(rootnode.domain)
    newdomain[decision] = false

    #add based on preceders and followers
    if decision != getend(model)
        to_add = true
        @inbounds for i in get_followers(model)[decision]
            if !newvisited[i] && !newdomain[i]
                to_add = true
                for value in get_preceders(model)[i]
                    if !newvisited[value]
                        to_add = false
                        break
                    end
                end
                if to_add
                    newdomain[i] = true
                end
            end
        end
    end

    #check if end should be made available
    if findfirst(x -> !x, newvisited) == lastindex(newvisited)
        newdomain[lastindex(newvisited)] = true
    end


    #update value
    return TSPTW_Restricted_Node(
        newpath, 
        newvalue, 
        newdomain,
        newvisited,
        newtime
    )
end

"""
    makedecision(model::TSPTWM_Model, rootnode::TSPTWM_Restricted_Node, decision::Int)

A method that generates the child node resulting from adding an arc to an existing restricted node
Returns ::TSPTWM_Restricted_Node

# Arguments
- `model::TSPTWM_Model`: The problem model
- `rootnode::TSPTWM_Restricted_Node: The starting node for the decision
- `decision::Int`: The node being visited
"""
function makedecision(model::TSPTWM_Model, rootnode::TSPTWM_Restricted_Node, decision::Int)
    #update path
    newpath = push!(copy(getpath(rootnode)), decision)

    #update visited
    newvisited = copy(getvisited(rootnode))
    newvisited[decision] = true

    #update value
    newvalue = max(
        getvalue(rootnode) + evaluate_decision(model,getstate(rootnode), decision),
        getreleasetimes(model)[decision]
    )

    #check if node is still valid
    for (i, e) in enumerate(newvisited)
        if !e && (newvalue+evaluate_decision(model, decision, i) > getdeadlines(model)[i])
            #update value
            return TSPTWM_Restricted_Node(
                newpath, 
                newvalue, 
                falses(length(rootnode.domain)),
                newvisited
            )
        end
    end

    #update domain
    newdomain = copy(rootnode.domain)
    newdomain[decision] = false

    if decision != getend(model)
        to_add = true
        @inbounds for i in get_followers(model)[decision]
            if !newvisited[i] && !newdomain[i]
                to_add = true
                for value in get_preceders(model)[i]
                    if !newvisited[value]
                        to_add = false
                        break
                    end
                end
                if to_add
                    newdomain[i] = true
                end
            end
        end
    end

    #check if end should be made available
    if findfirst(x -> !x, newvisited) == lastindex(newvisited)
        newdomain[lastindex(newvisited)] = true
    end

    #update value
    return TSPTWM_Restricted_Node(
        newpath, 
        newvalue, 
        newdomain,
        newvisited
    )
end


#=
    for Relaxed Decision Diagrams
=#

"""
    splitnode!(node::TSPTW_Relaxed_Node, maxwidth::Int, model::TSPTW_Model, iterationcounter::Int, heuristic_ordering_packet::Vector{Int}, toremove::Vector{TSPTW_Relaxed_Node})
Split a node during relaxation

# Arguments
- `node::TSPTW_Relaxed_Node`: the node to split
- `maxwidth::Int`: the max width of a layer
- `iterationcounter::Int`: The number of times the update queue function has been called on this layer
- `model::TSPTW_Model`: the problem being evaluated
- `heuristic_ordering_packet::Vector{Int}`: pre-calculated heuristic information
- `toremove::Vector{TSPTW_Relaxed_Node}`: pre-allocated for performance, contents dont matter
"""
function splitnode!(node::TSPTW_Relaxed_Node, maxwidth::Int, model::TSPTW_Model, iterationcounter::Int, heuristic_ordering_packet::Vector{Int}, toremove::Vector{TSPTW_Relaxed_Node})
    assignment = heuristic_ordering_packet[iterationcounter+1]

    newnode = TSPTW_Relaxed_Node(
            getlayer(node), #layer
            getstate(node), #state
            getlengthtoroot(node), #to root (also ECT)
            getlengthtoterminal(node), #to terminal
            copy(getallup(node)), #allup
            BitVector(undef,length(getalldown(node))), #alldown
            copy(getsomeup(node)), #someup
            BitVector(undef,length(getsomedown(node))), #somedown
            getexactness(node), #exact
            Vector{TSPTW_Relaxed_Node}(), #parents
            Vector{TSPTW_Relaxed_Node}(), #children
            get_ect(node), #ect
            get_lst(node) #lst
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
    splitnode!(node::TSPTWM_Relaxed_Node, maxwidth::Int, model::TSPTWM_Model, iterationcounter::Int, heuristic_ordering_packet::Vector{Int}, toremove::Vector{TSPTWM_Relaxed_Node})
Split a node during relaxation

# Arguments
- `node::TSPTWM_Relaxed_Node`: the node to split
- `maxwidth::Int`: the max width of a layer
- `iterationcounter::Int`: The number of times the update queue function has been called on this layer
- `model::TSPTWM_Model`: the problem being evaluated
- `heuristic_ordering_packet::Vector{Int}`: pre-calculated heuristic information
- `toremove::Vector{TSPTWM_Relaxed_Node}`: pre-allocated for performance, contents dont matter
"""
function splitnode!(node::TSPTWM_Relaxed_Node, maxwidth::Int, model::TSPTWM_Model, iterationcounter::Int, heuristic_ordering_packet::Vector{Int}, toremove::Vector{TSPTWM_Relaxed_Node})
    assignment = heuristic_ordering_packet[iterationcounter+1]

    newnode = TSPTWM_Relaxed_Node(
            getlayer(node), #layer
            getstate(node), #state
            getlengthtoroot(node), #to root (also ECT)
            getlengthtoterminal(node), #to terminal
            copy(getallup(node)), #allup
            BitVector(undef,length(getalldown(node))), #alldown
            copy(getsomeup(node)), #someup
            BitVector(undef,length(getsomedown(node))), #somedown
            getexactness(node), #exact
            Vector{TSPTWM_Relaxed_Node}(), #parents
            Vector{TSPTWM_Relaxed_Node}(), #children
            get_lst(node) #lst
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
    peel_node!(model::TSPTW_Model, node::TSPTW_Relaxed_Node, max_width::Int, parents::Vector{TSPTW_Relaxed_Node},bestknownvalue::Union{T,Nothing},heuristic_trimming_packet,preallocatedfilterlist::Vector{TSPTW_Relaxed_Node})where{T<:Real}

Peels a node, like splitting a node, but the sorting of arcs is pre-determined
Returns peeled_node::TSPTW_Relaxed_Node, the new node

# Arguments
- `model::TSPTW_Model`: The sequencing problem
- `node::TSPTW_Relaxed_Node`: The node to peel
- `max_width::Int`: the max width alllowed by the diagram
- `parents::Vector{TSPTW_Relaxed_Node}`: The set of 'in' arcs belonging to the new node
- `bestknownvalue::Union{T,Nothing}`: The value of the best known feasible solution
- `heuristic_trimming_packet`: Optional data to be passed to a trim function
- `preallocatedfilterlist::Vector{TSPTW_Relaxed_Node}`: pre-allocated for performance
"""
function peel_node!(model::TSPTW_Model, node::TSPTW_Relaxed_Node, max_width::Int, parents::Vector{TSPTW_Relaxed_Node},bestknownvalue::Union{T,Nothing},heuristic_trimming_packet,preallocatedfilterlist::Vector{TSPTW_Relaxed_Node})where{T<:Real}
    peeled_node = TSPTW_Relaxed_Node(
        getlayer(node), #layer
        getstate(node), #state
        getlengthtoroot(node), #to root (also ECT)
        getlengthtoterminal(node), #to terminal
        copy(getallup(node)), #allup
        BitVector(undef,length(getalldown(node))), #alldown
        copy(getsomeup(node)), #someup
        BitVector(undef,length(getsomedown(node))), #somedown
        getexactness(node), #exact
        Vector{TSPTW_Relaxed_Node}(), #parents
        Vector{TSPTW_Relaxed_Node}(), #children
        get_ect(node), #ect
        get_lst(node) #lst
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
    peel_node!(model::TSPTWM_Model, node::TSPTWM_Relaxed_Node, max_width::Int, parents::Vector{TSPTWM_Relaxed_Node},bestknownvalue::Union{T,Nothing},heuristic_trimming_packet,preallocatedfilterlist::Vector{TSPTWM_Relaxed_Node})where{T<:Real}

Peels a node, like splitting a node, but the sorting of arcs is pre-determined
Returns peeled_node::TSPTW_Relaxed_Node, the new node

# Arguments
- `model::TSPTWM_Model`: The sequencing problem
- `node::TSPTWM_Relaxed_Node`: The node to peel
- `max_width::Int`: the max width alllowed by the diagram
- `parents::Vector{TSPTWM_Relaxed_Node}`: The set of 'in' arcs belonging to the new node
- `bestknownvalue::Union{T,Nothing}`: The value of the best known feasible solution
- `heuristic_trimming_packet`: Optional data to be passed to a trim function
- `preallocatedfilterlist::Vector{TSPTWM_Relaxed_Node}`: pre-allocated for performance
"""
function peel_node!(model::TSPTWM_Model, node::TSPTWM_Relaxed_Node, max_width::Int, parents::Vector{TSPTWM_Relaxed_Node},bestknownvalue::Union{T,Nothing},heuristic_trimming_packet,preallocatedfilterlist::Vector{TSPTWM_Relaxed_Node})where{T<:Real}
    peeled_node = TSPTWM_Relaxed_Node(
        getlayer(node), #layer
        getstate(node), #state
        getlengthtoroot(node), #to root (also ECT)
        getlengthtoterminal(node), #to terminal
        copy(getallup(node)), #allup
        BitVector(undef,length(getalldown(node))), #alldown
        copy(getsomeup(node)), #someup
        BitVector(undef,length(getsomedown(node))), #somedown
        getexactness(node), #exact
        Vector{TSPTWM_Relaxed_Node}(), #parents
        Vector{TSPTWM_Relaxed_Node}(), #children
        get_lst(node) #lst
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
    update_down_variables!(node::TSPTW_Relaxed_Node, model::TSPTW_Model)
Update node variables that only use information from above

# Arguments
- `node::TSPTW_Relaxed_Node`: the node to update
- `model::TSPTW_Model`: the problem being evaluated
"""
function update_down_variables!(node::TSPTW_Relaxed_Node, model::TSPTW_Model)
    update_alldiff_framework_node_down_variables!(node, model)

    if !isempty(getparents(node))
        set_ect(node,get_ect(getfirstparent(node))+evaluate_decision(model,getstate(getfirstparent(node)), getstate(node)))
        @inbounds for parent in getparents(node)
            set_ect(
                node,
                min(
                    get_ect(node),
                    get_ect(parent) + evaluate_decision(model,getstate(parent), getstate(node))
                )
            )
        end
        set_ect(
            node,
            max(
                get_ect(node),
                getreleasetimes(model)[getstate(node)]
            )
        )
    end

    #check exactness condition: is best path also fastest path, if not the node is not exact
    if getexactness(node) && get_ect(node)!=getreleasetimes(model)[getstate(node)]
        if length(getparents(node))>1
            matchfound = false

            @inbounds for parent in getparents(node)
                if getlengthtoroot(parent)+evaluate_decision(model, getstate(parent), getstate(node))==getlengthtoroot(node)
                    if get_ect(node) == get_ect(parent) + evaluate_decision(model,getstate(parent), getstate(node))
                        matchfound = true
                        break
                    end
                end
            end

            if !matchfound
                setexactness(node, false)
            end
        end
    end
end

"""
    update_down_variables!(node::TSPTWM_Relaxed_Node, model::TSPTWM_Model)
Update node variables that only use information from above

# Arguments
- `node::TSPTWM_Relaxed_Node`: the node to update
- `model::TSPTWM_Model`: the problem being evaluated
"""
function update_down_variables!(node::TSPTWM_Relaxed_Node, model::TSPTWM_Model)
    update_alldiff_framework_node_down_variables!(node, model)
    setlengthtoroot(node, max(getlengthtoroot(node),getreleasetimes(model)[getstate(node)]))
end

"""
    update_up_variables!(node::T, model::U) where{T<:TSPTWRELAXEDNODE, U<:TSPTWMODEL}
Update node variables that only use information from below

# Arguments
- `node::T`: the node to update
- `model::U`: the problem being evaluated
"""
function update_up_variables!(node::T, model::U) where{T<:TSPTWRELAXEDNODE, U<:TSPTWMODEL}
    set_lst(node,
        get_lst(getfirstchild(node)) - evaluate_decision(model,getstate(node), getstate(getfirstchild(node)))
    )
    @inbounds for child in getchildren(node)
        set_lst(
            node,
            max(
                get_lst(child) - evaluate_decision(model,getstate(node), getstate(child)),
                get_lst(node)
            )
        )
    end
    set_lst(node, min(getdeadlines(model)[getstate(node)],get_lst(node)))

    update_alldiff_framework_node_up_variables!(node, model)
end 

"""
    filteroutarcs!(node::TSPTW_Relaxed_Node,model::TSPTW_Model,bestknownvalue::Union{Nothing, U},heuristic_packet, tofilter::Vector{TSPTW_Relaxed_Node})where{U<:Real}
Remove out arcs that cannot contain the optimal solution

# Arguments
- `node::TSPTW_Relaxed_Node`: the parent node
- `model::TSPTW_Model`: the sequencing problem being evaluated
- `bestknownvalue::Union{Nothing, U}`: the best known solution value
- `heuristic_packet`: pre-calculated heuristic information
- `tofilter::Vector{TSPTW_Relaxed_Node}`: pre-allocated for performance, contents dont matter
"""
function filteroutarcs!(node::TSPTW_Relaxed_Node,model::TSPTW_Model,bestknownvalue::Union{Nothing, U},heuristic_packet, tofilter::Vector{TSPTW_Relaxed_Node})where{U<:Real}
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
    filteroutarcs!(node::TSPTWM_Relaxed_Node,model::TSPTWM_Model,bestknownvalue::Union{Nothing, U},heuristic_packet, tofilter::Vector{TSPTWM_Relaxed_Node})where{U<:Real}
Remove out arcs that cannot contain the optimal solution

# Arguments
- `node::TSPTWM_Relaxed_Node`: the parent node
- `model::TSPTWM_Model`: the sequencing problem being evaluated
- `bestknownvalue::Union{Nothing, U}`: the best known solution value
- `heuristic_packet`: pre-calculated heuristic information
- `tofilter::Vector{TSPTWM_Relaxed_Node}`: pre-allocated for performance, contents dont matter
"""
function filteroutarcs!(node::TSPTWM_Relaxed_Node,model::TSPTWM_Model,bestknownvalue::Union{Nothing, U},heuristic_packet, tofilter::Vector{TSPTWM_Relaxed_Node})where{U<:Real}
    empty!(tofilter)
    for child in getchildren(node)
        if filter_out_arc_check(node, child, model, bestknownvalue, heuristic_packet[1], heuristic_packet[2],heuristic_packet[3],heuristic_packet[4])
            push!(tofilter, child)
        end
    end
    remove_arcs!(getchildren(node), tofilter)
    @inbounds @simd for child in tofilter
        remove_arc!(getparents(child), node)
    end
end

"""
    check_solution_validity(model::T, solution::Vector{Int})where{T<:TSPTWMODEL}

Check if a solution satisfies all the constraints

# Arguments
- `model::T`: The problem model
- `seq::Vector{Int}`: The sequence to check
"""
function check_solution_validity(model::T, solution::Vector{Int})where{T<:TSPTWMODEL}
    return (check_all_diff_validity(solution) && check_timewindow_validity(model, solution))
end

"""
    convert_path_to_restricted_node(model::T,path::Vector{Int})where{T<:TSPTW_Model}

Get the restricted node created by following a path

# Arguments
- `model::T`: The problem model
- `path::Vector{Int}`: The path to base the node on
"""
function convert_path_to_restricted_node(model::T,path::Vector{Int})where{T<:TSPTW_Model}
    new_restricted_root = create_restricted_root_node(model, TSPTW_Restricted_Node())
        
    for i in 2:lastindex(path)
        new_restricted_root = makedecision(model, new_restricted_root, path[i])
    end

    return new_restricted_root
end

"""
    convert_path_to_restricted_node(model::T,path::Vector{Int})where{T<:TSPTWM_Model}

Get the restricted node created by following a path

# Arguments
- `model::T`: The problem model
- `path::Vector{Int}`: The path to base the node on
"""
function convert_path_to_restricted_node(model::T,path::Vector{Int})where{T<:TSPTWM_Model}
    new_restricted_root = create_restricted_root_node(model, TSPTWM_Restricted_Node())
        
    for i in 2:lastindex(path)
        new_restricted_root = makedecision(model, new_restricted_root, path[i])
    end

    return new_restricted_root
end


"""
    construct_initial_relaxed_dd(model::TSPTW_Model)

Create an initial relaxed dd from the model
Returns ::Vector{Vector{TSPTW_Relaxed_Node}}

# Arguments
- `model::TSPTW_Model`: The problem model
"""
function construct_initial_relaxed_dd(model::TSPTW_Model)
    rootnode, masterdomain = create_relaxed_root_node(model,TSPTW_Relaxed_Node())

    relaxed_dd = Vector{Vector{TSPTW_Relaxed_Node}}()
    sizehint!(relaxed_dd, length(model)+1)
    push!(relaxed_dd, [rootnode])

    terminalnode = TSPTW_Relaxed_Node(
        length(model),#layer::Int
        getend(model),#state::Int 
        0.0,#lengthtoroot::T
        0.0,#lengthtoterminal::T
        falses(length(masterdomain)),#allup::BitVector
        falses(length(masterdomain)),#alldown::BitVector
        falses(length(masterdomain)),#someup::BitVector
        falses(length(masterdomain)),#somedown::BitVector
        false,#exact::Bool
        Vector{TSPTW_Relaxed_Node}(),#parents::Vector{TSPTW_NODE}
        Vector{TSPTW_Relaxed_Node}(),#children::Vector{TSPTW_NODE}
        0.0,#ect
        getdeadlines(model)[length(model)]#latest_start_time::Int
    )

    lastlayerloopindex = length(model)-getlayer(rootnode)
    to_add = Vector{Int}()
    newnode = TSPTW_Relaxed_Node()

    @inbounds for layer in 2:lastlayerloopindex
        push!(relaxed_dd,Vector{TSPTW_Relaxed_Node}())
        sizehint!(relaxed_dd[layer],length(masterdomain))
        #new node starts as a state and length
        for (index, indomain) in enumerate(masterdomain)
            if indomain
                newnode = TSPTW_Relaxed_Node(
                    layer,#layer::Int
                    index,#state::Int 
                    0.0,#lengthtoroot::T
                    0.0,#lengthtoterminal::T
                    falses(length(masterdomain)),#allup::BitVector
                    falses(length(masterdomain)),#alldown::BitVector
                    falses(length(masterdomain)),#someup::BitVector
                    falses(length(masterdomain)),#somedown::BitVector
                    false,#exact::Bool
                    Vector{TSPTW_Relaxed_Node}(),#parents::Vector{TSPTW_NODE}
                    Vector{TSPTW_Relaxed_Node}(),#children::Vector{TSPTW_NODE}
                    0.0,
                    0.0
                )
                sizehint!(getchildren(newnode), length(masterdomain))
                sizehint!(getparents(newnode), length(relaxed_dd[layer-1]))
                push!(relaxed_dd[layer],newnode)
            end
        end
        #update domain based on precedence
        empty(to_add)
        should_add = true
        @inbounds for (i, indomain) in enumerate(masterdomain)
            if !indomain && i!=getstart(model) && i!=getend(model)
                #add satisfied precedence constraints to the domain
                should_add = true
                
                @inbounds for p in get_preceders(model)[i]
                    if !masterdomain[p]
                        should_add = false
                        break
                    end
                end
                if should_add
                    push!(to_add,i)
                end
            end
        end
        @inbounds @simd for e in to_add
            masterdomain[e] = true
        end
    end#layer iteration
    push!(relaxed_dd, [terminalnode])

    #add all arcs except terminal arcs and update down values
    toremove = Vector{TSPTW_Relaxed_Node}()
    sizehint!(toremove, length(model))
    @inbounds for layer in 1:lastindex(relaxed_dd)-2
        for parent in relaxed_dd[layer]
            if layer != 1
                update_down_variables!(parent,model)
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
    @inbounds for parent in relaxed_dd[lastindex(relaxed_dd)-1]
        if haskey(getobjective(model), getstate(parent), getend(model))
            add_arc!(parent, terminalnode)
        end
        update_down_variables!(parent,model)
    end
    update_down_variables!(terminalnode,model)

    #update all the up variables
    @inbounds for layer in Iterators.reverse(1:length(relaxed_dd)-1)
        @simd for node in relaxed_dd[layer]
            update_up_variables!(node,model)
        end
    end

    #arc filtering
    tofilter = Vector{TSPTW_Relaxed_Node}()
    arc_removed = true
    @inbounds while arc_removed
        arc_removed = false
        
        for layer in relaxed_dd
            for node in layer
                empty!(tofilter)
                for child in getchildren(node)
                    if filter_out_arc_timewindow_check(node,child,model)
                        #println("Node: ", get_ect(node), " ", get_lst(node)," Child :",get_ect(child), " ", get_lst(child)," States :", getstate(node), " ", getstate(child), " Evaluation: ", evaluate_decision(model, getstate(node), getstate(child)))
                        arc_removed = true
                        push!(tofilter, child)
                    end
                end
                remove_arcs!(getchildren(node), tofilter)
                @inbounds @simd for child in tofilter
                    remove_arc!(getparents(child), node)
                end
            end
        end

        if arc_removed
            nodesremoved = true
            while nodesremoved
                nodesremoved = false
                for (i,layer) in enumerate(relaxed_dd)
                    if i!=1
                        #remove nodes with empty parents
                        @inbounds for node in layer
                            if isempty(getparents(node))
                                nodesremoved = true
                                delete_arcs_to_children!(node)
                            end
                        end
                        filter!(x->!isempty(getparents(x)), layer)
                    end
                    if i!= lastindex(relaxed_dd)
                        #remove nodes with empty children
                        @inbounds for node in layer
                            if isempty(getchildren(node))
                                nodesremoved = true
                                delete_arcs_to_parents!(node)
                            end
                        end
                        filter!(x->!isempty(getchildren(x)), layer)
                    end
                end
            end
            #update all the down variables
            @inbounds for layer in 2:lastindex(relaxed_dd)
                @simd for node in relaxed_dd[layer]
                    update_down_variables!(node,model)
                end
            end
            #update all the up variables
            @inbounds for layer in Iterators.reverse(1:length(relaxed_dd)-1)
                @simd for node in relaxed_dd[layer]
                    update_up_variables!(node,model)
                end
            end
        end
    end

    return relaxed_dd
end













"""
    construct_initial_relaxed_dd(model::TSPTWM_Model)

Create an initial relaxed dd from the model
Returns ::Vector{Vector{TSPTWM_Relaxed_Node}}

# Arguments
- `model::TSPTWM_Model`: The problem model
"""
function construct_initial_relaxed_dd(model::TSPTWM_Model)
    rootnode, masterdomain = create_relaxed_root_node(model,TSPTWM_Relaxed_Node())

    relaxed_dd = Vector{Vector{TSPTWM_Relaxed_Node}}()
    sizehint!(relaxed_dd, length(model)+1)
    push!(relaxed_dd, [rootnode])

    terminalnode = TSPTWM_Relaxed_Node(
        length(model),#layer::Int
        getend(model),#state::Int 
        0.0,#lengthtoroot::T
        0.0,#lengthtoterminal::T
        falses(length(masterdomain)),#allup::BitVector
        falses(length(masterdomain)),#alldown::BitVector
        falses(length(masterdomain)),#someup::BitVector
        falses(length(masterdomain)),#somedown::BitVector
        false,#exact::Bool
        Vector{TSPTWM_Relaxed_Node}(),#parents::Vector{TSPTWMM_NODE}
        Vector{TSPTWM_Relaxed_Node}(),#children::Vector{TSPTW_NODE}
        getdeadlines(model)[length(model)]#latest_start_time::Int
    )

    lastlayerloopindex = length(model)-getlayer(rootnode)
    to_add = Vector{Int}()
    newnode = TSPTWM_Relaxed_Node()

    @inbounds for layer in 2:lastlayerloopindex
        push!(relaxed_dd,Vector{TSPTWM_Relaxed_Node}())
        sizehint!(relaxed_dd[layer],length(masterdomain))
        #new node starts as a state and length
        for (index, indomain) in enumerate(masterdomain)
            if indomain
                newnode = TSPTWM_Relaxed_Node(
                    layer,#layer::Int
                    index,#state::Int 
                    0.0,#lengthtoroot::T
                    0.0,#lengthtoterminal::T
                    falses(length(masterdomain)),#allup::BitVector
                    falses(length(masterdomain)),#alldown::BitVector
                    falses(length(masterdomain)),#someup::BitVector
                    falses(length(masterdomain)),#somedown::BitVector
                    false,#exact::Bool
                    Vector{TSPTWM_Relaxed_Node}(),#parents::Vector{TSPTW_NODE}
                    Vector{TSPTWM_Relaxed_Node}(),#children::Vector{TSPTW_NODE}
                    0
                )
                sizehint!(getchildren(newnode), length(masterdomain))
                sizehint!(getparents(newnode), length(relaxed_dd[layer-1]))
                push!(relaxed_dd[layer],newnode)
            end
        end
        #update domain based on precedence
        empty(to_add)
        should_add = true
        @inbounds for (i, indomain) in enumerate(masterdomain)
            if !indomain && i!=getstart(model) && i!=getend(model)
                #add satisfied precedence constraints to the domain
                should_add = true
                
                @inbounds for p in get_preceders(model)[i]
                    if !masterdomain[p]
                        should_add = false
                        break
                    end
                end
                if should_add
                    push!(to_add,i)
                end
            end
        end
        @inbounds @simd for e in to_add
            masterdomain[e] = true
        end
    end#layer iteration
    push!(relaxed_dd, [terminalnode])

    #add all arcs except terminal arcs and update down values
    toremove = Vector{TSPTWM_Relaxed_Node}()
    sizehint!(toremove, length(model))
    @inbounds for layer in 1:lastindex(relaxed_dd)-2
        for parent in relaxed_dd[layer]
            if layer != 1
                update_down_variables!(parent,model)
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
    @inbounds for parent in relaxed_dd[lastindex(relaxed_dd)-1]
        if haskey(getobjective(model), getstate(parent), getend(model))
            add_arc!(parent, terminalnode)
        end
        update_down_variables!(parent,model)
    end
    update_down_variables!(terminalnode,model)

    #update all the up variables
    @inbounds for layer in Iterators.reverse(1:length(relaxed_dd)-1)
        @simd for node in relaxed_dd[layer]
            update_up_variables!(node,model)
        end
    end

    #arc filtering
    tofilter = Vector{TSPTWM_Relaxed_Node}()
    arc_removed = true
    @inbounds while arc_removed
        arc_removed = false
        
        for layer in relaxed_dd
            for node in layer
                empty!(tofilter)
                for child in getchildren(node)
                    if filter_out_arc_timewindow_check(node,child,model)
                        #println("Node: ", get_ect(node), " ", get_lst(node)," Child :",get_ect(child), " ", get_lst(child)," States :", getstate(node), " ", getstate(child), " Evaluation: ", evaluate_decision(model, getstate(node), getstate(child)))
                        arc_removed = true
                        push!(tofilter, child)
                    end
                end
                remove_arcs!(getchildren(node), tofilter)
                @inbounds @simd for child in tofilter
                    remove_arc!(getparents(child), node)
                end
            end
        end

        if arc_removed
            nodesremoved = true
            while nodesremoved
                nodesremoved = false
                for (i,layer) in enumerate(relaxed_dd)
                    if i!=1
                        #remove nodes with empty parents
                        @inbounds for node in layer
                            if isempty(getparents(node))
                                nodesremoved = true
                                delete_arcs_to_children!(node)
                            end
                        end
                        filter!(x->!isempty(getparents(x)), layer)
                    end
                    if i!= lastindex(relaxed_dd)
                        #remove nodes with empty children
                        @inbounds for node in layer
                            if isempty(getchildren(node))
                                nodesremoved = true
                                delete_arcs_to_parents!(node)
                            end
                        end
                        filter!(x->!isempty(getchildren(x)), layer)
                    end
                end
            end
            #update all the down variables
            @inbounds for layer in 2:lastindex(relaxed_dd)
                @simd for node in relaxed_dd[layer]
                    update_down_variables!(node,model)
                end
            end
            #update all the up variables
            @inbounds for layer in Iterators.reverse(1:length(relaxed_dd)-1)
                @simd for node in relaxed_dd[layer]
                    update_up_variables!(node,model)
                end
            end
        end
    end

    return relaxed_dd
end

"""
    find_optimal_path(model::TSPTWM_Model, dd::Vector{Vector{TSPTWM_Relaxed_Node}})
Find the optimal path through a decision diagram
Return optimal_path::Vector{Int}

# Arguments
- `model::TSPTWM_Model`: the sequencing problem being evaluated
- `dd::Vector{Vector{TSPTWM_Relaxed_Node}}`: a relaxed decision diagram
"""
function find_optimal_path(model::TSPTWM_Model, dd::Vector{Vector{TSPTWM_Relaxed_Node}})
    optimal_path = Vector{Int}()
    sizehint!(optimal_path, length(dd))
    current_node = first(last(dd))

    @inbounds while !isempty(getparents(current_node))
        for parent in getparents(current_node)
            if max(getlengthtoroot(parent)+evaluate_decision(model, getstate(parent),getstate(current_node)),getreleasetimes(model)[getstate(current_node)]) == getlengthtoroot(current_node)
                push!(optimal_path, getstate(current_node))
                current_node = parent
                break
            end
        end
    end

    push!(optimal_path,getstate(first(first(dd))))

    reverse!(optimal_path)

    return optimal_path
end