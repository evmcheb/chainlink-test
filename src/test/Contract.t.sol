// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ds-test/test.sol";
import "../Contract.sol";

contract ContractTest is DSTest {
    Contract c = new Contract();
    function setUp() public {}

    function testLatest() public {
        int latest = c.getPrice();
        emit log_named_int("latest price", latest);
    }

    function testTWAP1hr() public {
        uint latest = c.getTWAPPrice(60*60);
        emit log_named_uint("latest 1hr twap price", latest);
    }

    function testExample() public {
        assertTrue(true);
    }
}
