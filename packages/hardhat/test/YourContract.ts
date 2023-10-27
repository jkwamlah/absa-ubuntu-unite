import { expect } from "chai";
import { ethers } from "hardhat";
import { RewardSystem } from "../typechain-types";

describe("YourContract", function () {
  // We define a fixture to reuse the same setup in every test.

  let rewardSystem: RewardSystem;
  before(async () => {
    const [owner] = await ethers.getSigners();
    const yourContractFactory = await ethers.getContractFactory("RewardSystem");
    rewardSystem = (await yourContractFactory.deploy(owner.address)) as RewardSystem;
    await rewardSystem.deployed();
  });

  describe("Deployment", function () {
    it("Should have the right message on deploy", async function () {
      expect(await rewardSystem.greeting()).to.equal("Building Unstoppable Apps!!!");
    });

    it("Should allow setting a new message", async function () {
      const newGreeting = "Learn Scaffold-ETH 2! :)";

      await rewardSystem.setGreeting(newGreeting);
      expect(await rewardSystem.greeting()).to.equal(newGreeting);
    });
  });
});
