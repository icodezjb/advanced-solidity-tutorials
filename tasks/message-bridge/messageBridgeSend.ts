import { EXTRA_NETWORK_CONFIG } from "../../utils/constants"

module.exports = async function (taskArgs: any, hre: any) {
    const { bridge, id, message } = taskArgs
    const { ethers, network } = hre
    const networkConfig = EXTRA_NETWORK_CONFIG[network.config.chainId]

    const msgBridgeC = await ethers.getContractAt("MessageBridge", bridge)

    const encoder = new TextEncoder();

    const msg_bytes = encoder.encode(message)

    console.log(msg_bytes)

    const crossFee = await msgBridgeC.calculateFee(id, msg_bytes.length)

    console.log(`Sending ${message} to chain ${id} fee ${crossFee}`)


    const txResponse = await msgBridgeC.send_msg(
        id,
        msg_bytes,
        {
            value: crossFee,
        }
    )

    await txResponse.wait(networkConfig.blockConfirmations)
    console.log(`Transaction hash: ${txResponse.hash}`)
}
