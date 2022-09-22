__precompile__()

module Parameters

    export ψ_c, ψ_05, I_DC, Nb

    ψ_c = 60
    ψ_05 = 70
    I_DC = 500
    # ζ = 1
    # ς = 1
    Nb = 1.0
    

    export u_r, A_PD, β
    u_r = 0.3
    A_PD = 1e-4
    β = 0.6

    export height, device_height
    height = 3.95
    device_height = 0.85

    export N0
    # trajectory_length = 120
    N0 = -98.82

    export height_user_body, shoulder_width, device_body
    height_user_body = 1.6
    shoulder_width = 0.2
    device_body = 0.4

    export x_eve, y_eve
    x_eve = 1:0.5:39
    y_eve = 1:0.5:39
end