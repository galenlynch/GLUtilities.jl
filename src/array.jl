function flatten_nested_map(funcs::Tuple, nested)
    if length(funcs) == 1
        collect(Flatten(imap(first(funcs), nested)))
    else
        flatten_nested_map(Base.tail(funcs), collect(Flatten(imap(first(funcs), nested))))
    end
end

function nested_map(f, arrs::AbstractArray{<:AbstractArray})
    map(arr -> map(f, arr), arrs)
end

function cov(as::AbstractVector{<:AbstractVector{T}}) where {T<:Real}
    allsame(length, as) || throw(ArgumentError("Lengths must be the same"))
    na = length(as)
    S = div_type(T)
    covmat = zeros(S, na, na)
    if na > 0
        means = Vector{S}(undef, na)
        scratch = Vector{S}(undef, na)
        @inbounds for (i, a) in enumerate(as)
            means[i] = mean(a)
        end

        nx = length(as[1])
        for xno = 1:nx
            @simd for arrno = 1:na
                @inbounds scratch[arrno] = as[arrno][xno] - means[arrno]
            end
            for i = 1:na
                @simd for j = i:na
                    @inbounds covmat[i, j] += scratch[i] * scratch[j]
                end
            end
        end
        covmat ./= nx - 1
    end
    UpperTriangular(covmat)
end
