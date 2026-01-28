module GLUtilities

using Base.Iterators: Flatten
import Base: isless, convert, show, -, +, ==
using Dates:
    AbstractDateTime,
    DateTime,
    DateFormat,
    Nanosecond,
    Microsecond,
    Millisecond,
    TimePeriod,
    @dateformat_str
using LinearAlgebra: UpperTriangular
using Mmap: Mmap
using Printf: Printf, @sprintf
using Distributions: Distributions, Beta, quantile

using IterTools: imap
import SignalIndices
import SortedIntervals
using Statistics: mean, median
import Statistics: cov
using TimeZones: TimeZones, localzone, Local
import TimeZones: ZonedDateTime

# Implementation
include("times.jl")
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

# Deprecations for moved functions
include("deprecations.jl")

end # module
