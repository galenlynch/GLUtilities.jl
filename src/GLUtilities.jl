__precompile__()
module GLUtilities

# package code goes here
export
    add_time_and_micros,
    time_range_to_sec,
    matlab_datevec_to_datetime,
    check_overlap,
    clipind,
    dir_match_files,
    x_to_ndx,
    ndx_to_x,
    n_ndx,
    n_points_duration,
    duration,
    index_offset,
    bin_bounds,
    bin_center

include("times.jl")
include("interval.jl")
include("indices.jl")
include("files.jl")

end # module
