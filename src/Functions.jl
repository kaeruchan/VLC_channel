__precompile__()

module Algorithm

    using Base: tan, tand, append!, eachindex, union, intersect, push!, deg2rad
    using Core: throw, ArgumentError

    export LED_selection

    function LED_selection(user,user_num,led,led_num,height,device_height,ψ_c,degorrad)
        
        # grouping
        s_group = []
        user_group = []

        if degorrad == "deg"
            r = (height - device_height) * tand(ψ_c)
        elseif degorrad == "rad"
            r = (height - device_height) * tan(ψ_c)
        else
            throw(ArgumentError("Wrong degorrad type!"))
        end
        # LED mark
        for k in 1:user_num
            s_k = []
            for n in 1:led_num
                if (user[k,1] - led[n,1])^2 + (user[k,2] - led[n,2])^2 <= r^2
                    s_k = append!(s_k,n)
                end
            end
            change_remark = 0
            for i in eachindex(s_group)
                if intersect(s_group[i],s_k) != []
                    s_group[i] = union(s_group[i],s_k)
                    user_group[i] = union(user_group[i],k)
                    change_remark = 1
                    break    
                end
            end 
            if change_remark == 0
                s_group = push!(s_group,s_k)
                user_group = push!(user_group,k)
            end
        end

        return s_group, user_group
    end
end

module Functions
    using ArgParse

    export parse_commandline
    function parse_commandline()
        s = ArgParseSettings()

        @add_arg_table s begin
            "--power"
                help = "The transmission power."
                # arg_type = Float64
                required = true
            "--usertype", "-u"
                help = "User type"
                # arg_type = Int64
                required = true
            "--period"
                help = "simulation period"
                # arg_type = Int64
                required = true
        end

        return parse_args(s)
    end

    export dbm2watt
    function dbm2watt(dbm)
        return 10 ^ ((dbm - 30)/10)
    end

end