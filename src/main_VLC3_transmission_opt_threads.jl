# using libraries
using Base
using Base.Threads
using LinearAlgebra
using Distributions: Uniform
using ProgressBars


# local libraries
include("ProjectVLC.jl")

import .ProjectVLC.Channels: phi_rad, vlc_channel, theta_deg, shadow_check, phi_rad_est
import .ProjectVLC.Parameters: ψ_c, ψ_05, I_DC, Nb, u_r, A_PD, β, η, height, device_height, N0, height_user_body, shoulder_width, led, user_coop
import .ProjectVLC.FileOutput: Output_2d
import .ProjectVLC.FileInput: file_read
import .ProjectVLC.Algorithm: LED_selection
import .ProjectVLC.Functions: dbm2watt, parse_commandline
import .ProjectVLC.Optimal: beta_optimal



function main()
    parse_args = parse_commandline()
    Ps_max = parse(Float64, parse_args["power"]) # transmission power
    u_type = parse(Int64, parse_args["usertype"])
    simulation_loop = parse(Int64, parse_args["period"])

    led_num = size(led,1)
    user = user_coop(u_type)
    user_num = size(user,1)
    ps = 0.1:0.05:Ps_max
    n0 = dbm2watt(N0)

    theta_mean = 29.67

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
    
    
    s_group, user_group = LED_selection(user,user_num,led,led_num,height,device_height,ψ_c,"deg")



    for ps_index in eachindex(ps)

       
        # simulation
        sum_user = 0
        sum_user_est = 0
        # sum_eve = 0
        # sec = 0
        @threads for loop_index in ProgressBar(1:simulation_loop)
            
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
            
            # h_eve = zeros(led_num)
            # for i in 1:led_num
            #     # eve_d_matrix[i] = norm(led[i,:]-eve)
            #     # eve_psi_matrix[i] = phi_rad(led[i,:],eve,theta_deg("walk","opt"),eve_omega_deg)
            #     # eve_theta_rad[i] = acos((height - device_height) / eve_d_matrix[i])


            #     # check block -- eve
            #     for n in 1:user_num
            #         # check if any user's body block
            #         if shadow_check(led[i,:],eve,user_body[n,:],shoulder_width) == 0.0
            #             eve_led_block[i] = 0.0
            #             break
            #         end
            #     end
            #     # check if eve's body block
            #     if shadow_check(led[i,:],eve,eve_body,shoulder_width) == 0.0
            #         eve_led_block[i] = 0.0
            #     end

            #     # h_eve[i] = (vlc_channel(
            #     #     eve_psi_matrix[i],
            #     #     deg2rad(ψ_c),
            #     #     eve_theta_rad[i],
            #     #     deg2rad(ψ_05),
            #     #     eve_d_matrix[i],
            #     #     A_PD,
            #     #     Nb,
            #     #     η)
            #     #     * eve_led_block[i]
            #     # )
            # end   
            
            
            h_user = zeros(user_num,led_num) 
            h_user_rec = zeros(user_num,led_num)
            h_user_est = zeros(user_num,led_num)
            # β_sum_per_led = zeros(user_num,led_num)
            # initial the channel gain matrix
            capacity_user = 0
            capacity_user_est = 0
            # capacity_eve = 0
            for n in 1:user_num
                # set index of the user number

                # initial the SINR calculation
                # user_SINR = 0
                # eve_SINR = 0
                

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
                end
            end
            # Each floor set the NOMA rules based on user number in its coverage area

            # user
            # sum_h_eve = 0
            # for s in eachindex(user_group)
            #     sum_h_eve += sum(h_eve[s_group[s]])
            # end
            
            
            for s in eachindex(user_group)
                β_sum_per_group = zeros(length(user_group[s]))
                
                # println(user_group[s])
                if length(user_group[s]) >= 2
                    # println(length(user_group[s]))
                    # println(h_user_est[user_group[s],s_group[s]])
                    β_sum_per_group = beta_optimal(
                        length(user_group[s]),
                        vec(h_user_est[user_group[s],s_group[s]]).^2,
                        zeros(length(user_group[s])),
                        ps[ps_index],
                        n0
                    )
                elseif length(user_group[s]) == 1
                    β_sum_per_group = [1.0]
                end

                for b in 1:length(user_group[s])
                    # println(b)
                    # if b < length(user_group[s])
                    #     β_sum_per_group[b] = β * (1 - β)^(b-1)
                    # else
                    #     β_sum_per_group[b] = (1 - β)^(b-1)
                    # end
                
                    user_SINR = (sum(h_user_rec[user_group[s][b],s_group[s]])^2 
                        * ps[ps_index] 
                        * β_sum_per_group[b] 
                        / 
                        (sum(h_user_rec[user_group[s][b],s_group[s]])^2 
                            * ps[ps_index] 
                            * sum(β_sum_per_group[b+1:length(user_group[s])]) + n0))
                    # println(β_sum[b])
                    capacity_user += 0.5 * log2(1 + user_SINR)

                    user_est_SINR = (sum(h_user_est[user_group[s][b],s_group[s]])^2 
                    * ps[ps_index] 
                    * β_sum_per_group[b] 
                    / (sum(h_user_est[user_group[s][b],s_group[s]])^2 
                        * ps[ps_index] 
                        * sum(β_sum_per_group[b+1:length(user_group[s])]) + n0))
                    
                    capacity_user_est += 0.5 * log2(1 + user_est_SINR)
                
                    # eve
                    # eve_SINR = (sum(h_eve[s_group[s]])^2 * ps[ps_index] * β_sum[b]
                    # / (sum(h_eve[s_group[s]])^2 * ps[ps_index] * ((1-β)^(b-1) - β_sum[b])
                    # + (sum_h_eve - sum(h_eve[s_group[s]])) * ps[ps_index]
                    # + n0))
                    # capacity_eve += 0.5 * log2(1 + eve_SINR)
                end
            end
            
            sum_user += capacity_user        
            sum_user_est += capacity_user_est
            # sum_eve += capacity_eve
            # sec += max((capacity_user - capacity_eve), 0)
            # print("\r",
            # "Ps = ",ps[ps_index], 
            # ", Trans_capacity_fact = ", sum_user / loop_index,
            # ", Trans_capacity_est = ", sum_user_est / loop_index,
            # ", Simulation Period = ", loop_index)
        end
        print("Ps = ", ps[ps_index], 
            ", Trans_capacity_fact = ", sum_user / simulation_loop,
            ", Trans_capacity_est = ", sum_user_est / simulation_loop,
            ", Simulation Period = ", loop_index)

        capacity_user_sum_simu[ps_index] = sum_user / simulation_loop
        capacity_user_est_sum_simu[ps_index] = sum_user_est / simulation_loop
        # capacity_eve_simu[x_index,y_index] = sum_eve / simulation_loop
        # secrecy_simu[x_index,y_index] = sec / simulation_loop
        print("\n")
    end

    # output file
    path = string("results/case3_trans_opt/Loop_num=", Int(simulation_loop), 
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

    # Output_3d(file_eve, x_eve, length(x_eve), y_eve, length(y_eve), capacity_eve_simu)
    Output_2d(file_user, ps, length(ps), capacity_user_sum_simu)
    Output_2d(file_user_est, ps, length(ps), capacity_user_est_sum_simu)
    # Output_3d(file_sec, x_eve, length(x_eve), y_eve, length(y_eve), secrecy_simu)




end

# main()

if contains(@__FILE__, PROGRAM_FILE)
    main()
end