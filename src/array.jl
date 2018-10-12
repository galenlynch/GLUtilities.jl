function weighted_mean_dim(
    summand::AbstractArray{E, N},
    weights::AbstractVector{T},
    dim::Integer = N,
    total_weight::T = sum(weights)
) where {E<:Number, N, T<:Number}
    F = promote_type(E, T)

    dims = collect(size(summand))
    dims[dim] = 1

    slice_idx = collect(make_slice_idx(N, dim, 1))
    reduced = zeros(F, (dims...,))
    for i in 1:size(summand, dim)
        slice_idx[dim] = i
        reduced .+= summand[slice_idx...] .* weights[i]
    end
    reduced .= reduced ./ total_weight
    return reduced
end

function weighted_mean(
    summand::AbstractArray{E, N},
    weights::AbstractArray{T, N},
    total_weight::T = sum(weights)
) where {E<:Number, N, T<:Number}
    if size(summand) != size(weights)
        throw(ArgumentError("Sizes are not the same"))
    end
    F = promote_type(E, T)
    reduced = zero(F)
    for i in eachindex(summand)
        reduced += summand[i] * weights[i]
    end
    return reduced / total_weight
end

function weighted_mean(
    summand::AbstractArray{E,N},
    weights::AbstractArray{T,N},
    total_weight::T = sum(weights)
) where {G<:Number, E<:AbstractArray{G, <:Any}, N, T<:Number}
    # assumes elements of summand have the same size
    if size(summand) != size(weights)
        throw(ArgumentError("Sizes are not the same"))
    end
    if isempty(summand)
        throw(ArgumentError("summand is empty"))
    end
    F = promote_type(G, T)
    reduced = zeros(F, size(summand[1]))
    for i in eachindex(summand)
        reduced += summand[i] * weights[i]
    end
    return reduced / total_weight
end

function local_extrema(s::AbstractVector, comp::Function = >)
    ns = length(s)
    @compat idxes = Vector{Int}(undef, div(ns, 2))
    out_i = 0
    if ns > 2
        @inbounds last_comp = comp(s[1], s[2])
        for i in 2:(ns - 1)
            @inbounds this_comp = comp(s[i], s[i + 1])
            if this_comp && ! last_comp
                out_i += 1
                @inbounds idxes[out_i] = i
            end
            last_comp = this_comp
        end
    end
    resize!(idxes, out_i)
    idxes
end

function cov(as::AbstractVector{<:AbstractVector{T}}) where T<:Real
    allsame(length, as) || throw(ArgumentError("Lengths must be the same"))
    na = length(as)
    S = div_type(T)
    cov = zeros(S, na, na)
    if na > 0
        @compat means = Vector{S}(undef, na)
        @compat scratch = Vector{S}(undef, na)
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

rev_view(a::AbstractVector) = @view a[end:-1:1]

"""
    pairwise_idxs(n::Integer) -> Vector{NTuple{2, Int}}

Returns the possible combinations of `1:n` indices excluding self-pairs.
The first index is always greater than the second, allowing for easy
subtraction of ordered lists.

# Examples
```julia-repl
julia> pairwise_idxs(3)
3-element Array{Tuple{Int64,Int64},1}:
 (2, 1)
 (3, 1)
 (3, 2)
```
"""
function pairwise_idxs(n::Integer)
    idxs = Vector{NTuple{2, Int}}(undef, convert(Int, n * (n - 1) / 2))
    offset = 0
    @inbounds for i = 1:(n - 1)
        @simd for j = 1:(n - i)
            idxs[offset + j] = (i + j, i)
        end
        offset += n - i
    end
    idxs
end

function map_pairwise(
    f::Function, a::AbstractVector{T}, ::Type{R} = T
) where {T, R}
    n = length(a)
    out = Vector{R}(undef, convert(Int, n * (n - 1) / 2))
    offset = 0
    for i = 1:(n-1)
        @inbounds @simd for j = 1:(n - i)
            out[offset + j] = f(a[i + j], a[i])
        end
        offset += n - i
    end
    out
end

function map_pairwise(
    f::Function, as::AbstractVector{T}, bs::AbstractVector, ::Type{R} = T
) where {T, R}
    na = length(as)
    nb = length(bs)
    out = Matrix{R}(undef, nb, na)
    @inbounds @simd for i = 1:na
        for j = 1:nb
            out[j, i] = f(as[i], bs[j])
        end
    end
    out
end

function pmap_pairwise(f::Function, as::AbstractVector)
    pairs = pairwise_idxs(length(as))
    pmap(((x, y),) -> f(as[x], as[y]), pairs)
end

function find_subseq(subseq, seq)
    nsub = length(subseq)
    nsub > 0 || throw(ArgumentError("subseq cannot be empty"))
    p = isequal(subseq[1])
    if nsub == 1
        return findall(p, seq)
    end
    nseq = length(seq)
    nsub > nseq && return Vector{Int}()
    max_idx = nseq - nsub + 1
    @compat imatch = Vector{Int}(undef, max_idx)
    nmatch = 0
    idx = 1
    while (idx = findnext(p, seq, idx)) != nothing
        idx > max_idx && break
        ismatch = true
        @inbounds for i = 2:nsub
            if seq[idx + i - 1] != subseq[i]
                ismatch = false
                break
            end
        end
        if ismatch
            nmatch += 1
            imatch[nmatch] = idx
        end
        idx += 1
    end
    resize!(imatch, nmatch)
    imatch
end

function subselect(
    base_vec,
    idx_tup_vec::AbstractVector{<:NTuple{2, <:Any}},
    outtype::Type{T} = ifelse(
        base_vec isa AbstractVector, typeof(base_vec), Vector{eltype(base_vec)}
    )
) where {T<:AbstractVector}
    nout = length(idx_tup_vec)
    out = Vector{T}(undef, nout)
    for i = 1:nout
        ib, ie = idx_tup_vec[i]
        out[i] = convert(outtype, view(base_vec, ib:ie))
    end
    out
end

function subselect(
    base_vec,
    idx_tup_vec::AbstractVector{<:NTuple{2, <:Any}},
    outtype::Type{T}
) where T<:SharedVector
    nout = length(idx_tup_vec)
    out = Vector{T}(undef, nout)
    for i = 1:nout
        ib, ie = idx_tup_vec[i]
        out[i] = outtype(base_vec[ib:ie])
    end
    out
end

function simple_summary_stats(a::AbstractArray)
    m = mean(a)
    s = std(a)
    sem = s / sqrt(length(a))
    m, s, sem
end
