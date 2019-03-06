__precompile__()
module GLUtilities

using Compat, Formatting, Distributions

using IterTools: imap

import Base:
    isless,
    print,
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
    -

@static if VERSION >= v"0.7.0-DEV.2575"
    using
    Dates,
    LinearAlgebra,
    Compat,
    Statistics,
    Mmap,
    Random,
    SharedArrays,
    Distributed

    import Dates: DateTime
    import Statistics: cov
else
    import Base: cov, DateTime
end


# package code goes here
export
    # Constants
    POSTGRES_DATE_FORMAT,
    PSQL_DATETIME_REG,
    MICRO_FORMAT,
    JULIA_DT_REG,

    # Functions
    ## Promotion helper
    div_type,

    ## Time stuff
    FILE_DATEFORMAT,
    PreciseDateTime,
    RangeBound,
    TSRange,
    add_seconds,
    time_range_to_sec,
    matlab_datevec_to_datetime,
    postgres_time_str,
    matlab_datestring,
    iso_fine_datestring,
    micros,
    dt_and_micros,

    ## Interval stuff
    check_overlap,
    interval_intersect,
    interval_intersections,
    measure,
    midpoint,
    clip,
    clip_int,
    expand_intervals!,
    expand_intervals,
    join_intervals!,
    join_intervals,
    interval_complements,
    intervals_diff,
    mask_events,
    find_overlaps,
    interval_indices,
    is_subinterval,
    throttle,

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
    invert_perm,

    ## String stuff
    only_matches,

    ## File system stuff
    dir_match_files,
    dir_find_files,

    ## equality checking
    absdiff,
    allsame,
    anyeq,

    ## Misc
    reduce_extrema,
    extrema_red,
    postgres_time_str,
    parse_postgres_array,
    postgres_tsrange_to_datetime_micros,
    postgres_make_tsrange_str,

    ## Array stuff
    weighted_mean,
    weighted_mean_dim,
    local_extrema,
    mad_quantiles,
    mad_quantiles!,
    rev_view,
    pairwise_idx,
    pairwise_idxs,
    find_closest,
    map_pairwise,
    pmap_pairwise,
    find_subseq,
    subselect,
    simple_summary_stats,
    skipnothing,
    moving_sum!,
    moving_sum,
    trailing_zeros_idx,
    thresh_cross,
    centered_basis,
    imap_product,
    glhist!,
    glhist,
    find_local_extrema,
    stepsize,
    filter_no_collisions,
    window_counts,

    ## Mmap stuff
    typemmap,
    to_mmap,
    file_arr_size,

    ## Testing
    redirect_io,
    @redirect_io,

    ## Random
    randperm_notsame,
    mc_twotail_asymm_p,
    binomial_p_ci

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

end # module
