function allsame(a::AbstractArray)
    isempty(a) && throw(ArgumentError("input cannot be empty"))
    @inbounds first = a[1]
    for e in a[2:end]
        if e != first
            return false
        end
    end
    true
end
