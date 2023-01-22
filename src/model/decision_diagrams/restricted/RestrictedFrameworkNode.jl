abstract type RestrictedFrameworkNode <: Node end
#=
required values
    id                      ::UUID
    path                    ::Vector{Int}
    value                   ::T
    domain                  ::BitVector
=#

getpath(node::T) where{T<:RestrictedFrameworkNode} = node.path
getvalue(node::T) where{T<:RestrictedFrameworkNode} = node.value
setvalue(node::T, val::Int) where{T<:RestrictedFrameworkNode} = node.value = val
getdomain(node::T) where{T<:RestrictedFrameworkNode} = node.domain
Base.length(node::T) where{T<:RestrictedFrameworkNode} = length(node.path)
function restricted_node_trim_heuristic(node::T, heuristic_packet) where{T<:RestrictedFrameworkNode} return getvalue(node) end
function valuerestrictednode(model::T, node::U) where{T<:ProblemModel, U<:RestrictedFrameworkNode}
    if getobjectivetype(model) == minimization
        return getvalue(node)
    else
        return (-1 * getvalue(node))
    end
end
"""
    getstate(node::T)where{T<:RestrictedFrameworkNode}

Get the last location visited in the path leading to the given node

# Arguments
- `node::T`: The node 
"""
function getstate(node::T)where{T<:RestrictedFrameworkNode}
    return last(getpath(node))
end

"""
    indomain(node::T, i::Int)where{T<:RestrictedFrameworkNode}

Check if a value is in the domain of a node (check if a location has been visited or not)

# Arguments
- `node::T`: The node whose domain is being checked
- `i::Int`: The location/value to check for in the domain
"""
function indomain(node::T, i::Int)where{T<:RestrictedFrameworkNode}
    return getdomain(node)[i]
end

"""
    remove!(node::T, i::Int)where{T<:RestrictedFrameworkNode}

Remove a value from the domain of a node

# Arguments
- `node::T`: the node
- `i::Int`: the value to remove
"""
function remove!(node::T, i::Int)where{T<:RestrictedFrameworkNode}
    getdomain(node)[i] = false
end

"""
    add!(node::T, i::Int)where{T<:RestrictedFrameworkNode}

Add a a value to the domain of a node

# Arguments
- `node::T`: the domain
- `i::Int`: the value to add
"""
function add!(node::T, i::Int)where{T<:RestrictedFrameworkNode}
    getdomain(node)[i] = true
end