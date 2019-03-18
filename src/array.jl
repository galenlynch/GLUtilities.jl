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

imap_product(f, as, bs) = imap(
    x -> @inbounds(f(x[1], x[2])),
    Iterators.product(as, bs)
)

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
skipoftype(::Type{T}, itr::A) where {T, A} = SkipOfType{T, A}(itr)
skipoftype(::T, itr) where T = skipoftype(T, itr)

struct SkipOfType{T, A}
    x::A
end

IteratorSize(::Type{<:SkipOfType}) = SizeUnknown()
IteratorEltype(::Type{SkipOfType{T, A}}) where {T, A} = IteratorEltype(A)
eltype(::Type{SkipOfType{T, A}}) where {T, A} = union_poptype(T, eltype(A))

function iterate(itr::SkipOfType{T, <:Any}, state...) where T
    y = iterate(itr.x, state...)
    y === nothing && return nothing
    item, state = y
    while item isa T
        y = iterate(itr.x, state)
        y === nothing && return nothing
        item, state = y
    end
    item, state
end

# Optimized mapreduce implementation
# The generic method is faster when !(eltype(A) >: Nothing) since it does not need
# additional loops to identify the two first non-nothing values of each block
function mapreduce(f, op, itr::SkipOfType{T, <:AbstractArray}) where T
    _mapreduce(f, op, IndexStyle(itr.x), eltype(itr.x) >: T ? itr : itr.x)
end

function _mapreduce(
    f, op, ::IndexLinear, itr::SkipOfType{T, <:AbstractArray}
) where T
    A = itr.x
    local ai
    inds = LinearIndices(A)
    i = first(inds)
    ilast = last(inds)
    while i <= ilast
        @inbounds ai = A[i]
        ai isa T  || break
        i += 1
    end
    i > ilast && return mapreduce_empty(f, op, eltype(itr))
    a1 = ai
    i += 1
    while i <= ilast
        @inbounds ai = A[i]
        ai isa T || break
        i += 1
    end
    i > ilast && return mapreduce_first(f, op, a1)
    # We know A contains at least two non-nothing entries: the result cannot be nothing
    something(mapreduce_impl(f, op, itr, first(inds), last(inds)))
end

_mapreduce(f, op, ::IndexCartesian, itr::SkipOfType) = mapfoldl(f, op, itr)

mapreduce_impl(f, op, A::SkipOfType, ifirst::Integer, ilast::Integer) =
    mapreduce_impl(f, op, A, ifirst, ilast, pairwise_blocksize(f, op))

# Returns nothing when the input contains only nothing values
@noinline function mapreduce_impl(
    f, op, itr::SkipOfType{T, <:AbstractArray}, ifirst::Integer, ilast::Integer,
    blksize::Int
) where T
    A = itr.x
    if ifirst == ilast
        @inbounds a1 = A[ifirst]
        if a1 isa T
            return nothing
        else
            return Some(mapreduce_first(f, op, a1))
        end
    elseif ifirst + blksize > ilast
        # sequential portion
        local ai
        i = ifirst
        while i <= ilast
            @inbounds ai = A[i]
            ai isa T || break
            i += 1
        end
        i > ilast && return nothing
        a1 = ai::eltype(itr)
        i += 1
        while i <= ilast
            @inbounds ai = A[i]
            ai isa T || break
            i += 1
        end
        i > ilast && return Some(mapreduce_first(f, op, a1))
        a2 = ai::eltype(itr)
        i += 1
        v = op(f(a1), f(a2))
        @simd for i = i:ilast
            @inbounds ai = A[i]
            if !(ai isa T)
                v = op(v, f(ai))
            end
        end
        return Some(v)
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
            return Some(op(something(v1), something(v2)))
        end
    end
end

_union_poptype(::Type{T}, ::Type{Union{T,S}}) where {T, S} = S
_union_poptype(::Type{T}, ::Type{T}) where {T} = Union{}

# Necessary for cases like _union_poptype(Union{A,B}, Union{A,C})
union_poptype(::Type{T}, ::Type{S}) where {T, S} = _union_poptype(T, Union{T,S})

