using GLUtilities
using Base.Test

@testset "GLUtilities"  begin
    @testset "indices" begin
        @test clipind(-1, 2) == 1
        @test clipind(3, 2) == 2
        @test clipind(1, 2) == 1
        @test clipind(2, 2) == 2
        @test clipind(Int32(1), Int64(2)) == 1
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
