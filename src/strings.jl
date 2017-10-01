function only_matches(reg::Regex, strs::A) where {T<:AbstractString, A<:AbstractArray{T}}
    matches = Vector{RegexMatch}()
    for str in strs
        maybe_match = match(reg, str)
        if maybe_match != nothing
            push!(matches, maybe_match)
        end
    end
    return matches
end
