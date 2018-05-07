import * as fs from 'fs';
import * as path from 'path';
import { Organization, getClient, getOrderer } from './client';
import config from './config';

const CHANNEL_1_PATH = './../channel-artifacts/channel.tx';

async function main() {

  const org1Client = await getClient(Organization.ORG1);
  const orderer = await getOrderer(org1Client);

  // read in the envelope for the channel config raw bytes
  console.log('Reading the envelope from manually created channel transaction ..');
  const envelope = fs.readFileSync(path.join(__dirname, CHANNEL_1_PATH));

  // extract the configuration
  console.log('Extracting the channel configuration ..');
  const channelConfig = org1Client.extractChannelConfig(envelope);
  // consol.log(channelConfig);
  console.log('Signing the extracted channel configuration ..');
  const signature = org1Client.signChannelConfig(channelConfig);
  // console.log(signature);
  // prepare the request
  const channelRequest: ChannelRequest = {
    name: config.CHANNEL_NAME,
    config: channelConfig,
    signatures: [signature],
    orderer: orderer,
    txId: org1Client.newTransactionID()
  };
  // console.log(channelRequest);
  console.log('Sending the request to create the channel ..');
  const response = await org1Client.createChannel(channelRequest);

  console.log(response);
}

main();
