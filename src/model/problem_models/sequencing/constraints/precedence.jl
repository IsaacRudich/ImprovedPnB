
getp2f(model::T) where {T<:SequencingModel} = model.precedence_p2f
getf2p(model::T) where {T<:SequencingModel} = model.precedence_f2p
getprecedencenumbers(model::T) where {T<:SequencingModel} = model.precedence_numbers

"""
    check_precedence_validity(model::T, seq::Vector{Int})where{T<:SequencingModel}

Check if a solution satisfies all the precedence constraints

# Arguments
- `model::T`: The problem model
- `seq::Vector{Int}`: The sequence to check
"""
function check_precedence_validity(model::T, seq::Vector{Int})where{T<:SequencingModel}
    used = falses(length(seq))
    @inbounds for e in seq
        used[e] = true
        if Base.haskey(getf2p(model),e)
            for val in values(getf2p(model)[e])
                if !used[val]
                    return false
                end
            end
        end
    end
    return true
end

"""
    get_precedence_numbers(precedence_f2p::Dict{T, Vector{T}})where{T<:Int}

Return a list of pre-calculated precedence numbers

# Arguments
- `precedence_f2p::Dict{T, Vector{T}}`: The map of followers to their priors
"""
function get_precedence_numbers(precedence_f2p::Dict{T, Vector{T}})where{T<:Int}
    precedence_nums = Dict{Int, Int}()
    @inbounds for num in keys(precedence_f2p)
        if !Base.haskey(precedence_nums,num)
            get_precedence_number!(num, precedence_f2p,precedence_nums)
        end
    end
    return precedence_nums
end

"""
    get_precedence_number!(check_num::T, precedence_f2p::Dict{T, Vector{T}},precedence_nums::Dict{Int, Int})where{T<:Int}

Return a  precedence number, but also updates the values of any missing numbers it has to find along the way

# Arguments
- `check_num::T`: The number to calculate
- `precedence_f2p::Dict{T, Vector{T}}`: The map of followers to their priors
- `precedence_nums::Dict{Int, Int}`: The list of calculated numbers
"""
function get_precedence_number!(check_num::T, precedence_f2p::Dict{T, Vector{T}},precedence_nums::Dict{Int, Int})where{T<:Int}
    if Base.haskey(precedence_f2p,check_num)
        maxVal = 0
        @inbounds for element in precedence_f2p[check_num]
            if !Base.haskey(precedence_nums,element)
                precedence_nums[element] = get_precedence_number!(element, precedence_f2p,precedence_nums)
            end
            if precedence_nums[element]>maxVal
                maxVal = precedence_nums[element]
            end
        end
        precedence_nums[check_num] = max(maxVal+1,length(precedence_f2p[check_num]))
    else
        precedence_nums[check_num] = 0
    end
end

"""
    imposeprecedence!(domain::BitVector, visited::BitVector, model::T)where{T<:SequencingModel}

Given a domain with the labels that have been previously visted, imposes prcedence constraints on the domain

# Arguments
- `domain::BitVector`: the domain to impose precedence on
- `visited::BitVector`: the labels that have been visited
- `model::T`: the model with precedence constraints
"""
function imposeprecedence!(domain::BitVector, visited::BitVector, model::T)where{T<:SequencingModel}
    #handle precedence constraints
    @inbounds for follower in keys(getf2p(model))
        if domain[follower]
            for prior in getf2p(model)[follower]
                if !visited[prior]
                    domain[follower]=false
                    continue
                end
            end
        end
    end
end

"""
    handle_precedence_post_decision(domain, visited, model, decision)

Given the resulting domain from making a decision, check to see if anything can be added due to satisfied precedence

# Arguments
- `domain::BitVector`: the domain to update
- `visited::BitVector`: the labels that have been visited
- `model::T`: the model with precedence constraints
- `decision::Int`: the decision that was made (the new thing in visited)
"""
function handle_precedence_post_decision!(domain::BitVector, visited::BitVector, model::T, decision::Int)where{T<:SequencingModel}
    #handle precedence constraints
    if Base.haskey(getp2f(model),decision)
        @inbounds for i in getp2f(model)[decision]
            #check each of the relevant precedence constraints
            #if satisfied, put in the domain
            if Base.haskey(getf2p(model),i)
                if check_precedence(visited,getf2p(model)[i])
                    domain[i] = true
                end
            end
        end
    end
end

"""
    check_precedence(visited::BitVector,priors::Vector{Int})

Return true if the precedence constraint is satisfied

# Arguments
- `visited::BitVector`: A list of visited nodes
- `priors::Vector{Int}`: A list of nodes that must have been visited
"""
function check_precedence(visited::BitVector,priors::Vector{Int})
    @inbounds for i in priors
        if !visited[i]
            return false
        end
    end
    return true
end