echo "Network"
export IMAGE_TAG="latest"
export COMPOSE_PROJECT_NAME="mnproject"
docker-compose -f docker-compose-cli.yaml up -d
echo "Network UP"
sleep 15

export IMAGE_TAG="latest"
export COMPOSE_PROJECT_NAME="mnproject"
export CHANNEL_NAME=mychanneltest1
export CLI_DELAY=3
export LANGUAGE=golang
export CLI_TIMEOUT=21
docker exec cliorg2 scripts/script.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT
