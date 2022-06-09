import { ethers } from "hardhat";

export const developmentChains = ["hardhat", "localhost"];
export interface networkConfigItem {
  blockConfirmation: number;
  vrfCoordinatorAddress?: string;
  keyHash: string;
  subscriptionId?: string;
  callbackGasLimit: string;
  ticketPrice: string;
  interval: string
}
export interface networkConfigInfo {
  [key: string]: networkConfigItem;
}

export const networkConfig: networkConfigInfo = {
  hardhat: {
    blockConfirmation: 1,
    keyHash:
      "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
    callbackGasLimit: "500000",
    ticketPrice: ethers.utils.parseEther("0.01").toString(),
    interval: "100"
  },
  // localhost: {
  //   blockConfirmation: 1,
  // },
  rinkeby: {
    blockConfirmation: 6,
    vrfCoordinatorAddress: "0x6168499c0cFfCaCD319c818142124B7A15E857ab",
    keyHash:
      "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
    subscriptionId: "6117",
    callbackGasLimit: "500000",
    ticketPrice: ethers.utils.parseEther("0.01").toString(),
    interval: "10"

  },
};