skipnothing(itr) = skipoftype(Nothing, itr)

# Does not check input lengths
function _moving_sum!(out, s, nav, nout)
    if nav <= 1
        copyto!(out, 1, s, 1, nout)
    elseif nout > 0
        @inbounds out[1] = 0
        @inbounds @simd for i = 1:nav
            out[1] += s[i]
        end
        @inbounds for i = 2:nout
            # The only thing that changes is the first and last part of the window
            out[i] = out[i - 1] + s[i + nav - 1] - s[i - 1]
        end
    end
    out
end

"""
    moving_sum!(out, s, nav)

Sum `s` in a sliding window of `nav` points, placing the result into `out`.
The length of `out` should be `max(length(s) - nav + 1, 0)` if `nav > 0`, or
`length(s)` otherwise.

Does not zero-pad.
"""
function moving_sum!(out, s, nav)
    nin = length(s)
    nout = length(out)
    if nout != ifelse(nav == 0, nin, max(nin - nav + 1, min(nin, 1)))
        throw(ArgumentError("out is not the right size"))
    end
    _moving_sum!(out, s, min(nav, nin), nout)
end

"""
    moving_sum(s, nav)

Same as [`moving_sum!`](@ref), but returns a new array.
"""
function moving_sum(s::AbstractVector, nav::Integer)
    nin = length(s)
    nout = ifelse(nav == 0, nin, max(nin - nav + 1, min(nin, 1)))
    _moving_sum!(similar(s, nout), s, min(nav, nin), nout)
end

"""
    trailing_zeros_idx(arr)

return last index that is not zero
"""
function trailing_zeros_idx(arr)
    l = length(arr)
    last_idx = l
    while last_idx > 0 && arr[last_idx] == 0
        last_idx -= 1
    end
    last_idx
end

function thresh_cross(
    arr,
    thresh,
    comp = <
)
    l = length(arr)
    idx_cross = Vector{Int}(undef, div(l, 2))
    out_no = 0
    for i in 1:l - 1
        if comp(arr[i], thresh) & (! comp(arr[i + 1], thresh))
            out_no += 1
            idx_cross[out_no] = i + 1
        end
    end
    resize!(idx_cross, out_no)
    idx_cross
end

centered_basis(n_point) = (0:n_point - 1) .- (n_point - 1) / 2

stepsize(r::StepRangeLen) = Float64(r.step)
stepsize(::UnitRange) = 1
stepsize(a::AbstractVector) = a[2] - a[1]

@inline @inbounds function _glhist_push!(cnts, x, first, nbin, m)
    binndx = floor(Int, m * (x - first)) + 1
    inbounds = (binndx > 0) & (binndx <= nbin)
    trunc_ndx = ifelse(inbounds, binndx, 1)
    cnts[trunc_ndx] += inbounds
end

function _glhist!(cnts, xs, first, nbin::Integer, step)
    # Approximating division with multiplication of inverse is 20x faster
    m = 1 / step
    for x in xs
        _glhist_push!(cnts, x, first, nbin, m)
    end
    cnts
end

_glhist!(cnts, xs, r) = _glhist!(cnts, xs, first(r), length(r) - 1, stepsize(r))

"""
    glhist!(cnts, xs, r)

Histogram, left inclusive. Assumes regular bin size.
"""
function glhist!(cnts, xs, r)
    length(cnts) == length(r) - 1 || error("cnts must be length length(r) - 1")
    _glhist!(cnts, xs, r)
end

"""
    glhist([::Type{T} = Int,] xs, r) where T

Like [`glhist!`](@ref).
"""
glhist(::Type{T}, xs, r) where T = _glhist!(zeros(T, length(r) - 1), xs, r)
glhist(xs, r) = glhist(Int, xs, r)

