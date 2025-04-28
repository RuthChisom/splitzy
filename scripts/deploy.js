// scripts/deploy.js

async function main() {
    const cUSDCoinAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"; // cUSD on Alfajores (testnet)

    const Splitzy = await ethers.getContractFactory("Splitzy");
    const splitzy = await Splitzy.deploy(cUSDCoinAddress);
    // await splitzy.deployed();
  
    console.log("Splitzy deployed to:", splitzy.target);
    // console.log("Splitzy deployed to:", splitzy.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  