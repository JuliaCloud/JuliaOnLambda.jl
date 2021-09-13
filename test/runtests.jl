using JuliaOnLambda
using AWS.AWSExceptions: AWSException
using HTTP: Response, StatusError
using Mocking
using Test

Mocking.activate()

include("patches.jl")

function docker_rmi(name::AbstractString)
    return read(`docker rmi $(name)`)
end

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

    @testset "_build_docker_image" begin
        image_name = "julia-on-lambda-test-"
        image_count = 0

        function get_image_name()
            image_count += 1
            return string(image_name, image_count)
        end

        function image_exists(image_name::AbstractString)
            result = read(`docker images --format "{{.Repository}}"`, String)
            result = string.(split(result, "\n"))

            return image_name in result
        end

        @testset "default kwargs" begin
            try
                image_name = get_image_name()
                JuliaOnLambda._build_docker_image(image_name)
                @test image_exists(image_name)
            finally
                docker_rmi(image_name)
            end
        end

        @testset "dockerfile_path set" begin
            dockerfile_path = joinpath(@__DIR__, "resources", "Dockerfile")

            try
                image_name = get_image_name()
                JuliaOnLambda._build_docker_image(
                    image_name; dockerfile_path=dockerfile_path
                )
                @test image_exists(image_name)
            finally
                docker_rmi(image_name)
            end
        end
    end
end
