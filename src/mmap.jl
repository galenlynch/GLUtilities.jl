"Make a mmaped array of type A"
function typemmap(
    ::Type{A},
    dims::NTuple{N,Int};
    basedir::String = tempdir(),
    suffix::String = "",
    fpath::String = joinpath(basedir, basename(tempname()) * suffix),
    autoclean::Bool = true,
    readonly::Bool = false,
) where {A<:AbstractArray,N}
    arr = open(fpath, ifelse(readonly, "r+", "w+")) do io
        Mmap.mmap(io, A, dims; grow = true)
    end
    if autoclean
        finalizer(arr) do a
            try
                rm(fpath; force = true)
            catch
                # File might already be deleted or locked, that's ok
            end
        end
    end
    arr, fpath
end

function typemmap(a::AbstractArray{T,N}, args...; kwargs...) where {T,N}
    typemmap(Array{T,N}, size(a), args...; kwargs...)
end

function to_mmap(a::AbstractArray, arrtype::DataType = typeof(a); kwargs...)
    mma, path = typemmap(arrtype, size(a); kwargs...)
    copyto!(mma, a)
    mma, path
end

function file_arr_size(file_str::AbstractString, file_eltype::DataType)
    finfo = stat(file_str)
    el_sizes = sizeof(file_eltype)
    convert(Int, finfo.size / el_sizes)
end
