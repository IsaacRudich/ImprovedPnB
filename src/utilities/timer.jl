"""
    is_timed_out(timelimit::Union{T,Nothing},start_time::U, additional_time_elapsed::V)where{T<:Real, U<:Real, V<:Real}

Check if a timer has been exceeded, always true if timelimit is nothing

# Arguments
- `timelimit::Union{T,Nothing}`: the time limit in seconds (or nothing)
- `start_time::U`: the time the program started (in seconds since the epoch)
- `additional_time_elapsed::V`: additional time used (in seconds)
"""
function is_timed_out(timelimit::Union{T,Nothing},start_time::U, additional_time_elapsed::V)where{T<:Real, U<:Real, V<:Real}
    if isnothing(timelimit)
        return false
    end
    if (time() - start_time + additional_time_elapsed) >= timelimit
        return true
    else
        return false
    end
end