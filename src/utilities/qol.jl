function is_a_divisible_by_b(a::S, b::T;digits::Int=8) where {S,T<:Real}
    return ((a%b<=(1/(10^digits))) || (b-(a%b)<=(1/(10^digits))))
end

function rounded_mod(a,b)
    return is_a_divisible_by_b(a,b) ? 0 : round(a%b,digits = 8)
end

function round_to_epsilon(a::T;digits::Int=8) where {T<:Real}
    round(a,digits)
end

stop(text="Stopped by Stop Command") = throw(StopException(text))

struct StopException{T}
    S::T
end

function Base.showerror(io::IO, ex::StopException, bt; backtrace=true)
    Base.with_output_color(get(io, :color, false) ? :green : :nothing, io) do io
        showerror(io, ex.S)
    end
end

function bitvector_to_vector(bv::BitVector)
    v = Vector{Int}()
    sizehint!(v, sum(bv))

    @inbounds for (i,e) in enumerate(bv)
        if e
            push!(v,i)
        end
    end

    return v
end