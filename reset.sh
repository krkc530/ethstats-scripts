#!/bin/bash

echo "Notice: docker images should has default name (e.g., ethstats-server, ethstats-client)"

read -r -p "Remove all containers and images? [y/n]" response
case "$response" in
    [yY][eE][sS]|[yY])
        rm server.cfg
        docker stop $(docker ps -aqf ancestor=ethstats-client)
        docker stop $(docker ps -aqf ancestor=ethstats-server)
        docker rm $(docker ps -aqf ancestor=ethstats-server)
        docker rm $(docker ps -aqf ancestor=ethstats-client)
        docker rmi ethstats-client ethstats-server
        ;;
    *)
        exit 1
        ;;
esac

echo "Reset done."