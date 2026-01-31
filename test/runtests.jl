using GLUtilities, Dates, Test, Mmap

@testset "GLUtilities" begin

    @testset "mmap" begin
        test_len = 5
        (arr, path) = typemmap(Vector{Int}, (2,); autoclean = true)
        A = rand(test_len)
        (mma, path) = to_mmap(A)
        @test all(mma .== A)
        @test file_arr_size(path, eltype(A)) == test_len
    end

    @testset "files" begin
        dir_find_files(r"")
        dir_match_files(r"")
    end

    @testset "cov" begin
        A = rand(20)
        B = rand(20)
        C = rand(20)
        c = cov([A, B, C])
        @test size(c) == (3, 3)
    end
end
