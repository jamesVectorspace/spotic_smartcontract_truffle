const Exchange = artifacts.require("Exchange");
const SPOTICTOKEN = artifacts.require("SPOTICTOKEN") ;
const tUSDT = artifacts.require("tUSDT") ;
const tUSDC = artifacts.require("tUSDC") ;

module.exports = async function (deployer) {
  await deployer.deploy(SPOTICTOKEN);
 
  const deployedSPOTICTOKEN= await SPOTICTOKEN.deployed() ;
  
  await deployer.deploy(tUSDT);

  const deployedtUSDT = await tUSDT.deployed();

  await deployer.deploy(tUSDC);

  const deployedtUSDC = await tUSDC.deployed();

  await deployer.deploy(
    Exchange, 
    deployedSPOTICTOKEN.address,
    deployedtUSDT.address,
    deployedtUSDC.address
  );
};