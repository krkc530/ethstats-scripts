#!/bin/bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH=${__dir}/nodes.cfg

NODE1_HOST="localhost"
NODE1_PORT="8545"
NODE2_HOST="localhost"
NODE2_PORT="8545"
NODE3_HOST="localhost"
NODE3_PORT="8545"
NODE4_HOST="localhost"
NODE4_PORT="8545"

source $CONFIG_PATH

echo "Notice: Set environment variables in nodes.cfg (i.e., NODE1_HOST="*.*.*.*", NODE1_PORT="8545")"

echo "Run server..."
if ! ./run.sh server; then
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