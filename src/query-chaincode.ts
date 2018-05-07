import * as path from 'path';
import Client = require('fabric-client');

import config from './config';
import { Organization, getClient, getOrderer, getPeers } from './client';

async function getChannel(client: Client, org: Organization): Promise<Channel> {
  const orderer = await getOrderer(client);

  console.log('Creating a Channel object ..');
  const channel = client.newChannel(config.CHANNEL_NAME);

  console.log('Specifying the orderer to connect to ..');
  channel.addOrderer(orderer);

  console.log('Getting the peers ..');
  const peers = await getPeers(client, org);

  peers.map(p => channel.addPeer(p));

  console.log('Initializing the channel ..');
  await channel.initialize();

  return channel;
}

async function queryChaincode(org: Organization) {
  const client = await getClient(org);
  const channel = await getChannel(client, org);

  console.log(`Quering the Chaincode on the peers of ${org} for value of 'CAR1' ..`);
  const response = await channel.queryByChaincode({
    chaincodeId: config.CHAIN_CODE_ID,
    fcn: 'queryCar',
    args: ["CAR1"],
    txId: client.newTransactionID()
  });

  console.log(`Peer0 of ${org} has ${response[0].toString('utf8')} as the current value for 'CAR1'..`);
  // console.log(`Peer1 of ${org} has ${response[1].toString('utf8')} as the current value for 'CAR12'..`);
  // console.log(`Peer2 of ${org} has ${response[2].toString('utf8')} as the current value for 'CAR12'..`);

  console.log(`Quering the Chaincode on the peers of ${org} for value of 'AllCars' ..`);
  const response2 = await channel.queryByChaincode({
    chaincodeId: config.CHAIN_CODE_ID,
    fcn: 'queryAllCars',
    args: [],
    txId: client.newTransactionID()
  });

  // console.log(`Peer0 of ${org} has ${response2[0].toString('utf8')} as the current value for 'AllCars'..`);
  console.log(`Peer1 of ${org} has ${response2[1].toString('utf8')} as the current value for 'AllCars'..`);
  // console.log(`Peer2 of ${org} has ${response2[2].toString('utf8')} as the current value for 'AllCars'..`);

}

async function main() {
  console.log('############  ORG1 ###################');
  await queryChaincode(Organization.ORG1);
  // console.log('############  ORG2 ###################');
  // await queryChaincode(Organization.ORG2);
  console.log('############  ORG3 ###################');
  await queryChaincode(Organization.ORG3);
}

main();
