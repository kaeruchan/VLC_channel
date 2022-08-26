__precompile__()

module Channel

    import Base
    import Distributions: Laplace, Gaussian
    import LinearAlgebra: cross, dot
    export vlc_channel

    function vlc_channel(psi::Float64, Psi_c::Float64, phi::Float64, phi_1_2::Float64, d::Float64, A::Float64, N_b::Float64)
        m = -log(2) / log(cos(phi_1_2))
        rect = (psi >= 0 && psi <= Psi_c ? 1.0 : 0.0)
        return (m+1) * A * N_b / 2 * pi * d^2 * cos(phi)^m * cos(psi) * rect
    end

    export theta_deg

    function theta_deg(type::String, type_fit::String = "opt")

        #=
            The angle measurement based on Soltani's paper.
            M. D. Soltani, A. A. Purwita, Z. Zeng, H. Haas, and M. Safari, 
            ``Modeling the random orientation of mobile devices: Measurement, analysis and LiFi use case,''
            IEEE Trans. Commun., vol. 67, no. 3, pp. 2157- 2172, Mar. 2019.
        =#
        laplace_mean_sit = 41.39
        laplace_var_sit = 7.68
        laplace_mean_walk = 29.74
        laplace_var_walk = 8.59
        gaussian_mean_sit = 41.23
        gaussian_var_sit = 7.18
        gaussian_mean_walk = 29.67
        gaussian_var_walk = 7.78

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

    export shadow_check

    function shadow_check(source::Array, device::Array, user::Array, radius_user::Float64)
        #=
            The function check whether shadow blocked.
        =#
        theta = atan(abs(device[2] - source[2]) / abs(device[1] - source[1]))

        r = radius_user

        result = 1

        B1 = Array{Float64}([user[1] + r * cos(theta), user[2] - r * sin(theta), user[3]])
        B2 = Array{Float64}([user[1] - r * cos(theta), user[2] + r * sin(theta), user[3]])
        B3 = Array{Float64}([user[1] - r * cos(theta), user[2] + r * sin(theta), 0])
        B4 = Array{Float64}([user[1] + r * cos(theta), user[2] - r * sin(theta), 0])

        s_d_vector = (device - source) ./ (sqrt(sum(abs2, device-source)))

        norm_vec_user_h = Array([0,0,1])

        norm_vec_user_v = copy(s_d_vector)
        norm_vec_user_v[3] = 0

        # intersection
        s_d_vector = device - source
        P1 = _dot_coordination(device, user, s_d_vector, norm_vec_user_h)
        P2 = _dot_coordination(device, user, s_d_vector, norm_vec_user_v)

        # judge
        if (P1[1] - user[1]) ^ 2 + (P1[2] - user[2]) ^ 2 < r ^ 2
            result = 0
        elseif dot(cross((B2 - B1),(P2 - B1)),cross((B4 - B3), (P2 - B3))) >= 0 && dot(cross((B2 - B1), (P2 - B1)), cross((B4 - B3), (P2 - B3))) >= 0
            result = 0
        else
            result = 1
        end
        return result
    end

    function _dot_coordination(m::Array{Float64}, n::Array{Float64}, vl::Array{Float64}, vp::Array{Float64})
        MN = n - m
        P = M + vl * (MN * vp / vp * vl)
        return P
    end
end

import ..Channel: theta_deg

println(theta_deg("walk"))