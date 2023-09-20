#!/bin/bash

IMAGE_REMOVE=false

usage() {
    echo "Usage: ./reset.sh [OPTIONS]"
    echo "Options:"
    echo "  --images                        Remove docker images for ethstats-server, ethstats-client"
    echo "  --image-name-server=VALUE      Specify the server docker image name to be removed (default: ethstats-server)"
    echo "  --image-name-client=VALUE      Specify the client docker image name to be removed (default: ethstats-client)"
}

# parse command-line arguments
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --images)
        IMAGE_REMOVE=true
        shift
        ;;
        --image-name-server=*)
        IMAGE_NAME_SERVER="${key#*=}"
        shift
        ;;
        --image-name-client=*)
        IMAGE_NAME_CLIENT="${key#*=}"
        shift
        ;;
        --help)
        # Display script usage
        usage
        exit 0
        ;;
        *)
        # ignore unrecognized arguments
        shift
        ;;
    esac
done

if [ -z "${IMAGE_NAME_CLIENT}" ]; then
    echo "Client image name is not specified, using default: ethstats-client"
    IMAGE_NAME_CLIENT="ethstats-client"
fi
if [ -z "${IMAGE_NAME_SERVER}" ]; then
    echo "Server image name is not specified, using default: ethstats-server"
    IMAGE_NAME_SERVER="ethstats-server"
fi

echo "Removing server config file..."
rm server.cfg

echo "Stopping containers, this may take a while..."
docker stop $(docker ps -aqf ancestor=${IMAGE_NAME_CLIENT})
docker stop $(docker ps -aqf ancestor=${IMAGE_NAME_SERVER})

echo "Removing containers..."
docker rm $(docker ps -aqf ancestor=${IMAGE_NAME_SERVER})
docker rm $(docker ps -aqf ancestor=${IMAGE_NAME_CLIENT})

if [ "${IMAGE_REMOVE}" = true ]; then
    echo "Removing images..."
    docker rmi ${IMAGE_NAME_SERVER}
    docker rmi ${IMAGE_NAME_CLIENT}
fi

echo "Reset done!"