function find_local_extrema(
    sig::AbstractVector,
    start_ndx::Integer = div(length(sig), 2);
    findmax::Bool = true,
    right_on_ties::Bool = true
)
    sigl = length(sig)
    sigl < 2 && return start_ndx
    checkbounds(sig, start_ndx)
    comp = ifelse(findmax, >=, <=)
    bias = ifelse(right_on_ties, 1, -1)

    search_ndx = start_ndx
    @inbounds while true
        notleft = search_ndx == 1 || comp(sig[search_ndx], sig[search_ndx - 1])
        notright = search_ndx == sigl || comp(sig[search_ndx], sig[search_ndx + 1])
        if notleft & notright
            return search_ndx
        else
            search_ndx += ifelse(notleft, 1, ifelse(notright, -1, bias))
        end
    end
end

"""
    filter_no_collisions(as, bs, coll_rad)

Filter elements of `as` to keep elements that are not within `coll_rad` of any
element in `bs`. Assumes both are sorted.
"""
function filter_no_collisions(as, bs, coll_rad)
    out = similar(as)
    outno = 0
    nb = length(bs)
    na = length(as)
    ib = 1
    for (i, a) in enumerate(as)
        # Skip over bs that are too far back to matter
        while ib <= nb && a - bs[ib] > coll_rad
            ib += 1
        end
        if ib > nb
            # No times to avoid, push the rest of as into out
            nremainder = na - i + 1
            copyto!(out, outno + 1, as, i, nremainder)
            outno += nremainder
            break
        end
        # Only keep elements of as that do not collide with bs
        # If the next element of bs does not collide, none of the others will
        if abs(a - bs[ib]) > coll_rad
            outno += 1
            out[outno] = a
        end
    end
    resize!(out, outno)
    out
end

"""
    window_counts(ts, window_dur)

For each event in `ts`, count the number of events in `ts` that are in the
range of `ts[i]` and `ts[i] + window_dur`. Assumes `ts` is sorted, and
that elements of `ts` are unique.
"""
function window_counts(ts, window_dur)
    cnts = similar(ts, Int)
    for (i, t) in enumerate(ts)
        se = searchsortedlast(ts, t + window_dur)
        cnts[i] = se - i + 1
    end
    cnts
end

function window_counts(ts, window_dur, tb, te)
    ib = searchsortedfirst(ts, tb)
    ie = searchsortedlast(ts, te)
    subset = view(ts, ib:ie)
    cnts = window_counts(subset, window_dur)
    cnts, ib
end

"""
    filtermap(p::Function, f::Function, xs)

Filters the input vector, then maps the remaining values. For each element
of `xs` which predicate function `p` returns true for, use mapping function `f`
to transform the result."""
function filtermap(p::Function, f::Function, xs::AbstractVector)
    if isempty(xs)
        return similar(xs, Base.promote_op(f, eltype(xs)))
    end
    @inbounds begin
        m_el1 = f(xs[1])
        out = similar(xs, typeof(m_el1))
        nout = 0
        if p(xs[1])
            nout = 1
            out[1] = m_el1
        end
        for elno in 2:length(xs)
            if p(xs[elno])
                nout += 1
                out[nout] = f(xs[elno])
            end
        end
    end
    resize!(out, nout)
    out
end

"""
    find_not_unique(a::AbstractArray)

Returns the indices of all redundant elements in a. The time a value is
seen, it is not considered redundant
"""
function find_not_unique(a::AbstractArray{T}) where T
    na = length(a)

    # Stores the first seen index, and if the index is a known
    # duplicate
    seen_els = Dict{T, Tuple{Int, Bool}}()
    sizehint!(seen_els, na)
    redundant_ndxs = Vector{Int}(undef, na)
    outno = 0
    for (i, el) in enumerate(a)
        if haskey(seen_els, el)
            (first_ndx, duplicated) = seen_els[el]
            if ! duplicated
                seen_els[el] = (first_ndx, true)
                outno += 1
                redundant_ndxs[outno] = first_ndx
            end
            outno += 1
            redundant_ndxs[outno] = i
        else
            seen_els[el] = (i, false)
        end
    end
    resize!(redundant_ndxs, outno)
    redundant_ndxs
end
