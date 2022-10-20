__precompile__()

module Optimal

    using Base, JuMP, Ipopt


    export beta_optimal
    function beta_optimal(user_num,h₍current₎,h₍others₎,Pₛ,N₀)
        
        K = user_num
        # m = mₖ(h₍current₎,h₍others₎,Pₛ,N₀)

        # Optimizer
        model = Model(Ipopt.Optimizer)
        MOI.set(model,MOI.Silent(), true) # no output display
        @variable(model, β[i = 1:K] >= 0)
        @constraint(model, sum(β) <= 1)
        for i in 1:K-1
            @constraint(model, β[i]>= β[i+1])
        end
        @NLobjective(model, Max,
            (sum(0.5 * log2(1 + 
            h₍current₎[i] * β[i] * Pₛ 
            / (sum(h₍current₎[i] * β[j] * Pₛ for j in i+1:K) 
            +
            h₍others₎
            + 
            N₀)) 
            for i in 1:K-1)
            +
            0.5 * log2(1 + h₍current₎[K] * β[K] * Pₛ 
            / (h₍others₎ + N₀)))
        )
        optimize!(model)
        # println(JuMP.value.(β))
        res = Array(JuMP.value.(β))
        return res
    end

    # function mₖ(∑h₍current₎,∑h₍others₎,Pₛ,N₀)
    #     return ∑h₍others₎ / ∑h₍current₎ + N₀ / (∑h₍current₎ * Pₛ)
    # end
end