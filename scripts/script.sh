#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts


# verify the result of the end-to-end test
verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
		echo
   		exit 1
	fi
}

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
        CORE_PEER_LOCALMSPID="OrdererINMSP"
        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/neo.com/orderers/orderer1.neo.com/msp/tlscacerts/tlsca.neo.com-cert.pem
        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/neo.com/users/Admin@neo.com/msp
}

setGlobals () {
	PEER=$1
	ORG=$2
	if [ $ORG -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org1MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.neo.com/peers/peer0.org1.neo.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.neo.com/users/Admin@org1.neo.com/msp
		if [ $PEER -eq 0 ]; then
			CORE_PEER_ADDRESS=peer0.org1.neo.com:7051
		elif [ $PEER -eq 1 ]; then
			CORE_PEER_ADDRESS=peer1.org1.neo.com:7051
		else
			CORE_PEER_ADDRESS=peer2.org1.neo.com:7051
		fi
	elif [ $ORG -eq 2 ] ; then
		CORE_PEER_LOCALMSPID="Org2MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.neo.com/peers/peer0.org2.neo.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.neo.com/users/Admin@org2.neo.com/msp
		if [ $PEER -eq 0 ]; then
			CORE_PEER_ADDRESS=peer0.org2.neo.com:7051
		elif [ $PEER -eq 1 ]; then
			CORE_PEER_ADDRESS=peer1.org2.neo.com:7051
		else
			CORE_PEER_ADDRESS=peer2.org2.neo.com:7051
		fi

	elif [ $ORG -eq 3 ] ; then
		CORE_PEER_LOCALMSPID="Org3MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.neo.com/peers/peer0.org3.neo.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.neo.com/users/Admin@org3.neo.com/msp
		if [ $PEER -eq 0 ]; then
			CORE_PEER_ADDRESS=peer0.org3.neo.com:7051
		elif [ $PEER -eq 1 ]; then
			CORE_PEER_ADDRESS=peer1.org3.neo.com:7051
		else
			CORE_PEER_ADDRESS=peer2.org3.neo.com:7051
		fi
	else
		echo "================== ERROR !!! ORG Unknown =================="
	fi

	env |grep CORE
}


updateAnchorPeers() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel update -o orderer1.neo.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
		res=$?
                set +x
  else
                set -x
		peer channel update -o orderer1.neo.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
                set +x
  fi
	cat log.txt
	verifyResult $res "Anchor peer update failed"
	echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
	sleep $DELAY
	echo
}

## Sometimes Join takes time hence RETRY at least for 5 times
joinChannelWithRetry () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG

        set -x
	peer channel join -b $CHANNEL_NAME.block  >&log.txt
	res=$?
        set +x
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${PEER}.org${ORG} failed to join the channel, Retry after $DELAY seconds"
		sleep $DELAY
		joinChannelWithRetry $PEER $ORG
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to Join the Channel"
}

installChaincode () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	VERSION=${3:-1.0}
        set -x
	peer chaincode install -n examplecctest -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} >&log.txt
	res=$?
        set +x
	echo "===================== logs ====================="
	cat log.txt
	verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has Failed"
	echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
	echo
}

instantiateChaincode () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	VERSION=${3:-1.0}

	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer chaincode instantiate -o orderer1.neo.com:7050 -C $CHANNEL_NAME -n examplecctest -l ${LANGUAGE} -v ${VERSION} -c '{"Args":["init"]}' -P "OR	('Org1MSP.member','Org2MSP.member','Org3MSP.member')" >&log.txt
		res=$?
                set +x
	else
                set -x
		peer chaincode instantiate -o orderer1.neo.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n examplecctest -l ${LANGUAGE} -v 1.0 -c '{"Args":["init"]}' -P "OR	('Org1MSP.member','Org2MSP.member','Org3MSP.member')" >&log.txt
		res=$?
                set +x
	fi
	cat log.txt
	verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

upgradeChaincode () {
    PEER=$1
    ORG=$2
    setGlobals $PEER $ORG

    set -x
    peer chaincode upgrade -o orderer1.neo.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n examplecctest -v 2.0 -c '{"Args":["init"]}' -P "OR ('Org1MSP.member','Org2MSP.member','Org3MSP.member')"
    res=$?
	set +x
    cat log.txt
    verifyResult $res "Chaincode upgrade on org${ORG} peer${PEER} has Failed"
    echo "===================== Chaincode is upgraded on org${ORG} peer${PEER} ===================== "
    echo
}

chaincodeQuery () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  echo "===================== Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
  local rc=1
	local VALUE= nil
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s)-starttime)) secs"
     set -x
     peer chaincode query -C $CHANNEL_NAME -n examplecctest -c '{"Args":["queryAllCars"]}' >&log.txt
	 res=$?
     set +x
     test $res -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" != nil && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 || "$VALUE" != nil ; then
	echo "===================== Query on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
  else
	echo "!!!!!!!!!!!!!!! Query result on peer${PEER}.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	exit 1
  fi
}

# fetchChannelConfig <channel_id> <output_json>
# Writes the current channel config for a given channel to a JSON file
fetchChannelConfig() {
  CHANNEL=$1
  OUTPUT=$2

  setOrdererGlobals

  echo "Fetching the most recent configuration block for the channel"
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer channel fetch config config_block.pb -o orderer1.neo.com:7050 -c $CHANNEL --cafile $ORDERER_CA
    set +x
  else
    set -x
    peer channel fetch config config_block.pb -o orderer1.neo.com:7050 -c $CHANNEL --tls --cafile $ORDERER_CA
    set +x
  fi

  echo "Decoding config block to JSON and isolating config to ${OUTPUT}"
  set -x
  configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > "${OUTPUT}"
  set +x
}

