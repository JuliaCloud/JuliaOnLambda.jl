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
    image::AbstractString,
    tag::AbstractString;
    dockerfile_path::AbstractString=DEFAULT_DOCKERFILE,
)
    image_uri = _image_uri(image, tag)

    _build_docker_image(image_uri; dockerfile_path=dockerfile_path)

    return nothing
end

function _tag_docker_image(
    image::AbstractString, tag::AbstractString, repository_uri::AbstractString
)
    return run(`docker tag $(image):$(tag) $repository_uri`)
end

"""
Upload Docker image
"""
function _upload_docker_image(repository_name::AbstractString)
    return run(`docker push $repository_name`)
end

end
