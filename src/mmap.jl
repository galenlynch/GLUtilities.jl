"Make a mmaped array of type A"
function typemmap(
    ::Type{A}, dims::NTuple{N, Int}, basedir::AbstractString = tempdir();
    cleanup::Bool = true
) where {A<:AbstractArray, N}
    (path, io) = mktemp(basedir)
    cleanup && atexit(()->rm(path))
    arr = try
        Mmap.mmap(io, A, dims; grow = true)
    finally
        close(io)
    end
    return (arr, path::String)
end
function typemmap(a::AbstractArray{T, N}; kwargs...) where {T, N}
    typemmap(Array{T, N}, size(a); kwargs...)
end

function to_mmap(a::AbstractArray, kwargs...)
    mma, path = typemmap(a; kwargs...)
    copy!(mma, a)
    mma, path
end
