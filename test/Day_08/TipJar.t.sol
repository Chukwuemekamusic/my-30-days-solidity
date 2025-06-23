// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {TipJar} from "../../src/Day_08/TipJar.sol";
import {DeployTipJar} from "../../script/Day_08/TipJar.s.sol";

contract TipJarTest is Test {
    address owner;
    address user = makeAddr("user");
    address user2 = makeAddr("user2");
    TipJar public tipJar;
    DeployTipJar public deployer;

    uint256 public CURRENCY_PRECISION_DECIMALS;
    uint256 public CURRENCY_SCALING_FACTOR;

    function setUp() public {
        deployer = new DeployTipJar();
        tipJar = deployer.run();
        owner = tipJar.getOwner();

        CURRENCY_PRECISION_DECIMALS = tipJar.decimals();
        CURRENCY_SCALING_FACTOR = 10 ** CURRENCY_PRECISION_DECIMALS;
    }

    // =====================
    // Deployment Tests
    // =====================
    function test_InitialState() public view {
        assertEq(tipJar.getOwner(), owner);
        assertTrue(tipJar.currencyExists("USD"));
        assertTrue(tipJar.currencyExists("EUR"));
        assertEq(tipJar.getExchangeRate("USD"), 5e14);
        assertEq(tipJar.getExchangeRate("EUR"), 6e14);
        assertEq(tipJar.totalContributions(), 0);
    }

    // =====================
    // Exchange Rate Tests
    // =====================
    function test_SetExchangeRate() public {
        uint256 newRate = 7e14;
        vm.prank(owner);
        tipJar.setExchangeRate("GBP", newRate);

        assertTrue(tipJar.currencyExists("GBP"));
        assertEq(tipJar.getExchangeRate("GBP"), newRate);
    }

    function test_RevertWhen_SetExchangeRate_NotOwner() public {
        vm.prank(user);
        vm.expectRevert(TipJar.TipJar_Unauthorized.selector);
        tipJar.setExchangeRate("GBP", 7e14);
    }

    function test_RevertWhen_SetExchangeRate_ZeroRate() public {
        vm.prank(owner);
        vm.expectRevert(TipJar.TipJar_InvalidConversionRate.selector);
        tipJar.setExchangeRate("GBP", 0);
    }

    // =====================
    // Currency Conversion Tests
    // =====================
    function test_ConvertForeignCurrencyToWei() public {
        // Test USD conversion (1 USD = 0.0005 ETH)
        uint256 usdAmount = 100 * CURRENCY_SCALING_FACTOR; // 100 USD
        uint256 expectedUsdWei = 0.05 ether; // 100 * 0.0005 ETH
        uint256 actualUsdWei = tipJar.convertForeignCurrencyToWei("USD", usdAmount);
        assertEq(actualUsdWei, expectedUsdWei, "USD to Wei conversion failed");

        // Test EUR conversion (1 EUR = 0.0006 ETH)
        uint256 eurAmount = 100 * CURRENCY_SCALING_FACTOR; // 100 EUR
        uint256 expectedEurWei = 0.06 ether; // 100 * 0.0006 ETH
        uint256 actualEurWei = tipJar.convertForeignCurrencyToWei("EUR", eurAmount);
        assertEq(actualEurWei, expectedEurWei, "EUR to Wei conversion failed");

        // Test revert on non-existent currency
        vm.expectRevert(TipJar.TipJar_CurrencyMissing.selector);
        tipJar.convertForeignCurrencyToWei("GBP", 100 * CURRENCY_SCALING_FACTOR);

        // Test revert on zero amount
        vm.expectRevert(TipJar.TipJar_InvalidAmount.selector);
        tipJar.convertForeignCurrencyToWei("USD", 0);
    }

    function test_TipInCurrency() public {
        uint256 usdAmount = 100 * CURRENCY_SCALING_FACTOR; // 100 USD with 8 decimals
        // uint256 expectedWei = (5e14 * usdAmount) / 10**8; // Convert to wei
        uint256 expectedWei = tipJar.convertForeignCurrencyToWei("USD", usdAmount);

        vm.deal(user, expectedWei);

        vm.prank(user);
        tipJar.tipInCurrency{value: expectedWei}("USD", usdAmount);

        assertEq(tipJar.getContribution(user), expectedWei);
        assertEq(tipJar.getBalance(), expectedWei);
        assertEq(tipJar.totalContributions(), expectedWei);
    }

    function test_RevertWhen_TipInCurrency_InvalidAmount() public {
        vm.expectRevert(TipJar.TipJar_InvalidAmount.selector);
        tipJar.tipInCurrency("USD", 0);
    }

    function test_RevertWhen_TipInCurrency_InvalidCurrency() public {
        vm.expectRevert(TipJar.TipJar_CurrencyMissing.selector);
        tipJar.tipInCurrency("INVALID", 100 * 10 ** 8);
    }

    function test_RevertWhen_TipInCurrency_WrongAmount() public {
        uint256 usdAmount = 100 * 10 ** 8;
        uint256 wrongWei = 1 ether;

        vm.deal(user, wrongWei);
        vm.prank(user);
        vm.expectRevert(TipJar.TipJar_MoneyNotMatching.selector);
        tipJar.tipInCurrency{value: wrongWei}("USD", usdAmount);
    }

    // =====================
    // Tipping Tests
    // =====================
    function test_TipInEth() public {
        uint256 tipAmount = 1 ether;
        vm.deal(user, tipAmount);

        vm.prank(user);
        tipJar.tipInEth{value: tipAmount}();

        assertEq(tipJar.getContribution(user), tipAmount);
        assertEq(tipJar.getBalance(), tipAmount);
        assertEq(tipJar.totalContributions(), tipAmount);
    }

    function test_ReceiveAndFallback() public {
        uint256 tipAmount = 1 ether;
        vm.deal(user, tipAmount);

        // Test receive function
        vm.prank(user);
        (bool success,) = address(tipJar).call{value: tipAmount}("");
        assertTrue(success);
        assertEq(tipJar.getContribution(user), tipAmount);

        // Test fallback function
        vm.deal(user2, tipAmount);
        vm.prank(user2);
        (success,) = address(tipJar).call{value: tipAmount}(abi.encodeWithSignature("nonExistentFunction()"));
        assertTrue(success);
        assertEq(tipJar.getContribution(user2), tipAmount);
    }

    // =====================
    // Withdrawal & Access Control Tests
    // =====================
    function test_Withdraw() public {
        uint256 tipAmount = 1 ether;
        vm.deal(user, tipAmount);

        // First add some funds
        vm.prank(user);
        tipJar.tipInEth{value: tipAmount}();

        // Then withdraw as owner
        uint256 initialBalance = owner.balance;
        vm.prank(owner);
        tipJar.withdraw();

        assertEq(tipJar.getBalance(), 0);
        assertEq(owner.balance, initialBalance + tipAmount);
    }

    function test_RevertWhen_Withdraw_NotOwner() public {
        vm.prank(user);
        vm.expectRevert(TipJar.TipJar_Unauthorized.selector);
        tipJar.withdraw();
    }
}
