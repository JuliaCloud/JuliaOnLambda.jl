module JuliaOnLambda

using AWS
using Mocking

@service ECR

const DEFAULT_PROJECT_PATH = joinpath(@__DIR__, "..")
const DEFAULT_DOCKERFILE = joinpath(DEFAULT_PROJECT_PATH, "Dockerfile")
const REPO_NOT_FOUND_EXCEPTION = "RepositoryNotFoundException"

include("utilities.jl")

"""
Get the ECR Repo called `repository_name`. If it does not exist, create a new one.
"""
function _get_create_ecr_repo(repository_name::AbstractString)
    try
        response = @mock ECR.describe_repositories(
            Dict("repositoryNames" => [repository_name])
        )
        return response["repositories"][1]["repositoryUri"]
    catch e
        if e.code == REPO_NOT_FOUND_EXCEPTION
            @info "Creating ECR repository, $repository_name"
            response = @mock ECR.create_repository(repository_name)
            return response["repository"]["repositoryUri"]
        else
            rethrow(e)
        end
    end
end

"""
Build and tag the Docker image.
"""
function _create_docker_image(
    repository_name::AbstractString,
    image::AbstractString,
    tag::AbstractString;
    dockerfile_path::AbstractString=DEFAULT_DOCKERFILE,
)
    repository_uri = _get_create_ecr_repo(repository_name)
    image_uri = _image_uri(repository_uri, image, tag)

    _build_docker_image(image_uri; dockerfile_path=dockerfile_path)

    return nothing
end

end
