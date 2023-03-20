__precompile__()

# using libraries
using Base
using Base.Threads
using ArgParse
using LinearAlgebra
using Distributions: Uniform
# local libraries
include("src/ProjectVLC.jl")

import .ProjectVLC.Channels: phi_rad, vlc_channel, theta_deg, shadow_check
import .ProjectVLC.Parameters: ψ_c, ψ_05, I_DC, Nb, u_r, A_PD, β, η, height, device_height, N0, height_user_body, shoulder_width, x_eve, y_eve, led, user_coop
import .ProjectVLC.FileOutput: Output_3d
import .ProjectVLC.FileInput: file_read
import .ProjectVLC.Functions: dbm2watt, parse_commandline


function main()
    parse_args = parse_commandline()
    Ps = parse(Float64, parse_args["power"]) # transmission power
    u_type = parse(Int64, parse_args["usertype"])
    simulation_loop = parse(Int64, parse_args["period"])

    user = user_coop(u_type)
    user_num = size(user,1)
    led_num = size(led,1)
    # eve_init = [5,5,0.85]
    # Power = 10.0 # dbm
    # power = dbm2watt(Power)
    ps = Ps
    n0 = dbm2watt(N0)

    capacity_user_sum_simu = zeros(length(x_eve),length(y_eve))
    capacity_eve_simu = zeros(length(x_eve),length(y_eve))
    secrecy_simu = zeros(length(x_eve),length(y_eve))

    user_d_matrix = zeros(user_num,led_num)
    eve_d_matrix = zeros(led_num)
    user_psi_matrix = zeros(user_num,led_num)
    user_body = zeros(user_num,3)
    user_theta_rad = zeros(user_num,led_num)
    eve_theta_rad = zeros(led_num)
    eve_body = zeros(3)
    eve_psi_matrix = zeros(led_num)

    for x_index in eachindex(x_eve)
        for y_index in eachindex(y_eve)

        
            eve = [x_eve[x_index],y_eve[y_index],device_height]
            # simulation
            sum_user = 0
            sum_eve = 0
            sec = 0
            # loop_index_ato = Atomic{Int}(0)
            for loop_index in 1:simulation_loop
                # Threads.atomic_add!(loop_index_ato,loop_index)
                user_led_block = ones(user_num,led_num)
                eve_led_block = ones(led_num)
                # calculate distance,phi between users,eve and led
                user_omega_deg = rand(Uniform(-180,180),user_num)

                eve_omega_deg = rand(Uniform(-180,180))

                eve_body = [
                    eve[1] + cos(eve_omega_deg),
                    eve[2] + sin(eve_omega_deg),
                    height_user_body
                ]


                for n in 1:user_num
                    user_body[n,:] = [
                        user[n,1] + cos(user_omega_deg[n]), 
                        user[n,2] + sin(user_omega_deg[n]),
                        height_user_body] 


                    for i in 1:led_num
                        user_psi_matrix[n,i] = phi_rad(led[i,:],user[n,:],theta_deg("walk","opt"),user_omega_deg[n])
                        user_d_matrix[n,i] = norm(led[i,:] - user[n,:])
                        user_theta_rad[n,i] = acos((height-device_height) / user_d_matrix[n,i])

                        # check block -- user
                        for n_body in 1:user_num
                            # check if any user's body block
                            if shadow_check(led[i,:],user[n,:],user_body[n_body,:],shoulder_width) == 0.0
                                user_led_block[n,i] = 0.0
                                break
                            end
                        end
                        # check if eve's body block
                        if shadow_check(led[i,:],user[n,:],eve_body,shoulder_width) == 0.0
                            user_led_block[n,i] = 0.0
                        end
                    end
                end


                
                
                

                # calculate distance, phi between eve and led
    
                h_eve = zeros(led_num)
                for i in 1:led_num
                    eve_d_matrix[i] = norm(led[i,:]-eve)
                    eve_psi_matrix[i] = phi_rad(led[i,:],eve,theta_deg("walk","opt"),eve_omega_deg)
                    eve_theta_rad[i] = acos((height - device_height) / eve_d_matrix[i])

                    # check block -- eve
                    for n_body in 1:user_num
                        # check if any user's body block
                        if shadow_check(led[i,:],eve,user_body[n_body,:],shoulder_width) == 0.0
                            eve_led_block[i] = 0.0
                            break
                        end
                    end
                    # check if eve's body block
                    if shadow_check(led[i,:],eve,eve_body,shoulder_width) == 0.0
                        eve_led_block[i] = 0.0
                    end

                    h_eve[i] = vlc_channel(eve_psi_matrix[i],deg2rad(ψ_c),eve_theta_rad[i],deg2rad(ψ_05),eve_d_matrix[i],A_PD,Nb, η)^2 * eve_led_block[i]
                end   
                
                
                h_user = zeros(user_num,led_num)
                capacity_user = 0
                capacity_eve = 0
                for n in 1:user_num
                    if n < user_num
                        β_sum = β * (1 - β)^(n-1)
                    else
                        β_sum = (1 - β)^(n - 1)
                    end
                    # println(β_sum)
                    for i in 1:led_num
                        h_user[n,i] = vlc_channel(
                            user_psi_matrix[n,i],
                            deg2rad(ψ_c),
                            user_theta_rad[n,i],
                            deg2rad(ψ_05),
                            user_d_matrix[n,i],
                            A_PD,
                            Nb,
                            η) * user_led_block[n,i]
                        # println(β_sum)
                    end
                    user_SINR = (sum(h_user[n,:])^2 * ps * β_sum 
                    / (sum(h_user[n,:])^2 * ps * ((1 - β)^(n-1) - β_sum) + n0))
                    # println(user_SINR)
                    capacity_user += 0.5 * log2(1 + user_SINR)

                    eve_SINR = (sum(h_eve)^2 * ps * β_sum 
                    / (sum(h_eve)^2 * ps * ((1 - β)^(n-1) - β_sum) + n0))
                    capacity_eve += 0.5 * log2(1 + eve_SINR)
                    # capacity_user += 0.5 * log2(1 + user_SINR)
                    # capacity_eve += 0.5 * log2(1 + eve_SINR)
                end
                
                sum_user += capacity_user        
                sum_eve += capacity_eve
                sec += max((capacity_user - capacity_eve), 0)
                print("\r",
                "XoYCoordinate = ", [x_eve[x_index],y_eve[y_index]],
                ", Secrecy_capacity = ", sec / loop_index,
                ", Simulation Period = ", loop_index)
            end

            capacity_user_sum_simu[x_index,y_index] = sum_user / simulation_loop
            capacity_eve_simu[x_index,y_index] = sum_eve / simulation_loop
            secrecy_simu[x_index,y_index] = sec / simulation_loop
            print("\n")
        end
    end

    # output file
    path = string("results/case1/Loop_num=", Int(simulation_loop), 
        "/Ps=", Float64(Ps), 
        "/user_type", u_type, "/")
    file_user = string("VLC_user.txt")
    file_eve = string("VLC_eve.txt")
    file_sec = string("VLC_sec.txt")
    
    if ispath(path) == false
        mkpath(path)
    end
    cd(path)

    Output_3d(file_eve, x_eve, length(x_eve), y_eve, length(y_eve), capacity_eve_simu)
    Output_3d(file_user, x_eve, length(x_eve), y_eve, length(y_eve), capacity_user_sum_simu)
    Output_3d(file_sec, x_eve, length(x_eve), y_eve, length(y_eve), secrecy_simu)




end

# main()

if contains(@__FILE__, PROGRAM_FILE)
    main()
end