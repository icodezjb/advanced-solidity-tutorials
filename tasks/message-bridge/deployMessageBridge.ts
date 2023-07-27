import { Contract, Wallet } from "ethers"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { HardhatRuntimeEnvironment, Network } from "hardhat/types"
import { EXTRA_NETWORK_CONFIG } from "../../utils/constants"

module.exports = async function (taskArgs: any, hre: HardhatRuntimeEnvironment) {
    const { anchor } = taskArgs
    const { ethers, network } = hre
    const deployer = (await ethers.getSigners())[0]

    console.log("Deploying MessageBridge...")
    const msgBridgeC = await deployNewContract(
        hre, "MessageBridge", deployer, [anchor]
    )

    console.log(`MessageBridge deployed at ${msgBridgeC.address}`)
}

async function deployNewContract(
    hre: HardhatRuntimeEnvironment,
    contractName: string,
    deployer: SignerWithAddress | Wallet,
    args: any[]
): Promise<Contract> {
    const { deployments, network } = hre
    const { deploy, log } = deployments
    const chainId = getNetworkId(network)
    const networkConfig = EXTRA_NETWORK_CONFIG[chainId]

    console.log(
        `Deploying a new MessageBridge contract on chain ${chainId}...` +
            `\nDeployer address: ${deployer.address}`
    )
    const deploymentReceipt = await deploy(contractName, {
        from: deployer.address,
        args: args,
        log: true,
        waitConfirmations: networkConfig.blockConfirmations,
    })
    const targetC = await hre.ethers.getContractAt(contractName, deploymentReceipt.address)
    return targetC
}

function getNetworkId(network: Network): number {
    // if network.config.chaindId is undefined, log error and return 0
    if (typeof network.config.chainId === "undefined") {
        console.error("chainId is undefined")
        return 0
    } else {
        return network.config.chainId
    }
}
