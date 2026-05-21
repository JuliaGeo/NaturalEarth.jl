using NaturalEarth
using Test
import Downloads

@testset "NaturalEarth.jl" begin
    @testset "Bathymetry" begin
        @test_throws ErrorException bathymetry(10000000)
        # This also tests the whole pipeline...
        @test bathymetry(4000) isa NaturalEarth.GeoJSON.FeatureCollection
    end
    # This tests for an error in filename.
    @test_throws Downloads.RequestError naturalearth("asfhcsakdlfjnskfas")
    @testset "set_mirror!" begin
        @test_throws ArgumentError set_mirror!("bogus")
        @test Set(keys(NaturalEarth.MIRROR_URLS)) == Set(["githack", "github"])
    end
end
