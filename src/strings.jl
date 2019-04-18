"""
    only_matches(reg::Regex, strs::AbstractArray{<:AbstractString})

Return all matches of `reg` in `strs`, skipping over non-matches.
"""
function only_matches(reg::Regex, strs::AbstractArray{<:AbstractString})
    n_s = length(strs)
    matches = Vector{RegexMatch}(undef, n_s)
    out_no = 0
    for str in strs
        maybe_match = match(reg, str)
        if maybe_match != nothing
            out_no += 1
            matches[out_no] = maybe_match
        end
    end
    resize!(matches, out_no)
    matches
end
