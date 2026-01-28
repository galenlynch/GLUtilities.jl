function cov(as::AbstractVector{<:AbstractVector{T}}) where {T<:Real}
    allsame(length, as) || throw(ArgumentError("Lengths must be the same"))
    na = length(as)
    S = SignalIndices.div_type(T)
    cov = zeros(S, na, na)
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
                    @inbounds cov[i, j] += scratch[i] * scratch[j]
                end
            end
        end
        cov ./= nx - 1
    end
    UpperTriangular(cov)
end

function quantiles_mmap(v, p; kwargs...)
    v_mmap, f = to_mmap(v)
    q = try
        q = quantiles!(v_mmap, p; kwargs...)
    finally
        rm(f)
    end
    q
end

function mad_quantiles!(out::AbstractVector{T}, a::AbstractVector) where {T<:AbstractFloat}
    # Allocation
    na = length(a)
    length(out) == na || throw(ArgumentError("a and out not the same length"))
    p, f = typemmap(Vector{Int32}, (na,), autoclean = false)
    try
        # MAD
        ma = convert(T, median(a))
        out .= abs.(a .- ma)

        # Rank MAD
        sortperm!(p, out)

        # Make quantile
        @inbounds for i = 1:na
            out[p[i]] = i / na
        end
    finally
        rm(f)
    end
    out
end

mad_quantiles(a) = mad_quantiles!(similar(a, Float32), a)

to_ntuple(::Type{T}, args::Tuple) where {T} = map(x -> convert(T, x), args)
to_ntuple(::Type{T}, args...) where {T} = to_ntuple(T, args)

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

function pmap_pairwise(f::Function, as::AbstractVector)
    pairs = SignalIndices.pairwise_idxs(length(as))
    pmap(((x, y),) -> f(as[x], as[y]), pairs)
end
