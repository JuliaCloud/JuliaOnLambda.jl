const REPO_URL = "000000000000.dkr.ecr.us-east-1.amazonaws.com/foobar"
const RESPONSE = Response(400, "foobar")
const STATUS_ERROR = StatusError(400, "foo", "bar", RESPONSE)

describe_repository_exists_patch = @patch function JuliaOnLambda.ECR.describe_repositories(
    params
)
    return Dict("repositories" => [Dict("repositoryUri" => REPO_URL)])
end

describe_repository_dne_patch = @patch function JuliaOnLambda.ECR.describe_repositories(
    params
)
    return throw(
        AWSException(
            JuliaOnLambda.REPO_NOT_FOUND_EXCEPTION, "foobar", nothing, STATUS_ERROR
        ),
    )
end

create_repository_patch = @patch function JuliaOnLambda.ECR.create_repository(
    repository_name
)
    return Dict("repository" => Dict("repositoryUri" => REPO_URL))
end

create_repository_failure_patch = @patch function JuliaOnLambda.ECR.create_repository(
    repository_name
)
    return throw(AWSException("Alternative Error", "foobar", nothing, STATUS_ERROR))
end
