module GLUtilities

using Base.Iterators: Flatten
using Mmap: Mmap
using Distributions: Distributions, Beta, quantile

using IterTools: imap
using LinearAlgebra: UpperTriangular
import PreciseTimestamps
import SignalIndices
import SortedIntervals
using Statistics: mean
import Statistics: cov

# Implementation
include("files.jl")
include("strings.jl")
include("array.jl")
include("testing.jl")
include("mmap.jl")
include("rand.jl")

# Stable API
include("api.jl")

# Deprecations for moved functions
include("deprecations.jl")

end # module
