__precompile__()

include("File.jl")

using Base
using LinearAlgebra: cross, dot, norm
import .FileOutput: Output_2d

# Function libraries 
function shadow_check(source, device, UserCoorTop, radius_user::Float64)
    #=
        The function check whether shadow blocked.
    =#
    
    
    theta = atan(abs(device[2] - source[2]) / abs(device[1] - source[1]))

    r = radius_user

    result = 1

    B1 = Array{Float64}([UserCoorTop[1] + r * cos(theta), 
        UserCoorTop[2] - r * sin(theta), 
        UserCoorTop[3]])
    B2 = Array{Float64}([UserCoorTop[1] - r * cos(theta), 
    UserCoorTop[2] + r * sin(theta), UserCoorTop[3]])
    B3 = Array{Float64}([UserCoorTop[1] - r * cos(theta), UserCoorTop[2] + r * sin(theta), 0])
    B4 = Array{Float64}([UserCoorTop[1] + r * cos(theta), UserCoorTop[2] - r * sin(theta), 0])

    s_d_vector = (device - source) ./ (sqrt(sum(abs2, device-source)))

    norm_vec_user_h = Array([0,0,1])

    norm_vec_user_v = copy(s_d_vector)
    norm_vec_user_v[3] = 0

    # intersection
    s_d_vector = device - source
    P1 = _dot_coordination(device, UserCoorTop, s_d_vector, norm_vec_user_h)
    P2 = _dot_coordination(device, UserCoorTop, s_d_vector, norm_vec_user_v)

    # judge
    if (P1[1] - UserCoorTop[1]) ^ 2 + (P1[2] - UserCoorTop[2]) ^ 2 < r ^ 2
        result = 0
    elseif dot(cross((B2 - B1),(P2 - B1)),cross((B4 - B3), (P2 - B3))) >= 0 && dot(cross((B2 - B1), (P2 - B1)), cross((B4 - B3), (P2 - B3))) >= 0
        result = 0
    else
        result = 1
    end
    return result
end

function _dot_coordination(m, n, vl, vp)
    MN = n - m
    P = m + vl * (dot(MN,vp) / dot(vp,  vl))
    # println("vl=")
    # println(vl)
    # println("vp=")
    # println(vp)
    return P
end

function vlc_channel(ψ::Float64, Ψ::Float64, θ::Float64, θ₀₅::Float64, d::Float64, A::Float64, Nb::Float64, η::Float64)
    m = -log(2) / log(cos(θ₀₅))
    rect = (ψ >= 0 && ψ <= Ψ ? 1.0 : 0.0)
    return (m+1) * A * Nb / (2 * pi * d^2) * cos(θ)^m * cos(ψ) * rect * η^2 / sin(Ψ)^2
end

function phi_rad(
    led_location,
    user_location,
    theta_deg,
    omega_deg)

    # generate theta_deg variance
    # theta_rad = deg2rad(theta_deg(type,type_fit))
    # theta_rad = deg2rad(theta_deg)
    # omega_rad = deg2rad(omega_deg())
    # omega_rad = deg2rad(omega_deg)
    dist = norm(led_location - user_location)

    phi = acos(
        (led_location[1] - user_location[1]) / dist 
        * sind(theta_deg) * cosd(omega_deg) 
        + 
        (led_location[2] - user_location[2]) / dist 
        * sind(theta_deg) * sind(omega_deg)
        +
        (led_location[3] - user_location[3]) / dist
        * cosd(theta_deg))
    return phi
end

function main()
    LED = [0.0,0.0,5.0]
    User = [3,3,1.6]
    l_d = [0.4,0.5,0.6]
    r = 0.2
    z_d = 1.6
    ϕ = 0:1:360
    θ = 29.67
    θ_05 = 60.0
    u = zeros(length(ϕ))
    h = zeros(length(ϕ))
    Ψ = 70.0
    for l_d_index in eachindex(l_d)
        for ϕᵢ in eachindex(ϕ)
            device = [User[1] + l_d[l_d_index] * cosd(ϕ[ϕᵢ]),User[2] + l_d[l_d_index] * sind(ϕ[ϕᵢ]),z_d]
            u[ϕᵢ] = shadow_check(LED,device,User,r)
            ψ = phi_rad(LED,User,θ,ϕ[ϕᵢ])
            h[ϕᵢ] = vlc_channel(ψ,deg2rad(Ψ),deg2rad(θ),deg2rad(θ_05),norm(LED-device),1e-4,1.0,1.5) * u[ϕᵢ] + 1e-20
            println(u[ϕᵢ])
        end


        path = string("temp33/l_d=", Float16(l_d[l_d_index]),"/")
        file_result = string("sougou.txt")

        if ispath(path) == false
            mkpath(path)
        end
        cd(path)

        Output_2d(file_result, ϕ, length(ϕ), h)
        cd("../..")
    end

end

if contains(@__FILE__, PROGRAM_FILE)
    main()
end
