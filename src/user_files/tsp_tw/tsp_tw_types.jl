#Two versions, one for makespan, one for time traveled

#= 
    The Model
=#
abstract type TSPTWMODEL<:SequencingModel end

struct TSPTW_Model{T<:ObjectiveFunction} <: TSPTWMODEL
    #required from parent 
    objective           ::T
    length              ::Int
    #added for TSPTWs
    sequence_start      ::Int
    sequence_end        ::Int
    release_times       ::Dict{Int, Int}
    deadlines           ::Dict{Int, Int}
    implied_preceders   ::Dict{Int, Vector{Int}}
    implied_followers   ::Dict{Int, Vector{Int}}
end

struct TSPTWM_Model{T<:ObjectiveFunction} <: TSPTWMODEL
    #required from parent 
    objective           ::T
    length              ::Int
    #added for TSPTWs
    sequence_start      ::Int
    sequence_end        ::Int
    release_times       ::Dict{Int, Int}
    deadlines           ::Dict{Int, Int}
    implied_preceders   ::Dict{Int, Vector{Int}}
    implied_followers   ::Dict{Int, Vector{Int}}
end

TSPTW_Model(model::TSPTWM_Model) = TSPTW_Model(model.objective, model.length, model.sequence_start, model.sequence_end, model.release_times, model.deadlines, model.implied_preceders, model.implied_followers)

get_preceders(model::T) where{T<:TSPTWMODEL} = model.implied_preceders
get_followers(model::T) where{T<:TSPTWMODEL} = model.implied_followers

#= 
    The Relaxed Nodes
=#
abstract type TSPTWRELAXEDNODE<:AllDiffFrameworkNode end

mutable struct TSPTW_Relaxed_Node <: TSPTWRELAXEDNODE
    #required from parent
    id                  ::UUID
    layer               ::Int
    state               ::Int 
    lengthtoroot        ::Float64
    lengthtoterminal    ::Float64
    allup               ::BitVector
    alldown             ::BitVector
    someup              ::BitVector
    somedown            ::BitVector
    exact               ::Bool
    parents             ::Vector{TSPTW_Relaxed_Node}
    children            ::Vector{TSPTW_Relaxed_Node}
    #added for TSPTWs
    earliest_completion_time    ::Float64
    latest_start_time           ::Float64
end

mutable struct TSPTWM_Relaxed_Node <: TSPTWRELAXEDNODE
    #required from parent
    id                  ::UUID
    layer               ::Int
    state               ::Int 
    lengthtoroot        ::Float64
    lengthtoterminal    ::Float64
    allup               ::BitVector
    alldown             ::BitVector
    someup              ::BitVector
    somedown            ::BitVector
    exact               ::Bool
    parents             ::Vector{TSPTWM_Relaxed_Node}
    children            ::Vector{TSPTWM_Relaxed_Node}
    #added for TSPTWs
    latest_start_time   ::Float64
end

get_ect(node::T) where{T<:TSPTW_Relaxed_Node} = node.earliest_completion_time
set_ect(node::T, value::U) where{T<:TSPTW_Relaxed_Node,U<:Real} = node.earliest_completion_time = value
get_lst(node::T) where{T<:TSPTWRELAXEDNODE} = node.latest_start_time
set_lst(node::T, value::U) where{T<:TSPTWRELAXEDNODE,U<:Real} = node.latest_start_time = value

#= 
    The Restricted Nodes
=#
abstract type TSPTWRESTRICTEDNODE<:RestrictedAllDiffNode end

struct TSPTW_Restricted_Node{T<:Real} <: TSPTWRESTRICTEDNODE
    #required from parent
    id          ::UUID
    path        ::Vector{Int}
    value       ::T
    domain      ::BitVector
    visited     ::BitVector
    #added for TSPTWs
    time        ::T
end

struct TSPTWM_Restricted_Node{T<:Real} <: TSPTWRESTRICTEDNODE
    #required from parent
    id          ::UUID
    path        ::Vector{Int}
    value       ::T
    domain      ::BitVector
    visited     ::BitVector
    #added for TSPTWs
end

get_time(node::T) where{T<:TSPTW_Restricted_Node} = node.time

#= 
   Constructors
=#
#optional
TSPTW_Relaxed_Node(layer::Int, state::Int, lengthtoroot::T, lengthtoterminal::U,allup::BitVector, alldown::BitVector, someup::BitVector, somedown::BitVector,exact::Bool, parents::Vector{TSPTW_Relaxed_Node},children::Vector{TSPTW_Relaxed_Node}, earliest_completion_time::V, latest_start_time::W) where{T<:Real, U<:Real,V<:Real,W<:Real} = TSPTW_Relaxed_Node(getnewnodeid(), layer, state, float(lengthtoroot), float(lengthtoterminal), allup, alldown, someup, somedown,exact, parents,children,float(earliest_completion_time),float(latest_start_time))
TSPTWM_Relaxed_Node(layer::Int, state::Int, lengthtoroot::T, lengthtoterminal::U,allup::BitVector, alldown::BitVector, someup::BitVector, somedown::BitVector,exact::Bool, parents::Vector{TSPTWM_Relaxed_Node},children::Vector{TSPTWM_Relaxed_Node}, latest_start_time::V) where{T<:Real, U<:Real, V<:Real} = TSPTWM_Relaxed_Node(getnewnodeid(), layer, state, float(lengthtoroot), float(lengthtoterminal), allup, alldown, someup, somedown,exact, parents,children,float(latest_start_time))
#mandatory
TSPTW_Relaxed_Node() = TSPTW_Relaxed_Node(0,0,0.0,0.0,BitVector(),BitVector(),BitVector(),BitVector(),false,Vector{TSPTW_Relaxed_Node}(),Vector{TSPTW_Relaxed_Node}(),0.0,0.0)
TSPTWM_Relaxed_Node() = TSPTWM_Relaxed_Node(0,0,0.0,0.0,BitVector(),BitVector(),BitVector(),BitVector(),false,Vector{TSPTWM_Relaxed_Node}(),Vector{TSPTWM_Relaxed_Node}(),0.0)
#optional
TSPTW_Restricted_Node(path::Vector{Int}, value::T,domain::BitVector, visited::BitVector,time::T) where{T<:Real}= TSPTW_Restricted_Node(getnewnodeid(), path, value, domain, visited,time) 
TSPTWM_Restricted_Node(path::Vector{Int}, value::T,domain::BitVector, visited::BitVector) where{T<:Real}= TSPTWM_Restricted_Node(getnewnodeid(), path, value, domain, visited) 
#mandatory
TSPTW_Restricted_Node() = TSPTW_Restricted_Node(Vector{Int}(),zero(Int),BitVector(), BitVector(),zero(Int))
TSPTWM_Restricted_Node() = TSPTWM_Restricted_Node(Vector{Int}(),zero(Int),BitVector(), BitVector())
