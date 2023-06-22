# Containerized Firefox on Fedora

A fully operational, containerized Firefox. While communication between the container and the host utilizes X11 it integrates into Wayland through XWayland.
The container is based on Fedora:latest and installs the latest version of Firefox. 

Yes, native Wayland support is on my ToDo list. I promise!

## Pulling the Prebuild Image

An automatic build of the image is triggered every 7 days to incorporated the latest updates for Fedora and Firefox. The history for the latest prebuild image can be found at [Quay.io](https://quay.io/repository/rh_ee_bgrossew/firefox?tab=history).

To pull the image using podman, execute:

``` bash
podman pull quay.io/rh_ee_bgrossew/firefox
```

## Build the Image

### Example ``podman build`` Command

#### Build Parameters

| Parameter              | Values                       | Description | Optional |
| ---------------------- | ---------------------------- | ----------- | -------- |
| $ADDITIONAL_CERTS_PATH | absolute path                | path to a folder containing PEM formated certificates that should be added to firefox trusted certificates     | yes      |
| $HOMEPAGES            | space separated list of URLs | URLs to Websites Firefox should open on startup                                                               | yes      |

``` bash
ADDITIONAL_CERTS_PATH=~/trustanchors
HOMEPAGES="https://www.redhat.com https://www.google.com"

podman build . \
    -v $ADDITIONAL_CERTS_PATH:/mnt/trustanchors:ro,z \
    --build-arg HOMEPAGES=$HOMEPAGES \
    -t firefox_demo
```

### Explanation 

## Run the Container

### Example ``podman run`` Command
``` bash
podman run -it --rm \
    -v $XAUTHORITY:$XAUTHORITY:ro \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    --userns keep-id \
    --workdir=/tmp \
    -e "DISPLAY" \
    --ipc=host \
    --security-opt label=type:container_runtime_t firefox
```

#### Explanation

| Argument                                      | What | Why | Optional |
| --------------------------------------------- | ---- | --- | ---------|
| -v $XAUTHORITY:$XAUTHORITY:ro                 | mount XAUTHORITY Cookie as volume | so web can authenticate against X                                       | no       |
| -v /tmp/.X11-unix:/tmp/.X11-unix:ro           | X11 Zeug halt  | damit X geht | no |
| --userns keep-id                              | run the container process with the id of the current user | duh | ye..no | 
| --workdir=/tmp                                | set working directory || ??? |
| -e "DISPLAY"                                  |            | what do you think?| no |
| --ipc=host                                    | Inter Process Communication        | and there goes the isolation...| yes | 
| --security-opt label=type:container_runtime_t | Set SELinux Label | so it would work| SELinux only|

## Internals

### Trustanchor

### Firefox Policy

