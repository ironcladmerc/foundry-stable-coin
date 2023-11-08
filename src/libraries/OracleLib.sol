// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLib
 * @author Mike Harrison
 * @notice this library is used to check the chainlink Oracle for stale data.
 * if a price is sstale, the function will revert, and render the DSCEngine unusable
 * -- this is by design to prevent the system from being exploited.
 */
library OracleLib {
    error OracleLib__StalePriceFeed();
    uint256 private constant TIMEOUT = 3 hours;

    function staleCheckLatestRoundData(
        AggregatorV3Interface priceFeed
    ) public view returns (uint80, int256, uint256, uint256, uint80) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        uint256 secondsSince = block.timestamp - updatedAt;
        if (secondsSince > TIMEOUT) {
            revert OracleLib__StalePriceFeed();
        }

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}
