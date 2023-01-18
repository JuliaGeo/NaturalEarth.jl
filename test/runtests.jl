using NaturalEarth
using Test

@testset "NaturalEarth.jl" begin
    # Write your tests here.
    @testset "Bathymetry" begin
        @test_throws "Available contours" bathymetry(10000000)
        @test_nowarn bathymetry(4000)
    end
end
