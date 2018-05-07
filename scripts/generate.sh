rm -rvf ./channel-artifacts ./crypto-config ./hfc-key-store
echo "Old Data Removed"
echo "Setup Start"
export PATH=$PATH:/home/neospykar/hyperledger/bin
export COMPOSE_HTTP_TIMEOUT=1000
mkdir ./channel-artifacts
cryptogen generate --config=./crypto-config.yaml
echo "Certificates Generated"
export FABRIC_CFG_PATH=$PWD
configtxgen -profile ThreeOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
echo "Genesis Created"
export CHANNEL_NAME=mychanneltest1
configtxgen -profile ThreeOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
echo "CHANNEL ${CHANNEL_NAME} Tx Created"
# export CHANNEL_NAME=neospykarchannel
# configtxgen -profile NeospykarOrgsChannel -outputCreateChannelTx ./channel-artifacts/channelNeo.tx -channelID $CHANNEL_NAME
# echo "CHANNEL ${CHANNEL_NAME} Tx Created"
export CHANNEL_NAME=mychanneltest1
configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
echo "Anchor Peer of ORG1 updated on CHANNEL ${CHANNEL_NAME}"
configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
echo "Anchor Peer of ORG2 updated on CHANNEL ${CHANNEL_NAME}"
configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org3MSP
echo "Anchor Peer of ORG3 updated on CHANNEL ${CHANNEL_NAME}"
# export CHANNEL_NAME=neospykarchannel
# configtxgen -profile NeospykarOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org4MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org4MSP
# echo "Anchor Peer of ORG4 updated on CHANNEL ${CHANNEL_NAME}"
# configtxgen -profile NeospykarOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org5MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org5MSP
# echo "Anchor Peer of ORG5 updated on CHANNEL ${CHANNEL_NAME}"
echo "Setup Done"
