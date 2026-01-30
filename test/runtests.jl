using GLUtilities, Dates, Test, Mmap

@testset "GLUtilities" begin
    @testset "times" begin
        @test add_seconds(DateTime(2013, 7, 1), 1) ==
              PreciseDateTime(DateTime(2013, 7, 1, 0, 0, 1))

        @test duration(
            DateTime(2013, 7, 1, 0, 0, 0),
            0,
            DateTime(2013, 7, 1, 0, 0, 1),
            0,
        ) == 1

        @test datevec_to_precisedatetime(Float64[2017, 05, 14, 13, 53, 22.222]) ==
              PreciseDateTime(DateTime(2017, 05, 14, 13, 53, 22, 222))

    end

    @testset "array" begin
        A = rand(20)
        B = rand(20)
        C = rand(20)

        cov([A, B, C])
    end

    @testset "mmap" begin
        test_len = 5
        (arr, path) = typemmap(Vector{Int}, (2,); autoclean = true)
        A = rand(test_len)
        (mma, path) = to_mmap(A)
        @test all(mma .== A)
        @test file_arr_size(path, eltype(A)) == test_len
    end

    @testset "equality" begin
        A = ones(3, 3)
        @test allsame(A)
        A[1] = 0
        @test !allsame(A)

        @test allsame(1, 1)
        @test !allsame(1, 2)
        @test allsame(1)
        @test allsame(length, (1, 2), (3, 4))
    end

    @testset "files" begin
        dir_find_files(r"")
        dir_match_files(r"")
    end
end
