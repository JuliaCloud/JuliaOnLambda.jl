module JuliaOnLambda

using AWS
using JSON
using Mocking
using UUIDs

@service IAM
@service ECR
@service Lambda

const DEFAULT_PROJECT_PATH = joinpath(@__DIR__, "..")
const DEFAULT_DOCKERFILE = joinpath(DEFAULT_PROJECT_PATH, "Dockerfile")
const REPO_NOT_FOUND_EXCEPTION = "RepositoryNotFoundException"
const DEFAULT_LAMBDA_POLICY = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

const DEFAULT_LAMBDA_PARAMS = Dict{String, Any}(
    "PackageType" => "Image",
    "Publish" => "true",
    "MemorySize" => 4096,  # 4GB
    "Timeout" => 300,  # 5 minutes
)

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

    return image_uri
end

function _tag_docker_image(
    image::AbstractString, tag::AbstractString, repository_uri::AbstractString
)
    return run(`docker tag $(image):$(tag) $repository_uri`)
end

"""
Upload Docker image
"""
function _upload_docker_image(repository_name::AbstractString; tag::AbstractString="latest")
    run(`docker push $repository_name`)
    return "$repository_name:$(tag)"
end

"""
Create the Lambda function
"""
function _create_lambda_function(
    lambda_function_name::AbstractString,
    docker_arn::AbstractString;
    role_arn::Union{AbstractString, Nothing}=nothing,
    lambda_optional_parameters::Dict{String, <:Any}=Dict{String, Any}()
)
    role_name = "JuliaOnLambda-" * string(UUIDs.uuid4())

    if role_arn === nothing
        assume_role_policy_document = Dict(
            "Version" => "2012-10-17",
            "Statement" => [
                Dict(
                    "Effect" => "Allow",
                    "Principal" => Dict("Service" => "lambda.amazonaws.com"),
                    "Action" => "sts:AssumeRole"
                )
            ]
        )
        assume_role_policy_document = JSON.json(assume_role_policy_document)

        role_arn = IAM.create_role(assume_role_policy_document, role_name)["CreateRoleResult"]["Role"]["Arn"]
        IAM.attach_role_policy(DEFAULT_LAMBDA_POLICY, role_name)
    end

    sleep(8)  # We need to wait for AWS until we can use this role

    resp = Lambda.create_function(
        Dict("ImageUri" => docker_arn),
        lambda_function_name,
        role_arn,
        mergewith(_merge, DEFAULT_LAMBDA_PARAMS, lambda_optional_parameters)
    )

    return resp["FunctionArn"], role_name
end

end
