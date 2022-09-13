using ArgParse

function parse_commandline()
    s = ArgParseSettings()
    
    @add_arg_table s begin
        "--test1"
            help = "test1"
        "--test2", "-t"
            help = "test2"
            required = true
        #     arg_type = Int
        #     default = 0
        # "--flag1"
        #     help = "flag1"
        #     action = :store_true
        "--arg1"
            help = "arg1"
            required = true
    end

    return parse_args(s)
end


# function main()
    parsed_args = parse_commandline()
    println("Parsed args:")
    for (arg,val) in parsed_args
        println("   $arg  =>  $val")
    end
    a = parsed_args["test1"]
    println(a)
# end

# main()