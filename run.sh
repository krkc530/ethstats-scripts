#!/bin/bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_PATH=${__dir}/server.cfg

WS_PORT=3000
WS_SECRET="admin"
INSTANCE_NAME="node-instance"


usage() {
    echo "Usage: ./run.sh MODE [OPTIONS]"
    echo "Modes:"
    echo "  server              Run in server mode"
    echo "  client              Run in client mode"
    echo "Options:"
    echo "  --name=VALUE            Specify the docker container name (default: ethstats-server|ethstats-client)"
    echo "  --image-name=VALUE      Specify the docker image name (default: ethstats-server|ethstats-client)"
    echo "  --secret=VALUE          Specify the password for web socket communication (default: admin)"
    echo "  --port=VALUE            Specify the port for server container (default: 3000)"
    echo "  --instance-name=VALUES  Specify the instance name of client (default: node-instance)" 
    echo "  --rpc-host=VALUE        Specify the RPC host for client mode"
    echo "  --rpc-port=VALUE        Specify the RPC port for client mode"
}

# Parse command-line arguments
if [ "$1" == "client" ]; then
    # Client mode
    CONTAINER_NAME="ethstats-client"
    IMAGE_NAME="ethstats-client"
elif [ "$1" == "server" ]; then
    # Server mode
    CONTAINER_NAME="ethstats-server"
    IMAGE_NAME="ethstats-server"
else
    echo "Error: Invalid argument"
    usage
    exit 1
fi

BUILD_DIR="./${IMAGE_NAME}"

MODE="$1"
shift

# parse command-line arguments
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --name=*)
        CONTAINER_NAME="${key#*=}"
        shift
        ;;
        --image-name=*)
        IMAGE_NAME="${key#*=}"
        shift
        ;;
        --secret=*)
        WS_SECRET="${key#*=}"
        shift
        ;;
        --port=*)
        WS_PORT="${key#*=}"
        shift
        ;;
        --rpc-host=*)
        RPC_HOST="${key#*=}"
        shift
        ;;
        --rpc-port=*)
        RPC_PORT="${key#*=}"
        shift
        ;;
        --instance-name=*)
        INSTANCE_NAME="${key#*=}"
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

if [ "$MODE" == "client" ]; then 
    if [ -z "${RPC_HOST}" ]; then
        echo "RPC host not specified. Please provide the --rpc-host argument."
        exit 1
    fi

    if [ -z "${RPC_PORT}" ]; then
        echo "RPC port not specified. Please provide the --rpc-port argument."
        exit 1
    fi
fi

IS_IMAGE_EXIST=$(docker images -q ${IMAGE_NAME})

if [ -n "$IS_IMAGE_EXIST" ]; then
    # If image already exist
    echo "Docker image: ${IMAGE_NAME} was found"
else
    # If images does not exist, then build it
    echo "docker image: ${IMAGE_NAME} was not found"
    echo "now building..."
    cd ${BUILD_DIR}

    if ! npm install ; then
        echo "Error: Cannot install node packages"
        exit 1
    fi

    if ! docker build -t ${IMAGE_NAME} . ; then
        echo "Error: Cannot build docker image"
        exit 1
    else
        echo "Successfully build docker image: ${IMAGE_NAME}"
    fi
    cd ..
fi

IS_CONTAINER_EXIST=$(docker ps -aqf name=${CONTAINER_NAME})

if [ -n "$IS_CONTAINER_EXIST" ]; then
    # If container already exist
    echo "Docker container: ${CONTAINER_NAME} is already exist"
    read -r -p "Kill and restart container? [y/n]" response
    case "$response" in
        [yY][eE][sS]|[yY])
            echo "Stopping container..."
            docker stop ${CONTAINER_NAME}
            echo "Removing container..."
            docker rm ${CONTAINER_NAME}
            ;;
        *)
            echo "Terminating..."
            exit 1
            ;;
    esac
fi

CMD="docker run -d --name ${CONTAINER_NAME} -e "WS_SECRET=${WS_SECRET}" "
if [ "$MODE" == "server" ]; then
    CMD+="-e PORT=${WS_PORT} "
    CMD+="-p ${WS_PORT}:${WS_PORT} "
else 
    source $OUTPUT_PATH # read WS_SERVER, WS_SECRET
    CMD+="-e RPC_HOST=${RPC_HOST} "
    CMD+="-e RPC_PORT=${RPC_PORT} "
    CMD+="-e WS_SERVER=${WS_SERVER} "
    CMD+="-e INSTANCE_NAME=${INSTANCE_NAME} "
fi
CMD+=${IMAGE_NAME}

echo $CMD

echo "Starting docker container..."

if eval $CMD; then
        echo "Successfully start docker container: ${CONTAINER_NAME}"
    else
        echo "Error: Cannot start docker container: ${CONTAINER_NAME}"
fi

if [ "$MODE" == "server" ]; then
    # Only in server mode
    WS_HOST=`docker inspect -f "{{ .NetworkSettings.IPAddress }}" ${CONTAINER_NAME}`
    echo "Opened server: ${WS_HOST}:${WS_PORT}"
    echo "WS_SERVER=http://${WS_HOST}:${WS_PORT}" > ${OUTPUT_PATH}
    echo "WS_SECRET=${WS_SECRET}" >> ${OUTPUT_PATH}
fi