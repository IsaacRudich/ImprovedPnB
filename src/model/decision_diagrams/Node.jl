abstract type Node end

#required values: id -> UUID

getid(node::T) where{T<:Node}  = node.id

Base.hash(node::T) where{T<:Node} = hash(getid(node)) 
Base.:(==)(node::T) where{T<:Node} = getid(node)==getid(node)

getnewnodeid() = uuid4()