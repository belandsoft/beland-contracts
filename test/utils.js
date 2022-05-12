
async function getLastBlockTimestamp() {
  return (await web3.eth.getBlock(await web3.eth.getBlockNumber())).timestamp;
}

async function mineBlockWithTS(ts) {
  await web3.currentProvider.send(
    {
      jsonrpc: "2.0",
      method: "evm_mine",
      params: [ts],
    },
    () => {}
  );

  await setChainTimestamp(ts);
}

async function setChainTimestamp(ts) {
  await web3.currentProvider.send(
    {
      jsonrpc: "2.0",
      method: "evm_setTimestamp",
      params: [ts],
    },
    () => {}
  );
}


module.exports = {
    getLastBlockTimestamp,
    setChainTimestamp,
    mineBlockWithTS
}