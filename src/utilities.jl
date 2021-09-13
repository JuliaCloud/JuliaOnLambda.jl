function _image_uri(
    repository_uri::AbstractString, image::AbstractString, tag::AbstractString
)
    return "$(joinpath(repository_uri, image)):$(tag)"
end

function _build_docker_image(
    image_uri::AbstractString; dockerfile_path::AbstractString=DEFAULT_DOCKERFILE
)
    cmd = ["docker", "build", "-t", image_uri, "-f", dockerfile_path]

    # Set the appropriate build context
    if dockerfile_path == DEFAULT_DOCKERFILE
        push!(cmd, DEFAULT_PROJECT_PATH)
    else
        # Remove Dockerfile from the path provided, and use that directory for build context
        push!(cmd, dirname(dockerfile_path))

    run(Cmd(cmd))

    return nothing
end
