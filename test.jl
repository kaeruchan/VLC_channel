using Base.Threads
using Distributions: Gaussian
using ProgressBars
ids = zeros(1000)
res = zeros(length(ids))
# ato = Atomic{Int}(0)


res_origin = zeros(length(ids))
@threads for i in ProgressBar(eachindex(ids))
    # res_origin[i] = i

    # res_origin[i] = Threads.atomic_add!(ato,i)
    # println("After")
    # println(i)
    # res[i] = rand(Gaussian(0,1))
    ids[i] = i
    # println(ids)
end
# println(res_origin)
# println(ids)