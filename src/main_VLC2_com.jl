# using libraries
using Base
using ArgParse
using LinearAlgebra: norm
using Distributions: Uniform

# local libraries
include("ProjectVLC.jl")

import .ProjectVLC.Channels: phi_rad, vlc_channel, theta_deg, shadow_check
import .ProjectVLC.Parameters: ψ_c, ψ_05, I_DC, Nb, u_r, A_PD, β, η, height, device_height, N0, height_user_body, shoulder_width, x_eve, y_eve, led_com, user_coop
import .ProjectVLC.FileOutput: Output_3d
import .ProjectVLC.Functions: dbm2watt, parse_commandline



function main()
    parse_args = parse_commandline()
    Ps = parse(Float64, parse_args["power"]) # transmission power
    u_type = parse(Int64, parse_args["usertype"])
    simulation_loop = parse(Int64, parse_args["period"])

    led = copy(led_com)
    led_num = size(led,1)
    user = user_coop(u_type)
    user_num = size(user,1)
    ps = Ps
    n0 = dbm2watt(N0)

    capacity_user_sum_simu = zeros(length(x_eve), length(y_eve))
    capacity_eve_simu = zeros(length(x_eve), length(y_eve))
    secrecy_simu = zeros(length(x_eve), length(y_eve))

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


            eve = [x_eve[x_index], y_eve[y_index], device_height]
            # simulation
            sum_user = 0
            sum_eve = 0
            sec = 0
            for loop_index in 1:simulation_loop
                
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
                end   
                
                h_eve = zeros(led_num)
                for i in 1:led_num
                    h_eve[i] = (vlc_channel(
                        eve_psi_matrix[i],
                        deg2rad(ψ_c),
                        eve_theta_rad[i],
                        deg2rad(ψ_05),
                        eve_d_matrix[i],
                        A_PD,
                        Nb,
                        η)
                        * eve_led_block[i]
                        )
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
                        h_user[n,i] = (vlc_channel(
                            user_psi_matrix[n,i],
                            deg2rad(ψ_c),
                            user_theta_rad[n,i],
                            deg2rad(ψ_05),
                            user_d_matrix[n,i],
                            A_PD,
                            Nb,
                            η)
                            * user_led_block[n,i]
                            )

                        # Each floor set the NOMA rules based on user number in its coverage area

                        # user
                        user_num_per_led[i] = length(filter(!iszero,h_user[:,i])) # get the usernumber of each led
                        for s in 1:user_num_per_led[i]
                            if s < user_num_per_led[i]
                                β_sum_per_led[i] = β * (1 - β)^(s-1)
                            else
                                β_sum_per_led[i] = (1 - β)^(s-1)
                            end
                        end

                    end
                    # select
                    led_indice_user = argmax(h_user[n,:]) # get the indice of maximum channel
                    # println(led_indice_user)
                    # led_indice_eve = argmax(h_eve)
                    # println()
                    # println(led_indice_user)
                    # println(user_num_per_led[led_indice_user])
                    # println(β_sum_per_led[led_indice_user])
                    # println((1 - β)^(user_num_per_led[led_indice_user] - 1) - β_sum_per_led[led_indice_user])
                    println(h_user[n,led_indice_user]/(sum(h_user[n,:]) - h_user[n,led_indice_user]))
                    # println(sum(h_user[n,:]))
                    user_SINR = (h_user[n,led_indice_user]^2 * ps * β_sum_per_led[led_indice_user] 
                        / (h_user[n,led_indice_user]^2 * ps * ((1 - β)^(user_num_per_led[led_indice_user] - 1) - β_sum_per_led[led_indice_user]) 
                            + (sum(h_user[n,:]) - h_user[n,led_indice_user])^2 * ps + n0))
                    # println((1 - β)^(user_num_per_led[led_indice_user] - 1) - β_sum_per_led[led_indice_user])
                    capacity_user += 0.5 * log2(1 + user_SINR)
                    # eve
                    if h_eve[led_indice_user] != 0.0
                        eve_SINR = (h_eve[led_indice_user]^2 * ps * β_sum_per_led[led_indice_user]
                        / (h_eve[led_indice_user]^2 * ps * ((1 - β)^(user_num_per_led[led_indice_user] - 1) - β_sum_per_led[led_indice_user]) 
                            + (sum(h_eve) - h_eve[led_indice_user])^2 * ps + n0))
                    else
                        eve_SINR = 0.0
                    end
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
    path = string("results_com/case2/Loop_num=", Int(simulation_loop), 
        "/Ps=", Int(Ps), 
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