__precompile__()
module GLUtilities

using Formatting

# package code goes here
export
    # Constants
    POSTGRES_DATE_FORMAT,
    MICRO_FORMAT,

    # Functions
    ## Time stuff
    add_time_and_micros,
    time_range_to_sec,
    matlab_datevec_to_datetime,
    postgres_time_str,

    ## Interval stuff
    check_overlap,

    ## Indices stuff
    clip_ndx,
    t_to_ndx,
    ndx_to_t,
    n_ndx,
    n_points_duration,
    duration,
    ndx_offset,
    bin_bounds,
    bin_center,

    ## String stuff
    only_matches,

    ## File system stuff
    dir_match_files,
    dir_find_files,

    ## Misc
    reduce_extrema,
    postgres_time_str

include("times.jl")
include("interval.jl")
include("indices.jl")
include("files.jl")
include("strings.jl")
include("postgres.jl")

end # module
