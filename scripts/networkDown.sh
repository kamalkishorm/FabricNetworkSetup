export IMAGE_TAG="latest"
export COMPOSE_PROJECT_NAME="mnproject"
export PATH=$PATH:/home/neospykar/hyperledger/bin
echo "Network Down"
docker-compose -f docker-compose-cli.yaml down --volumes
DOCKER_CONTAINER_IDs=$(docker ps -aq)
if [ -z "$DOCKER_CONTAINER_IDs" -o "$DOCKER_CONTAINER_IDs" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $DOCKER_CONTAINER_IDs
    echo "Containers Cleared"
fi
# docker rm -f $(docker ps -aq)
DOCKER_IMAGE_IDs=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-\|dev-peer" | awk '{print $3}')
if [ -z "$DOCKER_IMAGE_IDs" -o "$DOCKER_IMAGE_IDs" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDs
    echo "Unwanted Images Removed"
fi
# docker rmi -f $(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')


# docker volume rm -f $(docker volume ls)
# echo "All volumes are deleted ;-)"
