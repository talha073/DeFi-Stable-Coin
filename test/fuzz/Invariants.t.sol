// SPDX-License-Identifier: MIT
// Have our invariant aka properties

/* Keep in mind
 what are our varients
 1: The total supply of DSC should be less than the total value of collateral
 2: Getter view functions should never revert  <- evergreen invariant
*/

// Handler-based Invariants

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract OpenInvariantsTest is StdInvariant, Test {
    DeployDSC deployer; 
    DSCEngine dsce; 
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;
    
    function setUp() external{
        deployer = new DeployDSC();
        (dsc, dsce, config)=deployer.run();
        (,,weth, wbtc,) = config.activeNetworkConfig();
        // targetContract(address(dsce));
        // don't call redeemCollateral, unless there is collateral to redeem 
        handler = new Handler(dsce, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTheTotalSupply() public view {
        // get the value of all the collatetal in the protocol
        // compare it to all the debt (dsc)
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalBtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

        console.log("totalSupply: ", totalSupply);
        console.log("totalWethDeposited: ", totalWethDeposited);
        console.log("totalBtcDeposited: ", totalBtcDeposited);
        console.log("Time mint called: ", handler.timeMintIsCalled());


        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalBtcDeposited);

        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_gettersShouldNotRevert() public view {
        dsce.getLiquidationBonus();
        dsce.getPrecision();
    }
    
}