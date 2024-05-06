using NaturalEarth
using Test

@testset "NaturalEarth.jl" begin
    # Write your tests here.
    @testset "Bathymetry" begin
        @test_throws "Available contours" bathymetry(10000000)
        # This also tests the whole pipeline...
        @test bathymetry(4000) isa NaturalEarth.GeoJSON.FeatureCollection
    end
    # This tests for an error in filename.
    @test_throws "404" naturalearth("asfhcsakdlfjnskfas")
end
