module FileOutput

    import Base: Filesystem

    export Output
    function Output(filename, x, x_range, y)
        fn = filename
        # makefiles if not exist
        if isfile(fn) == false
            # mkpath(directory)
            touch(string(fn))
        end
        # cd(directory)
        io = open(fn, "w")
        for i in 1:x_range
            println(io, string(x[i], " ", y[i]))
        end
        close(io)
        return nothing
    end
end

module FileInput

    import Base: Filesystem
    import DelimitedFiles: readdlm
    export file_read
    function file_read(type::String; args...)
        if type == "led"
            directory = string("input/light_coordinate.txt")
        elseif type == "user"
            user_type = string(args[:user_type])
            directory = string("input/user_coordinate_", 
            user_type,
            ".txt")
        else
            throw(DomainError(type, "Wrong type"))
        end

        mat = readdlm(directory)
        return mat
    end
end

# import ..FileInput: file_read
# using LinearAlgebra


# a = file_read("user",user_type=1)
# display(a)
# println(norm(a[1,:] - a[3,:]))
# println(a[2,:])