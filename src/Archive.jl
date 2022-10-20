module Archive

    using Base: copy
    using Core: throw, DomainError

    export trajectory_pos
    function trajectory_pos(
        total_length::Float64,
        start_pos, 
        speed,
        current_time)
        #=
            Get the current position for the square around
        =#
        
        current_pos = copy(start_pos)
        one_length = total_length * 0.25
        total_time = total_length / speed

        # The trajectory is square with clockwise.

        if current_time <= total_time * 0.25
            current_pos[2] += current_time * speed
        elseif current_time > total_time * 0.25 && current_time <= total_time * 0.5
            current_pos[2] += one_length
            current_pos[1] += (current_time - total_time * 0.25) * speed
        elseif current_time > total_time * 0.5 && current_time <= total_time * 0.75
            current_pos[2] += one_length - (current_time - total_time * 0.5) * speed
            current_pos[1] += one_length
        elseif current_time > total_time * 0.75 && current_time <= total_time * 1
            current_pos[1] += one_length - (current_time - total_time * 0.75) * speed
        else
            throw(DomainError(current_time,
                "Current time is bigger than (total_length / speed)"))
        end

        return current_pos

    end
end