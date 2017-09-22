__precompile__()
module GLUtilities

# package code goes here
export
    add_time_and_micros,
    time_range_to_sec,
    matlab_datevec_to_datetime,
    check_overlap,
    clipind,
    dir_match_files

include("times.jl")
include("ranges.jl")
include("indices.jl")
include("files.jl")

end # module
