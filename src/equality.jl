allsame(f::Function, first) = true

function allsame(f::Function, first, second, others...)
    f(first) == f(second) && allsame(f, second, others...)
end

allsame(first, args...) = allsame(identity, first, args...)

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

anyeq(el, iter) = any(a -> a == el, iter)
