# Deprecations for functions moved to PreciseTimestamps.jl
for fn in [
    :POSTGRES_DATE_FORMAT,
    :PSQL_DATETIME_REG,
    :JULIA_DT_REG,
    :FILE_DATEFORMAT,
    :PreciseDateTime,
    :RangeBound,
    :TSRange,
    :add_seconds,
    :datevec_to_precisedatetime,
    :matlab_datestring,
    :iso_fine_datestring,
    :trailing_micros,
    :dt_and_micros,
    :postgres_time_str,
    :parse_postgres_array,
    :postgres_tsrange_to_datetime_micros,
    :postgres_make_tsrange_str,
    :postgres_tuple_list,
    :postgres_tuple_rows,
    :to_ntuple,
]
    depr_msg = "GLUtilities.$fn is deprecated, use PreciseTimestamps.$fn instead."
    @eval begin
        @deprecate $fn(args...; kwargs...) PreciseTimestamps.$fn(args...; kwargs...) false
        export $fn
    end
end

# Deprecations for functions moved to SignalIndices.jl
for fn in [
    :div_type,
    :ndx_to_t,
    :t_to_ndx,
    :t_to_last_ndx,
    :t_sup_to_ndx,
    :clip_ndx,
    :clip_ndx_deviance,
    :n_ndx,
    :ndx_offset,
    :ndx_wrap,
    :duration,
    :time_interval,
    :bin_bounds,
    :bin_center,
    :expand_selection,
    :copy_length_check,
    :copy_length_dest_check,
    :make_slice_idx,
    :make_expand_idx,
    :view_trailing_slice,
    :invert_perm,
    :moving_sum!,
    :moving_sum,
    :local_extrema,
    :find_local_extrema,
    :find_all_edge_triggers,
    :find_first_edge_trigger,
    :thresh_cross,
    :indices_above_thresh,
    :filter_no_collisions,
    :window_counts,
    :centered_basis,
    :stepsize,
    :glhist!,
    :glhist,
    :weighted_mean,
    :weighted_mean_dim,
    :simple_summary_stats,
    :find_closest,
    :subselect,
    :find_subseq,
    :rev_view,
    :pairwise_idxs,
    :pairwise_idx,
    :map_pairwise,
    :imap_product,
    :filtermap,
    :trailing_zeros_idx,
    :clipsize!,
    :find_not_unique,
    :skipoftype,
    :skipnothing,
    :allsame,
    :anyeq,
    :absdiff,
]
    depr_msg = "GLUtilities.$fn is deprecated, use SignalIndices.$fn instead."
    @eval begin
        @deprecate $fn(args...; kwargs...) SignalIndices.$fn(args...; kwargs...) false
        export $fn
    end
end

# Deprecations for functions moved to SortedIntervals.jl
for fn in [
    :check_overlap,
    :is_subinterval,
    :find_overlaps,
    :find_all_overlapping,
    :interval_intersect,
    :interval_intersect_measure,
    :interval_intersections,
    :interval_intersections_overlapping,
    :intervals_diff,
    :interval_complements,
    :overlap_interval_union,
    :join_intervals!,
    :join_intervals,
    :expand_intervals!,
    :expand_intervals,
    :measure,
    :midpoint,
    :clip_int,
    :throttle,
    :mask_events,
    :interval_indices,
    :maximum_interval_overlap,
    :intervals_are_ordered,
    :intervals_are_partially_ordered,
    :parse_ranges_str,
    :measure_to_bounds,
    :clip_interval_duration,
    :reduce_extrema,
    :extrema_red,
]
    depr_msg = "GLUtilities.$fn is deprecated, use SortedIntervals.$fn instead."
    @eval begin
        @deprecate $fn(args...; kwargs...) SortedIntervals.$fn(args...; kwargs...) false
        export $fn
    end
end
