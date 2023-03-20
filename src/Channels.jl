__precompile__()

module Channels

    import Base
    import Distributions: Laplace, Gaussian, Uniform
    import LinearAlgebra: cross, dot, norm

    export vlc_channel

    function vlc_channel(ψ::Float64, Ψ::Float64, θ::Float64, θ₀₅::Float64, d::Float64, A::Float64, Nb::Float64, η::Float64)
        m = -log(2) / log(cos(θ₀₅))
        rect = (ψ >= 0 && ψ <= Ψ ? 1.0 : 0.0)
        return (m+1) * A * Nb / (2 * pi * d^2) * cos(θ)^m * cos(ψ) * rect * η^2 / sin(Ψ)^2
    end

    export phi_rad

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

    export phi_rad_est

    function phi_rad_est(
        led_location,
        user_location,
        theta_deg)
        dist = norm(led_location - user_location)
        height = (led_location[3] - user_location[3])

        psi_deg = acosd(height/dist)
        phi_deg = abs(psi_deg - theta_deg)

        phi = deg2rad(phi_deg)
        
        return phi
    end


    export theta_deg

    function theta_deg(type::String, type_fit::String = "opt")

        #=
            The polar angle based on Soltani's paper.
            M. D. Soltani, A. A. Purwita, Z. Zeng, H. Haas, and M. Safari, 
            ``Modeling the random orientation of mobile devices: Measurement, analysis and LiFi use case,''
            IEEE Trans. Commun., vol. 67, no. 3, pp. 2157- 2172, Mar. 2019.
        =#
        laplace_mean_sit = 41.39
        laplace_var_sit = 7.68^2
        laplace_mean_walk = 29.74
        laplace_var_walk = 8.59^2
        gaussian_mean_sit = 41.23
        gaussian_var_sit = 7.18^2
        gaussian_mean_walk = 29.67
        gaussian_var_walk = 7.78^2

        wrong_type_msg = "Wrong type! Please fix it."
        wrong_fit_msg = "Wrong fit type! Please fix it."
        if type_fit == "opt"
            if type == "sit"
                return rand(Laplace(laplace_mean_sit, laplace_var_sit))
            elseif type == "walk"
                return rand(Gaussian(gaussian_mean_walk, gaussian_var_walk))
            else
                throw(DomainError(type, wrong_type_msg))
            end
        elseif type_fit == "sit"
            if type == "sit"
                mean = gaussian_mean_sit
                var = gaussian_var_sit
            elseif type == "walk"
                mean = gaissian_mean_walk
                var = gaussian_var_walk
            else
                throw(DomainError(type, wrong_type_msg))
            end
            return rand(Gaussian(mean,var))
        elseif type_fit == "laplace"
            if type == "sit"
                mean = laplace_mean_sit
                var = laplace_var_sit
            elseif type == "walk"
                mean = laplace_mean_walk
                var = laplace_var_walk
            else
                throw(DomainError(type, wrong_type_msg))
            end
            return rand(Laplace(mean, var))
        else
            throw(DomainError(type_fit, wrong_fit_msg))
        end
    end

    export omega_deg

    function omega_deg()
        return rand(Uniform(-180,180))
    end

    export shadow_check

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
end

# import ..Channel: theta_deg

# println(theta_deg("walk"))