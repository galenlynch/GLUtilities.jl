allsame(f::Function, first) = true

function allsame(f::Function, first, second, others...)
    return f(first) == f(second) && allsame(f, second, others...)
end

allsame(first, args...) = allsame(identity, first, args...)

function allsame(a::AbstractArray)
    isempty(a) && return true
    @inbounds first = a[1]
    for e in a[2:end]
        if !isequal(e, first)
            return false
        end
    end
    return true
end

anyeq(el, iter) = any(a -> a == el, iter)

absdiff(a::Unsigned, b::Unsigned) = ifelse(a <= b, b - a, a - b)
absdiff(a::Signed, b::Signed) = abs(a - b)
