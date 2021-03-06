#-----------------------------------------------------
# Start with nice coordinates x, y, z. Rotate
# them to get X, Y, Z. Compute g to check all your routines 
# Soham 04/2021
#-----------------------------------------------------

using FastSphericalHarmonics, LinearAlgebra, Test
using ForwardDiff, CairoMakie, Random
using StaticArrays

function rotate(x::T, y::T, z::T) where {T <: Real} 
    K  = eigen(A + A').vectors
    @assert eltype(K) <: Real
    @assert K' * K ≈ I
    x, y, z = K * [x, y, z]
    return (x, y, z)
end

function r′θ′ϕ′_of_rθϕ(coords::Array{T,1}) where {T<:Real}
    r,  θ,  ϕ  = coords 
    r′, θ′, ϕ′ = cartesian2spherical(rotate(spherical2cartesian(r, θ, ϕ)...)...)
    return [r′, θ′, ϕ′]
end

function xyz_of_rθϕ(coords::Array{T,1}) where {T<:Real}
    r,  θ,  ϕ  = coords 
    x, y, z = spherical2cartesian(r, θ, ϕ)
    return [x, y, z]
end

function x′y′z′_of_rθϕ(lmax::Int) 
    x = map((μ,ν)->xyz_of_rθϕ(r′θ′ϕ′_of_rθϕ([1.0,μ,ν]))[1], lmax) 
    y = map((μ,ν)->xyz_of_rθϕ(r′θ′ϕ′_of_rθϕ([1.0,μ,ν]))[2], lmax) 
    z = map((μ,ν)->xyz_of_rθϕ(r′θ′ϕ′_of_rθϕ([1.0,μ,ν]))[3], lmax) 
    return (x, y, z)
end

lmax = 3
Random.seed!(lmax)
A = rand(3,3)
qinverse = map(inv ∘ q, lmax)
xyz = x′y′z′_of_rθϕ(lmax) 
jac = jacobian(xyz..., lmax)
hinverse = transform(qinverse, jac)  
@test all(isdiagonal.(hinverse, 1e-12))

@test Z(π/6, π/5) ≈ 0.9208285738676726
@test det(h(π/4, π/19)) ≈ 0.6583073877333249

F¹ = map((μ,ν)->SVector{2}([cos(μ), sin(ν)]), lmax)
X  = map((μ,ν)->SVector{2}([μ, ν]), lmax)
qmetric = map(q, lmax)   
hmetric = map(h, lmax)   
# display(X[2,2])
# display(hmetric[2,2])
# display(map(S1, qmetric, hmetric, F¹)[2,2])
println("vector")
display(F¹[2,2])
println("lower")
display(map(lower, hmetric, F¹)[2,2])
println("raise")
display(map(raise, inv.(hmetric), F¹)[2,2])
println("S1")
display(map(S1, qmetric, hmetric, F¹)[2,2])
