#!/bin/bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH=${__dir}/nodes.cfg

source $CONFIG_PATH

echo "Notice: Set environment variables in nodes.cfg (i.e., NODE1_HOST="*.*.*.*", NODE1_PORT="8545")"

PORT=3000

usage() {
    echo "Usage: ./run_all.sh [OPTIONS]"
    echo "Options:"
    echo "  --port=VALUE    Specify the server port to be exposed (default: ${PORT})"
}

# parse command-line arguments
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --port=*)
        PORT="${key#*=}"
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

echo "Run server..."
if ! ./run.sh server --port=${PORT}; then
    echo "Error: Cannot start server container"
    exit 1
fi

echo "Run clients..."
if ! (
    ./run.sh client --rpc-host=${NODE1_HOST} --rpc-port=${NODE1_PORT} --instance-name="node-1" --name="client-1" && \
    ./run.sh client --rpc-host=${NODE2_HOST} --rpc-port=${NODE2_PORT} --instance-name="node-2" --name="client-2" && \
    ./run.sh client --rpc-host=${NODE3_HOST} --rpc-port=${NODE3_PORT} --instance-name="node-3" --name="client-3" && \
    ./run.sh client --rpc-host=${NODE4_HOST} --rpc-port=${NODE4_PORT} --instance-name="node-4" --name="client-4"
); then
    echo "Error: Cannot start client containers"
    exit 2
fi

echo "All contaienrs are running, now logging server..."

docker logs -f ethstats-server
