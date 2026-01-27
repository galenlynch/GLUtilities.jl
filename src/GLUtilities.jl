module GLUtilities

using Distributions

using Base: @propagate_inbounds

using IterTools: imap

using TimeZones

using TimeZones: Local

using SharedArrays: SharedVector

using Printf

using Dates: AbstractDateTime, DateTime, DateFormat, Nanosecond, Microsecond, Millisecond, TimePeriod, @dateformat_str

using LinearAlgebra: UpperTriangular

using Mmap: Mmap

import TimeZones: ZonedDateTime

import Base:
    isless,
    convert,
    show,
    in,
    eltype,
    mapreduce,
    _mapreduce,
    mapreduce_empty,
    mapreduce_first,
    pairwise_blocksize,
    iterate,
    IteratorSize,
    IteratorEltype,
    SizeUnknown,
    -,
    +,
    ==

import Statistics: cov

# Implementation
include("types.jl")
include("times.jl")
include("interval.jl")
include("indices.jl")
include("files.jl")
include("strings.jl")
include("equality.jl")
include("postgres.jl")
include("array.jl")
include("testing.jl")
include("mmap.jl")
include("matlab.jl")
include("rand.jl")

# Stable API
include("api.jl")

end # module
