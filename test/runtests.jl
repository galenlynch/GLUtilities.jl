using GLUtilities
using Base.Test

@testset "GLUtilities"  begin
    @testset "types" begin
        @test div_type(Int) == Float64
        @test div_type(Int, Int) == Float64
        @test div_type(Float32) == Float32
        @test div_type(Float32, Int) == Float32
        @test div_type(Float32, Float64) == Float64
        @test div_type(2, 5) == Float64
        @test div_type(1.0f0, 1) == Float32
    end
    @testset "indices" begin
        @test clip_ndx(-1, 2) == 1
        @test clip_ndx(3, 2) == 2
        @test clip_ndx(1, 2) == 1
        @test clip_ndx(2, 2) == 2
        @test clip_ndx(Int32(1), Int64(2)) == 1

        @test ndx_to_t(1, 1, 0) == 0
        @test ndx_to_t(30000, 30000, 0) == 29999 / 30000
        @test ndx_to_t(1, 1, 20) == 20
        @test ndx_to_t(1:2, 1, 0) == 0.0:1.0:1.0
        @test ndx_to_t(1:1, 1, 20) == 20.0:1.0:20.0
        @test ndx_to_t([1, 2], 1, 0) == [0, 1]

        @test t_to_ndx(1, 30000, 0) == 30001
        @test t_to_ndx(1, 30000, 1) == 1
        @test t_to_ndx(1:2, 1, 0) == [2, 3]
        @test t_to_ndx([1, 2], 1, 0) ==[2, 3]

        @test n_ndx(1, 1) == 1
        @test n_ndx(1, 2) == 2

        @test duration(2, 1) == 1.0
        @test duration(30001, 30000) == 1.0

        @test ndx_offset(1, 1) == 1
        @test ndx_offset(1, 2) == 2
        @test ndx_offset(1, 0) == 0
        @test ndx_offset(3, -3) == 1

        @test bin_bounds(1, 1024) == (1, 1024)
        @test bin_bounds(2, 1024) == (1025, 2048)
        @test bin_bounds(1, 1024, 1023) == (1, 1023)
        @test bin_bounds(1:2, 1024) == (1:1024:1025, 1024:1024:2048)

        @test bin_center(1, 1024) == 512.5
        @test bin_center([(1, 1024)]) == [512.5]
        @test bin_center(1:2, 1024) == 512.5:1024.0:1536.5

        @test make_slice_idx(2, 1, 1) == (1, :)
        @test make_slice_idx(2, 1, 2) == (2, :)
        @test make_slice_idx(3, 1, 1:2) == (1:2, :, :)

        @test make_expand_idx(2, 1) == (:, 1)
        @test make_expand_idx(2, 2) == (1, :)

        @test copy_length_check(5, 1)
        @test ! copy_length_check(1, 5)
        @test copy_length_check(rand(5), rand(1))
        @test ! copy_length_check(rand(1), rand(5))
    end

    @testset "times" begin
        @test add_time_and_micros(DateTime(2013, 7, 1), 1) == (DateTime(2013, 7, 1, 0, 0, 1), 0)

        @test time_range_to_sec(DateTime(2013, 7, 1, 0, 0, 0), 0, DateTime(2013, 7, 1, 0, 0, 1), 0) == 1

        @test matlab_datevec_to_datetime(Float64[2017, 05, 14, 13, 53, 22.222]) ==
            DateTime(2017, 05, 14, 13, 53, 22, 222)

        @test ndx_wrap(1, 5) == 1
        @test ndx_wrap(6, 5) == 1
        @test ndx_wrap(5, 5) == 5
    end

    @testset "ranges" begin
        @test check_overlap(1, 3, 2, 3)
        @test !check_overlap(1, 3, 4, 5)
        @test interval_intersect(1, 3, 4, 5) == Int[]
        @test interval_intersect(1, 4, 3, 5) == [3, 4]
    end

    @testset "array" begin
        A = rand(3, 3)
        B = rand(3)

        @test all(B[end:-1:1] .== rev_view(B))

        weighted_mean_dim(A, B)

        C = [2, 1, 2, 3, 2]
        @test local_extrema(C) == [4]
        @test local_extrema(C, <) == [2]
        @test local_extrema(C[1:4]) == []

        A = rand(20)
        B = rand(20)
        C = rand(20)

        cov([A,B,C])
    end

    @testset "mmap" begin
        (arr, path) = typemmap(Vector{Int}, (2,); cleanup=false)
    end

    @testset "equality" begin
        A = ones(3, 3)
        @test allsame(A)
        A[1] = 0
        @test ! allsame(A)

        @test allsame(1, 1)
        @test ! allsame(1, 2)
        @test allsame(1)
        @test allsame(length, (1,2), (3, 4))
    end
end
