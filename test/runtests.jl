using JuliaOnLambda
using AWS.AWSExceptions: AWSException
using HTTP: Response, StatusError
using Mocking
using Test

Mocking.activate()

include("patches.jl")

@testset "JuliaOnLambda.jl" begin
    @testset "_get_create_ecr_repo" begin
        @testset "repo exists" begin
            apply(describe_repository_exists_patch) do
                response = JuliaOnLambda._get_create_ecr_repo("foobar")

                @test response == REPO_URL
            end
        end

        @testset "repo dne" begin
            apply([describe_repository_dne_patch, create_repository_patch]) do
                response = JuliaOnLambda._get_create_ecr_repo("foobar")

                @test response == REPO_URL
            end
        end

        @testset "alternative error" begin
            apply([describe_repository_dne_patch, create_repository_failure_patch]) do
                @test_throws AWSException JuliaOnLambda._get_create_ecr_repo("foobar")
            end
        end
    end
end
