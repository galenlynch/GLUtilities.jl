"Make a mmaped array of type A"
function typemmap(
    ::Type{A},
    dims::NTuple{N, Int};
    basedir::AbstractString = tempdir(),
    suffix::AbstractString = "",
    fpath::AbstractString = joinpath(basedir, basename(tempname()) * suffix),
    autoclean::Bool = true
) where {A<:AbstractArray, N}
    arr = Mmap.mmap(fpath, A, dims; grow = true)
    autoclean && atexit(()->rm(fpath))
    arr, fpath
end
function typemmap(a::AbstractArray{T, N}, args...; kwargs...) where {T, N}
    typemmap(Array{T, N}, size(a), args...; kwargs...)
end

function to_mmap(a::AbstractArray, kwargs...)
    mma, path = typemmap(a; kwargs...)
    copy!(mma, a)
    mma, path
end
