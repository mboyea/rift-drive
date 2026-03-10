{
  pkgs,
  image,
  mkContainer,
}: mkContainer {
  imageName = image.name;
  imageTag = image.tag;
  imageStream = image.stream;
  podmanArgs = [
    "--publish" "9000:9000"
    "--publish" "9001:9001"
    "--env" "MINIO*"
    "--volume" "${image.name}:/data"
    "--name" image.name
  ];
  ensureStopOnExit = true;
  useInteractiveTTY = false;
  preStart = ''
    if ! podman volume exists "${image.name}" > /dev/null 2>&1; then
      podman volume create "${image.name}"
    fi
  '';
  postStop = ''
  '';
}

