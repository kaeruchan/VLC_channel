__precompile__()

module ProjectVLC

    using Requires
    include("Channels.jl")
    include("Parameters.jl")
    include("File.jl")
    include("Functions.jl")
    include("Optimal.jl")
end
