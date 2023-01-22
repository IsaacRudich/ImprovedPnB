getreleasetimes(model::T) where {T<:SequencingModel} = model.release_times
getdeadlines(model::T) where {T<:SequencingModel} = model.deadlines

"""
    check_timewindow_validity(model::T, seq::Vector{Int})where{T<:SequencingModel}

Check if a solution satisfies all the timewindow constraints

# Arguments
- `model::T`: The problem model
- `seq::Vector{Int}`: The sequence to check
"""
function check_timewindow_validity(model::T, seq::Vector{Int})where{T<:SequencingModel}
    time = 0
    @inbounds for i in 1:lastindex(seq)-1
        #println(seq[i], " ", time," ",getreleasetimes(model)[seq[i]], " ", getdeadlines(model)[seq[i]])
        if time > getdeadlines(model)[seq[i]]
            return false
        end
        time += evaluate_decision(model,seq[i], seq[i+1])
        time = max(time, getreleasetimes(model)[seq[i+1]])
    end

    #println(last(seq), " ", time," ",getreleasetimes(model)[last(seq)], " ", getdeadlines(model)[last(seq)])
    if time > getdeadlines(model)[last(seq)]
        return false
    end
    
    return true
end