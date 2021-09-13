module JuliaOnLambda

using AWS
using Mocking

@service ECR

const REPO_NOT_FOUND_EXCEPTION = "RepositoryNotFoundException"

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

end
