using GLUtilities
using Base.Test

@testset "GLUtilities"  begin
    @testset "indices" begin
        @test clipind(-1, 2) == 1
        @test clipind(3, 2) == 2
        @test clipind(1, 2) == 1
        @test clipind(2, 2) == 2
        @test clipind(Int32(1), Int64(2)) == 1

        @test ndx_to_x(1, 1, 0) == 0
        @test ndx_to_x(30000, 30000, 0) == 29999 / 30000
        @test ndx_to_x(1, 1, 20) == 20
        @test ndx_to_x(1:2, 1, 0) == 0.0:1.0:1.0
        @test ndx_to_x(1:1, 1, 20) == 20.0:1.0:20.0
        @test ndx_to_x([1, 2], 1, 0) == [0, 1]

        @test x_to_ndx(1, 30000, 0) == 30001
        @test x_to_ndx(1, 30000, 1) == 1
        @test x_to_ndx(1:2, 1, 0) == [2, 3]
        @test x_to_ndx([1, 2], 1, 0) ==[2, 3]

        @test n_ndx(1, 1) == 1
        @test n_ndx(1, 2) == 2

        @test n_points_duration(2, 1) == 1.0
        @test n_points_duration(30001, 30000) == 1.0

        @test index_offset(1, 1) == 1
        @test index_offset(1, 2) == 2
        @test index_offset(1, 0) == 0
        @test index_offset(3, -3) == 1

        @test bin_bounds(1, 1024) == (1, 1024)
        @test bin_bounds(2, 1024) == (1025, 2048)
        @test bin_bounds(1, 1024, 1023) == (1, 1023)
        @test bin_bounds(1:2, 1024) == (1:1024:1025, 1024:1024:2048)

        @test bin_center(1, 1024) == 512.5
        @test bin_center([(1, 1024)]) == [512.5]
        @test bin_center(1:2, 1024) == 512.5:1024.0:1536.5
    end

    @testset "times" begin
        @test add_time_and_micros(DateTime(2013, 7, 1), 1) == (DateTime(2013, 7, 1, 0, 0, 1), 0)

        @test time_range_to_sec(DateTime(2013, 7, 1, 0, 0, 0), 0, DateTime(2013, 7, 1, 0, 0, 1), 0) == 1

        @test matlab_datevec_to_datetime(Float64[2017, 05, 14, 13, 53, 22.222]) ==
            DateTime(2017, 05, 14, 13, 53, 22, 222)
    end

    @testset "ranges" begin
        @test check_overlap(1, 3, 2, 3)
        @test !check_overlap(1, 3, 4, 5)
    end
end
