# Fabric Network with Fabcar Chaincode Example in between 3 Organizations
This a basic fabric network setup for 3 Organizations using Fabcar Chaincode for maintaining Car Informations.

## Using Tool
1. Up Network using `./scripts/networkUp.sh`
2. Down Network using `./scripts/networkDown.sh`

## Manual Setps :
### Network Setup
1. `cryptogen generate --config=./crypto-config.yaml`
`export FABRIC_CFG_PATH=$PWD`
2.   `configtxgen -profile TwoOrdererOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block`
`export CHANNEL_NAME=examplechannel`
3. `configtxgen -profile ExampleOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME`
/// update anchor
`export CHANNEL_NAME=examplechannel`
4.   `configtxgen -profile ExampleOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP`
5.   `configtxgen -profile ExampleOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP`
6.   `configtxgen -profile ExampleOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org3MSP`
<!-- ////// export CHANNEL_NAME=neospykarchannel
7. configtxgen -profile NeospykarOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelNeo.tx -channelID $CHANNEL_NAME
8.   configtxgen -profile NeospykarOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org4MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org4MSP
9.   configtxgen -profile NeospykarOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org5MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org5MSP -->

### Up Network
`export IMAGE_TAG="latest"
export COMPOSE_PROJECT_NAME="mnproject"`
1. `docker-compose -f docker-compose-cli.yaml up -d`

### Down Network
1. `docker-compose -f docker-compose-cli.yaml down`
2. `docker rm -f $(docker ps -aq)`	//clear Containers
3. `docker rmi -f $(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')` //removeUnwantedImages

### Remove Old Setup
1. `rm -rvf ./channel-artifacts/* ./crypto-config`
2. `rm -rvf ./crypto-config`

### Create & Join Channel
1. `docker exec -it cliorg1 bash`
2. `export CHANNEL_NAME=examplechannel`
3. `peer channel create -o orderer1.neo.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/neo.com/orderers/orderer1.neo.com/msp/tlscacerts/tlsca.neo.com-cert.pem`
4. `peer channel join -b examplechannel.block`

### Update the anchor peers
1. `peer chaincode install -n examplecc -v 1.0 -p github.com/hyperledger/fabric/peer/chaincode/fabcar/go/`
2. `peer chaincode instantiate -o orderer1.neo.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/neo.com/orderers/orderer1.neo.com/msp/tlscacerts/tlsca.neo.com-cert.pem -C $CHANNEL_NAME -n examplecc -v 1.0 -c '{"Args":["init"]}' -P "OR ('Org1MSP.peer','Org2MSP.member','Org3MSP.member')"`

### query
1.`peer chaincode query -C $CHANNEL_NAME -n examplecc -c '{"Args":["queryCar","CAR1"]}'`

### Invoke
1. `peer chaincode invoke -o orderer1.neo.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/neo.com/orderers/orderer1.neo.com/msp/tlscacerts/tlsca.neo.com-cert.pem  -C $CHANNEL_NAME -n examplecc -c '{"Args":["initLedger"]}'`





## NODE-SDK
### Make Peers join the new channel

```bash
# Stop already running orderer containers
npm run stop-containers
# This will start both orderer & peer containers
npm run start-containers
# Create the channel again as when we start-containers we remove the previous data from the containers
npm run create-channel
# Join the channel
npm run join-channel
```

### Install and instantiate the chaincode

```bash
npm run install-chaincode
npm run instantiate-chaincode
npm run initLedger-chaincode
```

### Invoke the transaction & Query the chaincode
```bash
npm run query-chaincode
npm run invoke-transaction
npm run query-chaincode
