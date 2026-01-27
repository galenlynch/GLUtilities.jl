function redirect_io(
    f::Function,
    stdout::AbstractString = joinpath(pwd(), "jlout.txt"),
    stderr::AbstractString = joinpath(pwd(), "jlerr.txt"),
)
    open(stdout, "w+") do io
        open(stderr, "w+") do ioe
            redirect_stdout(() -> redirect_stderr(() -> f(), ioe), io)
        end
    end
end

macro redirect_io(ex)
    old_stdout = esc(STDOUT)
    old_stderr = esc(STDERR)
    quote
        open("jlout.txt", "w+") do io
            io_r = redirect_stdout(io)
            try
                open("jlerr.txt", "w+") do ioe
                    ioe_r = redirect_stderr(ioe)
                    try
                        $ex
                    finally
                        redirect_stderr($old_stderr)
                    end
                end
            finally
                redirect_stdout($old_stdout)
            end
        end
    end
end
