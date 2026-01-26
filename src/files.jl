function dir_find_files(
        reg::Regex, dir::AbstractString = pwd(); full::Bool = false
    )
    files = readdir(dir)
    strs = full ? joinpath.(dir, files) : files
    return filter((x) -> occursin(reg, x), strs)
end

function dir_match_files(
        reg::Regex, dir::AbstractString = pwd(); full::Bool = false
    )
    files = readdir(dir)
    strs = full ? joinpath.(dir, files) : files
    return only_matches(reg, strs)
end