# signConfigtxAsPeerOrg <org> <configtx.pb>
# Set the peerOrg admin of an org and signing the config update
signConfigtxAsPeerOrg() {
        PEERORG=$1
        TX=$2
        setGlobals 0 $PEERORG
        set -x
        peer channel signconfigtx -f "${TX}"
        set +x
}

# createConfigUpdate <channel_id> <original_config.json> <modified_config.json> <output.pb>
# Takes an original and modified config, and produces the config update tx which transitions between the two
createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config > original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config > modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original original_config.pb --updated modified_config.pb > config_update.pb
  configtxlator proto_decode --input config_update.pb  --type common.ConfigUpdate > config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
  configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope > "${OUTPUT}"
  set +x
}

chaincodeInvokeCreate () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		# peer chaincode invoke -o orderer1.neo.com:7050 -C $CHANNEL_NAME -n examplecctest -c '{"Args":["initLedger"]}' >&log.txt
		peer chaincode invoke -o orderer1.neo.com:7050 -C $CHANNEL_NAME -n examplecctest -c '{"Args":["createCar","CAR11","Hyundai","i10","blue","Mr. Mehra"]}' >&log.txt
		res=$?
                set +x
	else
                set -x
		# peer chaincode invoke -o orderer1.neo.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n examplecctest -c '{"Args":["initLedger"]}' >&log.txt
		peer chaincode invoke -o orderer1.neo.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n examplecctest -c '{"Args":["createCar","CAR11","Hyundai","i10","blue","Mr. Mehra"]}' >&log.txt
		res=$?
                set +x
	fi
	cat log.txt
	verifyResult $res "Invoke execution on peer${PEER}.org${ORG} failed "
	echo "===================== Invoke transaction on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

chaincodeInvoke () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer chaincode invoke -o orderer1.neo.com:7050 -C $CHANNEL_NAME -n examplecctest -c '{"Args":["initLedger"]}' >&log.txt
		# peer chaincode invoke -o orderer1.neo.com:7050 -C $CHANNEL_NAME -n examplecctest -c '{"Args":["createCar","newCar01","Hyundai","i10","blue","Mr. Mehra"]}' >&log.txt
		res=$?
                set +x
	else
                set -x
		peer chaincode invoke -o orderer1.neo.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n examplecctest -c '{"Args":["initLedger"]}' >&log.txt
		# peer chaincode invoke -o orderer1.neo.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n examplecctest -c '{"Args":["createCar","newCar01","Hyundai","i10","blue","Mr. Mehra"]}' >&log.txt
		res=$?
                set +x
	fi
	cat log.txt
	verifyResult $res "Invoke execution on peer${PEER}.org${ORG} failed "
	echo "===================== Invoke transaction on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}


echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/neo.com/orderers/orderer1.neo.com/msp/tlscacerts/tlsca.neo.com-cert.pem
CORE_PEER_TLS_ENABLED=true

CC_SRC_PATH="github.com/chaincode/fabcar/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/fabcar/node/"
fi

echo "Channel name : "$CHANNEL_NAME

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer1.neo.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer1.neo.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

joinChannel () {
	for org in 1 2 3; do
	    for peer in 0 1 2; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.org${org} joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep $DELAY
		echo
	    done
	done
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
updateAnchorPeers 0 1
echo "Updating anchor peers for org2..."
updateAnchorPeers 0 2
echo "Updating anchor peers for org3..."
updateAnchorPeers 0 3
sleep 5

# ## Install chaincode on peer0.org1 and peer0.org2
# echo "Installing chaincode on peer0.org1..."
# installChaincode 0 1
# echo "Installing chaincode on peer1.org1..."
# installChaincode 1 1
# echo "Install chaincode on peer0.org2..."
# installChaincode 0 2
# echo "Installing chaincode on peer0.org3..."
# installChaincode 0 3
# echo "Installing chaincode on peer1.org3..."
# installChaincode 1 3
# # Instantiate chaincode on peer0.org2
# echo "Instantiating chaincode on peer0.org2..."
# instantiateChaincode 0 2
# sleep 5
#
# # Invoke chaincode initLedger function
# echo "Sending invoke transaction on peer0.org2..."
# chaincodeInvoke 0 2
#
# # Query chaincode on peer0.org3
# echo "Querying chaincode on peer0.org3..."
# chaincodeQuery 0 3
#
# # Query chaincode on peer0.org1
# echo "Querying chaincode on peer0.org1..."
# chaincodeQuery 0 1
#
# ## Install chaincode on peer1.org2
# echo "Installing chaincode on peer1.org2..."
# installChaincode 1 2
# sleep 5
# # Query chaincode on peer1.org2
# echo "Querying chaincode on peer1.org2..."
# chaincodeQuery 1 2
#
# # Invoke chaincode createCar function
# echo "Sending invoke transaction on peer1.org2..."
# chaincodeInvokeCreate 1 2
# sleep 5
#
# # Query on chaincode on peer1.org2
# echo "Querying chaincode on peer1.org2..."
# chaincodeQuery 1 2

echo
echo "========= All GOOD, execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
