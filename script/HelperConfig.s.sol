//SPDX-License-Identifier: MIT

//1.deploy mocks when we are on a local anvil chain;
//2.keep track of contract address acrross different chains
//Sepolia ETH/USD
//Mainet ETH/USD

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{
     //if we are on a local anvil,we deploy mocks
     //otherwise,grab the existing address from the live network
     NetworkConfig public activeNetworkConfig;//to see which net is on

     uint8 public constant Decimal = 8;
     int256 public constant Initial_Price = 2000e8;
     
     struct NetworkConfig {
        address priceFeed;//ETH/USD price feed address
     }
     
     constructor() {
        if(block.chainid == 5){//georli's chainid is 5
            activeNetworkConfig = getGeorliEthconfig();
        }else if(block.chainid == 1) {
            activeNetworkConfig =  getMainnetEthconfig();
        }else{
            activeNetworkConfig = getAnvilEthConfig();
        }
     }

     function getGeorliEthconfig() public pure returns(NetworkConfig memory){
         //price feed address
         NetworkConfig memory georliEthConfig = NetworkConfig({priceFeed: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e});
         return georliEthConfig;
     }

     function getMainnetEthconfig() public pure returns(NetworkConfig memory){
         //price feed address
         NetworkConfig memory ethConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
         return ethConfig;
     }

     function getAnvilEthConfig() public returns(NetworkConfig memory){
        if(activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        //1.deploy the mocks
        //2.return the mock address
        vm.startBroadcast();
        //deploy our pricefeed
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(Decimal, Initial_Price);//uint8 _decimals, int256 _initialAnswer,decimal of usdeth is 8,
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
     }
}