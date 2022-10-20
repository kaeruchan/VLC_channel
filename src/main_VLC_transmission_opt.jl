__precompile__()


# using libraries
using Base
using ArgParse
using LinearAlgebra
using Distributions: Uniform
# local libraries
include("ProjectVLC.jl")

import .ProjectVLC.Channels: phi_rad, vlc_channel, theta_deg, shadow_check, phi_rad_est
import .ProjectVLC.Parameters: ψ_c, ψ_05, I_DC, Nb, u_r, A_PD, β, η, height, device_height, N0, height_user_body, shoulder_width, led, user_coop
import .ProjectVLC.FileOutput: Output_2d
import .ProjectVLC.Functions: dbm2watt, parse_commandline
import .ProjectVLC.Optimal: beta_optimal


function main()
    parse_args = parse_commandline()
    Ps_max = parse(Float64, parse_args["power"]) # transmission power
    u_type = parse(Int64, parse_args["usertype"])
    simulation_loop = parse(Int64, parse_args["period"])

    user = user_coop(u_type)
    user_num = size(user,1)
    led_num = size(led,1)
    # eve_init = [5,5,0.85]
    # Power = 10.0 # dbm
    # power = dbm2watt(Power)
    ps = 0.1:0.05:Ps_max
    n0 = dbm2watt(N0)

    theta_mean = 29.67

    capacity_user_sum_simu = zeros(length(ps))
    capacity_user_est_sum_simu = zeros(length(ps))
    # capacity_eve_simu = zeros(length(ps))
    # secrecy_simu = zeros(length(ps))

    user_d_matrix = zeros(user_num,led_num)
    user_psi_matrix = zeros(user_num,led_num)
    user_psi_matrix_est = zeros(user_num,led_num)
    user_body = zeros(user_num,3)
    user_theta_rad = zeros(user_num,led_num)
    eve_body = zeros(3)
        
    for ps_index in eachindex(ps)
        # simulation
        
        sum_user = 0
        sum_user_est = 0
        for loop_index in 1:simulation_loop
            
            x_eve = rand(Uniform(1,39))
            y_eve = rand(Uniform(1,39))
            eve = [x_eve,y_eve,device_height]
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
            
            for i in 1:led_num
                eve_d_matrix[i] = norm(led[i,:]-eve)
                # eve_psi_matrix[i] = phi_rad(led[i,:],eve,theta_deg("walk","opt"),eve_omega_deg)
                # eve_theta_rad[i] = acos((height - device_height) / eve_d_matrix[i])


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

            
            
            

            
            h_user = zeros(user_num,led_num)
            h_user_est = zeros(user_num,led_num)
            capacity_user = 0
            capacity_user_est = 0
            for n in 1:user_num

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

                    h_user_est[n,i] = vlc_channel(
                        user_psi_matrix[n,i],
                        deg2rad(ψ_c),
                        user_theta_rad[n,i],
                        deg2rad(ψ_05),
                        user_d_matrix[n,i],
                        A_PD,
                        Nb,
                        η)
                end
            end
            β = beta_optimal(
                user_num,
                sum(h_user_est,dims=2),
                0,
                ps[ps_index],
                n0)
            
            # println(β)

            for n in 1:user_num
                
                
            
                user_SINR = (sum(h_user[n,:])^2 * ps[ps_index] * β[n]
                / (sum(h_user[n,:])^2 * ps[ps_index] * sum(β[n+1:user_num]) + n0))
                # println(user_SINR)
                capacity_user += 0.5 * log2(1 + user_SINR)

                user_est_SINR = (sum(h_user_est[n,:])^2 * ps[ps_index] * β[n]
                / (sum(h_user_est[n,:])^2 * ps[ps_index] * sum(β[n+1:user_num]) + n0))

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
        print("\n")
    end

    # output file
    path = string("results/case1_trans_opt/Loop_num=", Int(simulation_loop), 
        "/Ps_max=", Float64(Ps_max), 
        "/user_type", u_type, "/")
    file_user = string("VLC_user.txt")
    file_user_est = string("VLC_user_est.txt")
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