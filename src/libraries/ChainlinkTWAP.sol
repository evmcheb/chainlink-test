// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {FeedRegistryInterface} from "chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import {Denominations} from "chainlink/contracts/src/v0.8/Denominations.sol";

library ChainlinkTWAP {
    // Kovan FeedRegistry address
    FeedRegistryInterface public constant registry = FeedRegistryInterface(0xAa7F6f7f507457a1EE157fE97F6c7DB2BEec5cD0);

    function getTokenFeed(address base) public view returns (address) {
        address aggregator = address(registry.getFeed(base, Denominations.USD));
        return (aggregator);
    }

    function getLatestPrice(address base) public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/
            ,
            ,

        ) = /*uint timeStamp*/
            /*uint80 answeredInRound*/
            registry.latestRoundData(base, Denominations.USD);
        return price;
    }

    function _getRoundData(address base, uint80 _round)
        public
        view
        returns (
            uint80,
            uint256,
            uint256
        )
    {
        (uint80 round, int256 latestPrice, , uint256 latestTimestamp, ) = registry.getRoundData(
            base,
            Denominations.USD,
            _round
        );
        while (latestPrice < 0) {
            require(round > 0, "Not enough history");
            round = round - 1;
            (, latestPrice, , latestTimestamp, ) = registry.getRoundData(base, Denominations.USD, round);
        }
        return (round, uint256(latestPrice), latestTimestamp);
    }

    function _getLatestRoundData(address base)
        public
        view
        returns (
            uint80,
            uint256 finalPrice,
            uint256
        )
    {
        (uint80 round, int256 latestPrice, , uint256 latestTimestamp, ) = registry.latestRoundData(
            base,
            Denominations.USD
        );
        finalPrice = uint256(latestPrice);
        if (latestPrice < 0) {
            require(round > 0, "Not enough history");
            (round, finalPrice, latestTimestamp) = _getRoundData(base, round - 1);
        }
        return (round, finalPrice, latestTimestamp);
    }

    function getTWAPPrice(address base, uint256 interval) public view returns (uint256) {
        // 3 different timestamps, `previous`, `current`, `target`
        // `base` = now - _interval
        // `current` = current round timestamp from aggregator
        // `previous` = previous round timestamp form aggregator
        // now >= previous > current > = < base
        //
        //  while loop i = 0
        //  --+------+-----+-----+-----+-----+-----+
        //         base                 current  now(previous)
        //
        //  while loop i = 1
        //  --+------+-----+-----+-----+-----+-----+
        //         base           current previous now

        (uint80 round, uint256 latestPrice, uint256 latestTimestamp) = _getLatestRoundData(base);
        if (interval == 0 || round == 0) {
            return latestPrice;
        }

        uint256 baseTimestamp = block.timestamp - interval;
        // if latest updated timestamp is earlier than target timestamp, return the latest price.
        if (latestTimestamp < baseTimestamp) {
            return latestPrice;
        }

        // rounds are like snapshots, latestRound means the latest price snapshot. follow chainlink naming
        uint256 previousTimestamp = latestTimestamp;
        uint256 cumulativeTime = block.timestamp - previousTimestamp;
        uint256 weightedPrice = latestPrice * cumulativeTime;
        uint256 timeFraction;
        while (true) {
            if (round == 0) {
                // To prevent from div 0 error, return the latest price if `cumulativeTime == 0`
                if (cumulativeTime == 0) {
                    return latestPrice;
                }
                // if cumulative time is less than requested interval, return current twap price
                return weightedPrice / cumulativeTime;
            }

            round = round - 1;
            (, uint256 currentPrice, uint256 currentTimestamp) = _getRoundData(base, round);

            // check if current round timestamp is earlier than target timestamp
            if (currentTimestamp <= baseTimestamp) {
                // weighted time period will be (target timestamp - previous timestamp). For example,
                // now is 1000, interval is 100, then target timestamp is 900. If timestamp of current round is 970,
                // and timestamp of NEXT round is 880, then the weighted time period will be (970 - 900) = 70,
                // instead of (970 - 880)
                weightedPrice = weightedPrice + (currentPrice * (previousTimestamp - baseTimestamp));
                break;
            }

            timeFraction = previousTimestamp - currentTimestamp;
            weightedPrice = weightedPrice + (currentPrice * timeFraction);
            cumulativeTime = cumulativeTime + timeFraction;
            previousTimestamp = currentTimestamp;
        }
        if (weightedPrice == 0) {
            return latestPrice;
        }
        return weightedPrice / interval;
    }
}
