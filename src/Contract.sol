// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ChainlinkTWAP} from "./libraries/ChainlinkTWAP.sol";

contract Contract {
    function getPrice() public view returns (int latest) {
        latest = ChainlinkTWAP.getLatestPrice(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }
    function getTWAPPrice(uint time) public view returns (uint latestTwap) {
        latestTwap = ChainlinkTWAP.getTWAPPrice(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, time);
    }
}