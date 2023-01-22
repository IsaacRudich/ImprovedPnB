struct SOP_Model{T<:ObjectiveFunction} <: SequencingModel
    #required from parent 
    objective           ::T
    length              ::Int
    #added for SOPs
    sequence_start      ::Union{Nothing,Int}
    sequence_end        ::Union{Nothing,Int}
    precedence_p2f      ::Dict{Int, Vector{Int}}#map of priors to followers
    precedence_f2p      ::Dict{Int, Vector{Int}} #map of followers to priors
    precedence_numbers  ::Dict{Int, Int}#how many things must come before each node
end

mutable struct SOP_Relaxed_Node{T<:Real} <: AllDiffFrameworkNode
    #required from parent
    id                  ::UUID
    layer               ::Int
    state               ::Int 
    lengthtoroot        ::T
    lengthtoterminal    ::T
    allup               ::BitVector
    alldown             ::BitVector
    someup              ::BitVector
    somedown            ::BitVector
    exact               ::Bool
    parents             ::Vector{SOP_Relaxed_Node}
    children            ::Vector{SOP_Relaxed_Node}
    #added for SOPs
end

struct SOP_Restricted_Node{T<:Real} <: RestrictedAllDiffNode
    #required from parent
    id          ::UUID
    path        ::Vector{Int}
    value       ::T
    domain      ::BitVector
    visited     ::BitVector
    #added for SOPs
end

#optional
SOP_Relaxed_Node(layer::Int, state::Int, lengthtoroot::T, lengthtoterminal::T,allup::BitVector, alldown::BitVector, someup::BitVector, somedown::BitVector,exact::Bool, parents::Vector{SOP_Relaxed_Node},children::Vector{SOP_Relaxed_Node}) where{T<:Real} = SOP_Relaxed_Node(getnewnodeid(), layer, state, lengthtoroot, lengthtoterminal, allup, alldown, someup, somedown,exact, parents,children)
#mandatory
SOP_Relaxed_Node() = SOP_Relaxed_Node(0,0,0,0,BitVector(),BitVector(),BitVector(),BitVector(),false,Vector{SOP_Relaxed_Node}(),Vector{SOP_Relaxed_Node}())
#optional
SOP_Restricted_Node(path::Vector{Int}, value::T,domain::BitVector, visited::BitVector) where{T<:Real}= SOP_Restricted_Node(getnewnodeid(), path, value, domain, visited) 
#mandatory
SOP_Restricted_Node() = SOP_Restricted_Node(Vector{Int}(),zero(Int),BitVector(), BitVector())