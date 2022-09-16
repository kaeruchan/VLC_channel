# using libraries
using Base
using ArgParse
using LinearAlgebra
using Distributions: Uniform

# local libraries
include("ProjectVLC.jl")

import .ProjectVLC.Channels: phi_rad, vlc_channel, theta_deg, omega_deg
import .ProjectVLC.Parameters: ψ_c, ψ_05, I_DC, Nb, u_r, A_PD, β, height, device_height, trajectory_length, N0
import .ProjectVLC.FileOutput: Output
import .ProjectVLC.FileInput: file_read

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

function trajectory_pos(
    total_length,
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


function dbm2watt(dbm)
    return 10 ^ ((dbm - 30)/10)
end


function main()
    parse_args = parse_commandline()
    Ps = parse(Float64, parse_args["power"]) # transmission power
    # println(Ps)
    u_type = parse(Int64, parse_args["usertype"])
    simulation_loop = parse(Int64, parse_args["period"])
    # Ps = 10
    # u_type = 1
    # simulation_loop = Int64(1e6)

    led = file_read("led")
    led_num = size(led,1)
    user = file_read("user",user_type=u_type)
    user_num = size(user,1)
    eve_init = [5,5,0.85]
    # Power = 10.0 # dbm
    # power = dbm2watt(Power)
    ps = dbm2watt(Ps)
    time = 0:trajectory_length
    n0 = dbm2watt(N0)

    capacity_user_sum_simu = zeros(length(time))
    capacity_eve_simu = zeros(length(time))
    secrecy_simu = zeros(length(time))
    for time_index in eachindex(time)


        eve = trajectory_pos(120,eve_init,1,time[time_index])
        # simulation
        sum_user = 0
        sum_eve = 0
        sec = 0
        for loop_index in 1:simulation_loop
            
            # calculate distance,phi between users,eve and led
            user_d_matrix = zeros(user_num,led_num)
            eve_d_matrix = zeros(led_num)
            user_psi_matrix = zeros(user_num,led_num)
            user_theta_rad = zeros(user_num,led_num)
            user_omega_deg = rand(Uniform(-180,180),user_num)
            for n in 1:user_num
                for i in 1:led_num
                    user_psi_matrix[n,i] = phi_rad(led[i,:],user[n,:],theta_deg("walk","opt"),user_omega_deg[n])
                    user_d_matrix[n,i] = norm(led[i,:] - user[n,:])
                    user_theta_rad[n,i] = acos((height-device_height) / user_d_matrix[n,i])
                end
            end

            # calculate distance, phi between eve and led
            # eve_theta_rad = asin.((3.2 - 0.85)./ eve_d_matrix)
            eve_theta_rad = zeros(led_num)
            eve_psi_matrix = zeros(led_num)
            eve_omega_deg = rand(Uniform(-180,180))
            for i in 1:led_num
                eve_d_matrix[i] = norm(led[i,:]-eve)
                eve_psi_matrix[i] = phi_rad(led[i,:],eve,theta_deg("walk","opt"),eve_omega_deg)
                eve_theta_rad[i] = acos((height - device_height) / eve_d_matrix[i])
            end   
            
            h_eve = zeros(led_num)
            for i in 1:led_num
                h_eve[i] = vlc_channel(eve_psi_matrix[i],deg2rad(ψ_c),eve_theta_rad[i],deg2rad(ψ_05),eve_d_matrix[i],A_PD,Nb)
            end
            
            h_user = zeros(user_num,led_num) 
            # initial the channel gain matrix
            capacity_user = 0
            capacity_eve = 0
            for n in 1:user_num
                # set index of the user number

                # initial the SINR calculation
                # user_SINR = 0
                # eve_SINR = 0
                

                user_num_per_led = zeros(led_num)
                β_sum_per_led = zeros(led_num)
                for i in 1:led_num
                    # set index of the LED number 
                    # get the value of the channel gain
                    h_user[n,i] = vlc_channel(
                        user_psi_matrix[n,i],
                        deg2rad(ψ_c),
                        user_theta_rad[n,i],
                        deg2rad(ψ_05),
                        user_d_matrix[n,i],
                        A_PD,
                        Nb)

                    # Each floor set the NOMA rules based on user number in its coverage area

                    # user
                    user_num_per_led[i] = length(filter(!iszero,h_user[:,i])) # get the usernumber of each led
                    for s in 1:user_num_per_led[i]
                        if s < user_num_per_led[i]
                            β_sum_per_led[i] = (1 - β)^(s-1) - (1 - β)^s
                        else
                            β_sum_per_led[i] = (1 - β)^s
                        end
                        
                        # select
                        led_indice_user = argmax(h_user[n,:]) # get the indice of maximum channel
                        # led_indice_eve = argmax(h_eve)
                        user_SINR = (h_user[n,led_indice_user] * ps * β_sum_per_led[i] 
                            / (h_user[n,led_indice_user] * ps * (1 - β_sum_per_led[i]) 
                                + (sum(h_user[n,:]) - h_user[n,led_indice_user]) * ps + n0))
                        capacity_user += 0.5 * log2(1 + user_SINR)
                        # eve
                        if h_eve[led_indice_user] != 0.0
                            eve_SINR = (h_eve[led_indice_user] * ps * β_sum_per_led[i]
                            / (h_eve[led_indice_user] * ps * (1 - β_sum_per_led[i]) 
                                + (sum(h_eve) - h_eve[led_indice_user]) * ps + n0))
                        else
                            eve_SINR = 0.0
                        end
                        capacity_eve += 0.5 * log2(1 + eve_SINR)
                    end

                    # eve
                    # if user_num_per_led[i] != 0
                    #     eve_SINR += h_eve[i] * ps * β_sum / (h_eve[i] * ps * (1 - β_sum) + n0)
                    # end
                    
                    # user_SINR += h_user[n,i] * ps * β_sum / (h_user[n,i] * ps * (1 - β_sum) + n0)
                    # eve_SINR += h_eve[i] * ps * β_sum / (h_eve[i] * ps * (1 - β_sum) + n0)

                    # SINR will be calculated as the maximum of two selection
                end

                
                # capacity_user += 0.5 * log2(1 + user_SINR)
                # capacity_eve += 0.5 * log2(1 + eve_SINR)
            end
            
            sum_user += capacity_user        
            sum_eve += capacity_eve
            sec += max((capacity_user - capacity_eve), 0)
            print("\r",
            # "Position = (", eve[1], "," ,eve[2], ",", eve[3], ")",
            "Length = ", time[time_index], 
            # ", Capacity_user = ", sum_user / loop_index,
            # ", Capacity_eve = ", sum_eve / loop_index,
            ", Secrecy_capacity = ", sec / loop_index,
            ", Simulation Period = ", loop_index)
        end

        capacity_user_sum_simu[time_index] = sum_user / simulation_loop
        capacity_eve_simu[time_index] = sum_eve / simulation_loop
        secrecy_simu[time_index] = sec / simulation_loop
        print("\n")
    end

    # output file
    path = string("results/case2/", "Ps=", Int(Ps), "/", "user_type", u_type, "/")
    file_user = string("VLC_user.txt")
    file_eve = string("VLC_eve.txt")
    file_sec = string("VLC_sec.txt")
    
    if ispath(path) == false
        mkpath(path)
    end
    cd(path)

    Output(file_eve, time, length(time), capacity_eve_simu)
    Output(file_user, time, length(time), capacity_user_sum_simu)
    Output(file_sec, time, length(time), secrecy_simu)




end

# main()

if contains(@__FILE__, PROGRAM_FILE)
    main()
end