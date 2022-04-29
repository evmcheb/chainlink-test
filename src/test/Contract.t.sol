// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ds-test/test.sol";
import "../Contract.sol";

contract ContractTest is DSTest {
    Contract c = new Contract();
    function setUp() public {}

    function testTWAP() public {
        int twap = c.getPrice();
        emit log_named_int("latest price", twap);
    }

    function testExample() public {
        assertTrue(true);
    }
}
