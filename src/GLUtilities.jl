__precompile__()
module GLUtilities

using Compat, Formatting

@static if VERSION >= v"0.7.0-DEV.2575"
    using Dates, LinearAlgebra, Compat, Statistics, Mmap
    import Statistics: cov
else
    import Base: cov
end


# package code goes here
export
    # Constants
    POSTGRES_DATE_FORMAT,
    MICRO_FORMAT,

    # Functions
    ## Promotion helper
    div_type,

    ## Time stuff
    add_time_and_micros,
    time_range_to_sec,
    matlab_datevec_to_datetime,
    postgres_time_str,

    ## Interval stuff
    check_overlap,
    interval_intersect,

    ## Indices stuff
    clip_ndx,
    copy_length_check,
    expand_selection,
    t_to_ndx,
    t_to_last_ndx,
    t_sup_to_ndx,
    ndx_to_t,
    ndx_wrap,
    n_ndx,
    duration,
    time_interval,
    ndx_offset,
    bin_bounds,
    bin_center,
    make_slice_idx,
    make_expand_idx,
    view_trailing_slice,

    ## String stuff
    only_matches,

    ## File system stuff
    dir_match_files,
    dir_find_files,

    ## equality checking
    allsame,

    ## Misc
    reduce_extrema,
    extrema_red,
    postgres_time_str,

    ## Array stuff
    weighted_mean,
    weighted_mean_dim,
    local_extrema,
    rev_view,

    ## Mmap stuff
    typemmap,
    to_mmap,
    file_arr_size,

    ## Testing
    redirect_io,
    @redirect_io

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

end # module
