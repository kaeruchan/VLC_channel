__precompile__()

module Parameters

    include("File.jl")
    import .FileInput: file_read, file_read_com
    export ψ_c, ψ_05, I_DC, Nb, u_r, A_PD, β, η
    export height, device_height
    export N0
    export height_user_body, shoulder_width, device_body
    export x_eve, y_eve
    export led, user_coop, led_com, led_com_to_led_ratio

    using Base: fill

    ψ_c = 60
    ψ_05 = 70
    I_DC = 500
    # ζ = 1
    # ς = 1
    Nb = 1.0
    η = 1.5

    u_r = 0.3
    A_PD = 1e-4
    β = 0.6

    height = 4
    device_height = 0.85

    
    # trajectory_length = 120
    N0 = -98.82

    
    height_user_body = 1.6
    shoulder_width = 0.2
    device_body = 0.4

    x_eve = 1:0.5:39
    y_eve = 1:0.5:39

    led = hcat(file_read("led"),fill(height,size(file_read("led"),1)))

    led_com = hcat(file_read_com("led"),fill(height,size(file_read_com("led"),1)))

    led_com_to_led_ratio = size(led,1) / size(led_com,1)

    function user_coop(usr_type::Int64)
        return hcat(file_read("user", user_type=usr_type),fill(device_height,size(file_read("user", user_type=usr_type),1)))
    end

end