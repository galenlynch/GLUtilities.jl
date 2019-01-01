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

"n is the number of elements in the INPUT of pairwise diff"
_pairwise_idx(i, j, n) = i - j + div((j - 1) * (2 * (n - 1) - (j - 2)), 2)

"""
n_el is the number of elements in the INPUT to pairwise diff
"""
function pairwise_idx(i, j, n)
    if i == j
        error("invalid indices")
    elseif i < j
        return _pairwise_idx(j, i, n)
    else
        return _pairwise_idx(i, j, n)
    end
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

"""
    find_closest(a, target, ...)

Find the index of the element in `a` that minimizes the absolute difference from
the target.
"""
function find_closest end

find_closest(arr::AbstractVector, target) = argmin(abs.(arr .- target))

function find_closest(arr::AbstractVector, target, eligible::AbstractVector)
    elig_ndxs = findall(eligible)
    rel_ndx = find_closest(arr[eligible], target)
    elig_ndxs[rel_ndx]
end

function find_closest(f::Function, arr::AbstractVector, target, args...)
    find_closest(map(f, arr), f(target), args...)
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

function mad_quantiles!(out::AbstractVector{T}, a::AbstractVector) where T <: AbstractFloat
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

"""
    skipnothing(itr)
Return an iterator over the elements in `itr` skipping [`nothing`](@ref) values.
Use [`collect`](@ref) to obtain an `Array` containing the non-`nothing` values in
`itr`. Note that even if `itr` is a multidimensional array, the result will always
be a `Vector` since it is not possible to remove nothings while preserving dimensions
of the input.
# Examples
```jldoctest
julia> sum(skipnothing([1, nothing, 2]))
3
julia> collect(skipnothing([1, nothing, 2]))
2-element Array{Int64,1}:
 1
 2
julia> collect(skipnothing([1 nothing; 2 nothing]))
2-element Array{Int64,1}:
 1
 2
```
"""
skipnothing(itr) = SkipNothing(itr)

struct SkipNothing{T}
    x::T
end
IteratorSize(::Type{<:SkipNothing}) = SizeUnknown()
IteratorEltype(::Type{SkipNothing{T}}) where {T} = IteratorEltype(T)
eltype(::Type{SkipNothing{T}}) where {T} = nonnothingtype(eltype(T))

function iterate(itr::SkipNothing, state...)
    y = iterate(itr.x, state...)
    y === nothing && return nothing
    item, state = y
    while item === nothing
        y = iterate(itr.x, state)
        y === nothing && return nothing
        item, state = y
    end
    item, state
end

# Optimized mapreduce implementation
# The generic method is faster when !(eltype(A) >: Nothing) since it does not need
# additional loops to identify the two first non-nothing values of each block
mapreduce(f, op, itr::SkipNothing{<:AbstractArray}) =
    _mapreduce(f, op, IndexStyle(itr.x), eltype(itr.x) >: Nothing ? itr : itr.x)

function _mapreduce(f, op, ::IndexLinear, itr::SkipNothing{<:AbstractArray})
    A = itr.x
    local ai
    inds = LinearIndices(A)
    i = first(inds)
    ilast = last(inds)
    while i <= ilast
        @inbounds ai = A[i]
        ai === nothing || break
        i += 1
    end
    i > ilast && return mapreduce_empty(f, op, eltype(itr))
    a1 = ai
    i += 1
    while i <= ilast
        @inbounds ai = A[i]
        ai === nothing || break
        i += 1
    end
    i > ilast && return mapreduce_first(f, op, a1)
    # We know A contains at least two non-nothing entries: the result cannot be nothing
    mapreduce_impl(f, op, itr, first(inds), last(inds))
end

_mapreduce(f, op, ::IndexCartesian, itr::SkipNothing) = mapfoldl(f, op, itr)

mapreduce_impl(f, op, A::SkipNothing, ifirst::Integer, ilast::Integer) =
    mapreduce_impl(f, op, A, ifirst, ilast, pairwise_blocksize(f, op))

# Returns nothing when the input contains only nothing values
@noinline function mapreduce_impl(f, op, itr::SkipNothing{<:AbstractArray},
                                  ifirst::Integer, ilast::Integer, blksize::Int)
    A = itr.x
    if ifirst == ilast
        @inbounds a1 = A[ifirst]
        if a1 === nothing
            return nothing
        else
            return mapreduce_first(f, op, a1)
        end
    elseif ifirst + blksize > ilast
        # sequential portion
        local ai
        i = ifirst
        while i <= ilast
            @inbounds ai = A[i]
            ai === nothing || break
            i += 1
        end
        i > ilast && return nothing
        a1 = ai::eltype(itr)
        i += 1
        while i <= ilast
            @inbounds ai = A[i]
            ai === nothing || break
            i += 1
        end
        i > ilast && return mapreduce_first(f, op, a1)
        a2 = ai::eltype(itr)
        i += 1
        v = op(f(a1), f(a2))
        @simd for i = i:ilast
            @inbounds ai = A[i]
            if ai !== nothing
                v = op(v, f(ai))
            end
        end
        return v
    else
        # pairwise portion
        imid = (ifirst + ilast) >> 1
        v1 = mapreduce_impl(f, op, itr, ifirst, imid, blksize)
        v2 = mapreduce_impl(f, op, itr, imid+1, ilast, blksize)
        if v1 === nothing && v2 === nothing
            return nothing
        elseif v1 === nothing
            return v2
        elseif v2 === nothing
            return v1
        else
            return op(v1, v2)
        end
    end
end

nonnothingtype(::Type{Union{T, Nothing}}) where {T} = T
nonnothingtype(::Type{Nothing}) = Union{}
nonnothingtype(::Type{T}) where {T} = T
nonnothingtype(::Type{Any}) = Any
