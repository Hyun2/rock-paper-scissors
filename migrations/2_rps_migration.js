const RPS = artifacts.require("RPS");
// const rockpaperscissors = artifacts.require("rockpaperscissors");
module.exports = function(deployer) {
  deployer.deploy(RPS);
  // deployer.deploy(rockpaperscissors);
};
