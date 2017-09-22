function dir_match_files(reg::Regex, dir::AbstractString = ".")
    files = readdir(dir)
    return filter(x -> ismatch(reg, x), files)
end
