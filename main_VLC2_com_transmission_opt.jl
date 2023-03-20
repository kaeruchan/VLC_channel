__precompile__()


# using libraries
using Base
using ArgParse
using LinearAlgebra: norm
using Distributions: Uniform

# local libraries
include("src/ProjectVLC.jl")

import .ProjectVLC.Channels: phi_rad, vlc_channel, theta_deg, shadow_check, phi_rad_est
import .ProjectVLC.Parameters: ψ_c, ψ_05, I_DC, Nb, u_r, A_PD, β, η, height, device_height, N0, height_user_body, shoulder_width, led_com, user_coop, led_com_to_led_ratio
import .ProjectVLC.FileOutput: Output_2d
import .ProjectVLC.Functions: dbm2watt, parse_commandline
import .ProjectVLC.Optimal: beta_optimal



function main()
    parse_args = parse_commandline()
    Ps_max = parse(Float64, parse_args["power"]) # transmission power
    u_type = parse(Int64, parse_args["usertype"])
    simulation_loop = parse(Int64, parse_args["period"])
    led = copy(led_com)

    led_num = size(led,1)
    user = user_coop(u_type)
    user_num = size(user,1)
    ps = 0.1:0.05:Ps_max
    ps_real = ps * led_com_to_led_ratio
    n0 = dbm2watt(N0)

    theta_mean = 29.67 # degree

    capacity_user_sum_simu = zeros(length(ps))
    capacity_user_est_sum_simu = zeros(length(ps))
    # capacity_eve_simu = zeros(length(x_eve), length(y_eve))
    # secrecy_simu = zeros(length(x_eve), length(y_eve))

    user_d_matrix = zeros(user_num,led_num)
    # eve_d_matrix = zeros(led_num)
    user_psi_matrix = zeros(user_num,led_num)
    user_psi_matrix_est = zeros(user_num,led_num)
    user_body = zeros(user_num,3)
    user_theta_rad = zeros(user_num,led_num)
    # eve_theta_rad = zeros(led_num)
    eve_body = zeros(3)
    # eve_psi_matrix = zeros(led_num)
    

    for ps_index in eachindex(ps_real)
        # simulation
        sum_user = 0
        sum_user_est = 0
        # sum_eve = 0
        # sec = 0
        for loop_index in 1:simulation_loop
            
            x_eve = rand(Uniform(1,39))
            y_eve = rand(Uniform(1,39))
            eve = [x_eve, y_eve, device_height]
            user_led_block = ones(user_num,led_num)
            # eve_led_block = ones(led_num)
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
                    user_psi_matrix[n,i] = phi_rad(
                        led[i,:],
                        user[n,:],
                        theta_deg("walk","opt"),
                        user_omega_deg[n])
                    user_psi_matrix_est[n,i] = phi_rad_est(
                        led[i,:],
                        user[n,:],
                        theta_mean
                    )
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
            
            # check the blockage of eve, not needed.
            # for i in 1:led_num
            #     eve_d_matrix[i] = norm(led[i,:]-eve)
            #     # eve_psi_matrix[i] = phi_rad(led[i,:],eve,theta_deg("walk","opt"),eve_omega_deg)
            #     # eve_theta_rad[i] = acos((height - device_height) / eve_d_matrix[i])


            #     # check block -- eve
            #     for n_body in 1:user_num
            #         # check if any user's body block
            #         if shadow_check(led[i,:],eve,user_body[n_body,:],shoulder_width) == 0.0
            #             eve_led_block[i] = 0.0
            #             break
            #         end
            #     end
            #     # check if eve's body block
            #     if shadow_check(led[i,:],eve,eve_body,shoulder_width) == 0.0
            #         eve_led_block[i] = 0.0
            #     end
            # end   
            
            
            h_user = zeros(user_num,led_num) 
            h_user_rec = zeros(user_num,led_num)
            h_user_est = zeros(user_num,led_num)
            β_sum_per_led = zeros(user_num,led_num)
            # initial the channel gain matrix
            capacity_user = 0
            capacity_user_est = 0
            for n in 1:user_num
                # set index of the user number

                # initial the SINR calculation
                # user_SINR = 0
                # eve_SINR = 0
                

                # user_num_per_led = zeros(led_num)
                # β_sum_per_led = zeros(led_num)
                
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
                        Nb,
                        η)

                    h_user_rec[n,i] = h_user[n,i] * user_led_block[n,i]

                    h_user_est[n,i] = vlc_channel(
                        user_psi_matrix_est[n,i],
                        deg2rad(ψ_c),
                        user_theta_rad[n,i],
                        deg2rad(ψ_05),
                        user_d_matrix[n,i],
                        A_PD,
                        Nb,
                        η
                    )
                    # Each floor set the NOMA rules based on user number in its coverage area

                    # user
                    # user_num_per_led[i] = length(filter(!iszero,h_user[:,i])) # get the usernumber of each led
                    user_indices_cache = findall(!iszero,h_user[:,i])


                    # for s in 1:user_num_per_led[i]
                    #     if s < user_num_per_led[i]
                    #         β_sum_per_led[i] = β * (1 - β)^(s-1)
                    #     else
                    #         β_sum_per_led[i] = (1 - β)^(s-1)
                    #     end
                    # end
                    # println(length(user_indices_cache))
                    # println((sum(h_user_est[user_indices_cache,:],dims=2) - h_user_est[user_indices_cache,i]))
                    # println(size(sum(h_user_est[user_indices_cache,:],dims=2)))
                    if length(user_indices_cache) >= 2
                        # println(1)
                        # println(vec(h_user_est[user_indices_cache,i]).^2)
                        # println(vec((sum(h_user_est[user_indices_cache,:],dims=2) - h_user_est[user_indices_cache,i])))
                        β_sum_per_led_temp = beta_optimal(
                            length(user_indices_cache),
                            vec(h_user_est[user_indices_cache,i]).^2,
                            vec((sum(h_user_est[user_indices_cache,:],dims=2) - h_user_est[user_indices_cache,i])).^2,
                            ps_real[ps_index],
                            n0
                        )
                        β_sum_per_led[user_indices_cache,i] = β_sum_per_led_temp
                    elseif length(user_indices_cache) > 0 && length(user_indices_cache) == 1
                        β_sum_per_led[user_indices_cache,i] = [1]
                    end
                end
                # select
                led_indice_user = argmax(h_user_rec[n,:]) # get the indice of maximum channel


                user_SINR = (h_user_rec[n,led_indice_user]^2 
                    * ps_real[ps_index] 
                    * β_sum_per_led[n,led_indice_user] 
                    / (h_user_rec[n,led_indice_user]^2 
                        * ps_real[ps_index] 
                        * sum(β_sum_per_led[n+1:user_num,led_indice_user])
                        + (sum(h_user_rec[n,:]) - h_user_rec[n,led_indice_user])^2 
                        * ps_real[ps_index] + n0))
                # println((1 - β)^(s - 1) - β_sum_per_led[i])

                capacity_user += 0.5 * log2(1 + user_SINR)
                

                user_est_SINR = (h_user_est[n,led_indice_user]^2 
                    * ps_real[ps_index] 
                    * β_sum_per_led[n,led_indice_user] 
                    / (h_user_est[n,led_indice_user]^2 
                        * ps[ps_index] 
                        * sum(β_sum_per_led[n+1:user_num,led_indice_user])
                        + (sum(h_user_est[n,:]) - h_user_est[n,led_indice_user])^2 
                        * ps_real[ps_index] + n0))

                capacity_user_est += 0.5 * log2(1 + user_est_SINR)
                
            end
            
            sum_user += capacity_user
            sum_user_est += capacity_user_est
            
            print("\r",
            "Ps = ", ps[ps_index],
            ", Trans_capacity_fact = ", sum_user / loop_index,
            ", Trans_capacity_est = ", sum_user_est / loop_index,
            ", Simulation Period = ", loop_index)
        end

        capacity_user_sum_simu[ps_index] = sum_user / simulation_loop
        capacity_user_est_sum_simu[ps_index] = sum_user_est / simulation_loop
        # capacity_eve_simu[x_index,y_index] = sum_eve / simulation_loop
        # secrecy_simu[x_index,y_index] = sec / simulation_loop
        print("\n")
    end

    # output file
    path = string("results/case2_trans_opt/Loop_num=", Int(simulation_loop), 
        "/Ps_max=", Float64(Ps_max), 
        "/user_type", u_type, "/")
    file_user = string("VLC_user_com.txt")
    file_user_est = string("VLC_user_est_com.txt")
    # file_eve = string("VLC_eve.txt")
    # file_sec = string("VLC_sec.txt")
    
    if ispath(path) == false
        mkpath(path)
    end
    cd(path)

    Output_2d(file_user, ps, length(ps), capacity_user_sum_simu)
    Output_2d(file_user_est, ps, length(ps), capacity_user_est_sum_simu)




end

# main()

if contains(@__FILE__, PROGRAM_FILE)
    main()
end