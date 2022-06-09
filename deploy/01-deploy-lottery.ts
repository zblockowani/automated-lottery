import { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { developmentChains, networkConfig } from "../helper-hardhat-config";
import { VRFCoordinatorV2Mock } from "../typechain-types/VRFCoordinatorV2Mock";
import verify from "../utils/verify";
const deployLottery: DeployFunction = async (
  hre: HardhatRuntimeEnvironment
) => {
  const { deployments, getNamedAccounts, network } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const VRF_SUB_FOUND_AMOUNT = ethers.utils.parseEther("2");

  let vrfCoordinatorAddress;
  let subscriptionId;
  if (developmentChains.includes(network.name)) {
    const vrfCooridnator: VRFCoordinatorV2Mock = (await ethers.getContract(
      "VRFCoordinatorV2Mock"
    )) as VRFCoordinatorV2Mock;
    vrfCoordinatorAddress = vrfCooridnator.address;
    const tx = await vrfCooridnator.createSubscription();
    const response = await tx.wait(1);

    subscriptionId = response.events![0].args!.subId.toString();

    const fundTx = await vrfCooridnator.fundSubscription(
      subscriptionId,
      VRF_SUB_FOUND_AMOUNT
    );
    await fundTx.wait(1);
  } else {
    vrfCoordinatorAddress = networkConfig[network.name].vrfCoordinatorAddress;
    subscriptionId = networkConfig[network.name].subscriptionId;
  }

  const keyHash = networkConfig[network.name].keyHash;
  const callbackGasLimit = networkConfig[network.name].callbackGasLimit;
  const ticketPrice = networkConfig[network.name].ticketPrice;
  const interval = networkConfig[network.name].interval;
  const args = [
    vrfCoordinatorAddress,
    keyHash,
    subscriptionId,
    callbackGasLimit,
    ticketPrice,
    interval,
  ];
  
  console.log(args);
  const lottery = await deploy("Lottery", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: networkConfig[network.name].blockConfirmation,
  });

  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(lottery.address, args);
  }
};

export default deployLottery;
deployLottery.tags = ["all", "lottery"];
