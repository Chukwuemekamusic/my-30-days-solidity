// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test, console} from "forge-std/Test.sol";
import {TipJar} from "../../src/Day_08/TipJar.sol";
import {DeployTipJar} from "../../script/Day_08/TipJar.s.sol";

contract TipJarTest is Test {
    TipJar public tipJar;
    DeployTipJar public deployer;

    address public owner;
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    uint256 public constant CURRENCY_PRECISION_DECIMALS = 8;
    uint256 public constant CURRENCY_SCALING_FACTOR = 10 ** CURRENCY_PRECISION_DECIMALS;

    // Events for testing
    event ExchangeRateSet(string indexed currencyName, uint256 exchangeRate);
    event TipInCurrency(address indexed sender, string indexed currencyName, uint256 currencyAmount, uint256 weiAmount);
    event TipInEth(address indexed sender, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);

    function setUp() public {
        deployer = new DeployTipJar();
        tipJar = deployer.run();
        owner = tipJar.getOwner();

        // Give test accounts some ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testDeploymentSetsOwnerCorrectly() public view {
        assertEq(tipJar.getOwner(), owner);
    }

    function testDeploymentSetsInitialExchangeRates() public view {
        // USD rate should be 5e14 (0.0005 ETH)
        assertEq(tipJar.getExchangeRate("USD"), 5e14);
        assertTrue(tipJar.currencyExists("USD"));

        // EUR rate should be 6e14 (0.0006 ETH)
        assertEq(tipJar.getExchangeRate("EUR"), 6e14);
        assertTrue(tipJar.currencyExists("EUR"));
    }

    function testInitialContractState() public view {
        assertEq(tipJar.totalContributions(), 0);
        assertEq(tipJar.getBalance(), 0);
        assertEq(tipJar.getContribution(user1), 0);
    }

    /*//////////////////////////////////////////////////////////////
                        EXCHANGE RATE TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetExchangeRateAsOwner() public {
        vm.expectEmit(true, false, false, true);
        emit ExchangeRateSet("GBP", 7e14);

        vm.prank(owner);
        tipJar.setExchangeRate("GBP", 7e14);

        assertEq(tipJar.getExchangeRate("GBP"), 7e14);
        assertTrue(tipJar.currencyExists("GBP"));
    }

    function testSetExchangeRateRevertsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert(TipJar.TipJar_Unauthorized.selector);
        tipJar.setExchangeRate("GBP", 7e14);
    }

    function testSetExchangeRateRevertsIfZero() public {
        vm.prank(owner);
        vm.expectRevert(TipJar.TipJar_InvalidConversionRate.selector);
        tipJar.setExchangeRate("GBP", 0);
    }

    function testGetExchangeRateRevertsForNonexistentCurrency() public {
        vm.expectRevert(TipJar.TipJar_CurrencyMissing.selector);
        tipJar.getExchangeRate("JPY");
    }

    function testUpdateExistingExchangeRate() public {
        // Update USD rate
        vm.prank(owner);
        tipJar.setExchangeRate("USD", 4e14);

        assertEq(tipJar.getExchangeRate("USD"), 4e14);
    }

    /*//////////////////////////////////////////////////////////////
                        CURRENCY CONVERSION TESTS
    //////////////////////////////////////////////////////////////*/

    function testConvertForeignCurrencyToWei() public view {
        // Test USD conversion: 10 USD * 5e14 / 1e8 = 5e7 wei
        uint256 weiAmount = tipJar.convertForeignCurrencyToWei("USD", 10 * CURRENCY_SCALING_FACTOR);
        assertEq(weiAmount, 5e16); // 0.05 ETH
    }

    function testConvertForeignCurrencyToWeiWithDecimals() public view {
        // Test 12.5 USD (12.5 * 1e8)
        uint256 amount = 125 * (CURRENCY_SCALING_FACTOR / 10); // 12.5 USD
        uint256 weiAmount = tipJar.convertForeignCurrencyToWei("USD", amount);
        assertEq(weiAmount, 625e13); // 0.0625 ETH
    }

    function testConvertForeignCurrencyRevertsForZeroAmount() public {
        vm.expectRevert(TipJar.TipJar_InvalidAmount.selector);
        tipJar.convertForeignCurrencyToWei("USD", 0);
    }

    function testConvertForeignCurrencyRevertsForNonexistentCurrency() public {
        vm.expectRevert(TipJar.TipJar_CurrencyMissing.selector);
        tipJar.convertForeignCurrencyToWei("JPY", 100 * CURRENCY_SCALING_FACTOR);
    }

    /*//////////////////////////////////////////////////////////////
                            TIP IN CURRENCY TESTS
    //////////////////////////////////////////////////////////////*/

    function testTipInCurrencySuccess() public {
        uint256 currencyAmount = 5 * CURRENCY_SCALING_FACTOR; // 5 USD
        uint256 expectedWei = tipJar.convertForeignCurrencyToWei("USD", currencyAmount);

        vm.expectEmit(true, true, false, true);
        emit TipInCurrency(user1, "USD", currencyAmount, expectedWei);

        vm.prank(user1);
        tipJar.tipInCurrency{value: expectedWei}("USD", currencyAmount);

        assertEq(tipJar.getContribution(user1), expectedWei);
        assertEq(tipJar.totalContributions(), expectedWei);
        assertEq(tipJar.getBalance(), expectedWei);
    }

    function testTipInCurrencyRevertsWithWrongEthAmount() public {
        uint256 currencyAmount = 5 * CURRENCY_SCALING_FACTOR; // 5 USD
        uint256 expectedWei = tipJar.convertForeignCurrencyToWei("USD", currencyAmount);
        uint256 wrongWei = expectedWei + 1;

        vm.prank(user1);
        vm.expectRevert(TipJar.TipJar_MoneyNotMatching.selector);
        tipJar.tipInCurrency{value: wrongWei}("USD", currencyAmount);
    }

    function testTipInCurrencyRevertsWithZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(TipJar.TipJar_InvalidAmount.selector);
        tipJar.tipInCurrency{value: 0}("USD", 0);
    }

    function testTipInCurrencyRevertsForNonexistentCurrency() public {
        vm.prank(user1);
        vm.expectRevert(TipJar.TipJar_CurrencyMissing.selector);
        tipJar.tipInCurrency{value: 1 ether}("JPY", 100 * CURRENCY_SCALING_FACTOR);
    }

    function testMultipleTipsInCurrency() public {
        uint256 amount1 = 3 * CURRENCY_SCALING_FACTOR; // 3 USD
        uint256 amount2 = 2 * CURRENCY_SCALING_FACTOR; // 2 EUR

        uint256 wei1 = tipJar.convertForeignCurrencyToWei("USD", amount1);
        uint256 wei2 = tipJar.convertForeignCurrencyToWei("EUR", amount2);

        vm.prank(user1);
        tipJar.tipInCurrency{value: wei1}("USD", amount1);

        vm.prank(user1);
        tipJar.tipInCurrency{value: wei2}("EUR", amount2);

        assertEq(tipJar.getContribution(user1), wei1 + wei2);
        assertEq(tipJar.totalContributions(), wei1 + wei2);
    }

    /*//////////////////////////////////////////////////////////////
                            TIP IN ETH TESTS
    //////////////////////////////////////////////////////////////*/

    function testTipInEthSuccess() public {
        uint256 tipAmount = 0.1 ether;

        vm.expectEmit(true, false, false, true);
        emit TipInEth(user1, tipAmount);

        vm.prank(user1);
        tipJar.tipInEth{value: tipAmount}();

        assertEq(tipJar.getContribution(user1), tipAmount);
        assertEq(tipJar.totalContributions(), tipAmount);
        assertEq(tipJar.getBalance(), tipAmount);
    }

    function testTipInEthRevertsWithZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(TipJar.TipJar_InvalidAmount.selector);
        tipJar.tipInEth{value: 0}();
    }

    function testMultipleTipsInEth() public {
        uint256 tip1 = 0.1 ether;
        uint256 tip2 = 0.2 ether;

        vm.prank(user1);
        tipJar.tipInEth{value: tip1}();

        vm.prank(user2);
        tipJar.tipInEth{value: tip2}();

        assertEq(tipJar.getContribution(user1), tip1);
        assertEq(tipJar.getContribution(user2), tip2);
        assertEq(tipJar.totalContributions(), tip1 + tip2);
    }

    /*//////////////////////////////////////////////////////////////
                        RECEIVE/FALLBACK TESTS
    //////////////////////////////////////////////////////////////*/

    function testReceiveFunctionWorks() public {
        uint256 tipAmount = 0.1 ether;

        vm.expectEmit(true, false, false, true);
        emit TipInEth(user1, tipAmount);

        vm.prank(user1);
        (bool success,) = address(tipJar).call{value: tipAmount}("");
        assertTrue(success);

        assertEq(tipJar.getContribution(user1), tipAmount);
        assertEq(tipJar.totalContributions(), tipAmount);
    }

    function testFallbackFunctionWorks() public {
        uint256 tipAmount = 0.1 ether;

        vm.expectEmit(true, false, false, true);
        emit TipInEth(user1, tipAmount);

        vm.prank(user1);
        (bool success,) = address(tipJar).call{value: tipAmount}("invalidfunction()");
        assertTrue(success);

        assertEq(tipJar.getContribution(user1), tipAmount);
        assertEq(tipJar.totalContributions(), tipAmount);
    }

    function testReceiveRevertsWithZeroValue() public {
        vm.prank(user1);
        vm.expectRevert(TipJar.TipJar_InvalidAmount.selector);
        (bool success,) = address(tipJar).call{value: 0}("");
        assertFalse(success);
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdrawSuccess() public {
        // First, add some funds
        uint256 tipAmount = 1 ether;
        vm.prank(user1);
        tipJar.tipInEth{value: tipAmount}();

        uint256 ownerBalanceBefore = owner.balance;

        vm.expectEmit(true, false, false, true);
        emit Withdrawal(owner, tipAmount);

        vm.prank(owner);
        tipJar.withdraw();

        assertEq(tipJar.getBalance(), 0);
        assertEq(owner.balance, ownerBalanceBefore + tipAmount);
    }

    function testWithdrawRevertsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert(TipJar.TipJar_Unauthorized.selector);
        tipJar.withdraw();
    }

    function testWithdrawRevertsIfNoBalance() public {
        vm.prank(owner);
        vm.expectRevert(TipJar.TipJar_InvalidAmount.selector);
        tipJar.withdraw();
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetContribution() public {
        uint256 tipAmount = 0.5 ether;

        vm.prank(user1);
        tipJar.tipInEth{value: tipAmount}();

        assertEq(tipJar.getContribution(user1), tipAmount);
        assertEq(tipJar.getContribution(user2), 0);
    }

    function testGetBalance() public {
        assertEq(tipJar.getBalance(), 0);

        uint256 tipAmount = 0.3 ether;
        vm.prank(user1);
        tipJar.tipInEth{value: tipAmount}();

        assertEq(tipJar.getBalance(), tipAmount);
    }

    function testCurrencyExists() public {
        assertTrue(tipJar.currencyExists("USD"));
        assertTrue(tipJar.currencyExists("EUR"));
        assertFalse(tipJar.currencyExists("JPY"));

        // Add new currency
        vm.prank(owner);
        tipJar.setExchangeRate("JPY", 1e12);
        assertTrue(tipJar.currencyExists("JPY"));
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzTipInEth(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1000 ether);

        vm.deal(user1, amount);
        vm.prank(user1);
        tipJar.tipInEth{value: amount}();

        assertEq(tipJar.getContribution(user1), amount);
        assertEq(tipJar.totalContributions(), amount);
        assertEq(tipJar.getBalance(), amount);
    }

    function testFuzzSetExchangeRate(uint256 rate) public {
        vm.assume(rate > 0 && rate <= type(uint128).max);

        vm.prank(owner);
        tipJar.setExchangeRate("TEST", rate);

        assertEq(tipJar.getExchangeRate("TEST"), rate);
        assertTrue(tipJar.currencyExists("TEST"));
    }

    function testFuzzConvertCurrency(uint256 amount) public {
        vm.assume(amount > 0 && amount <= type(uint128).max);

        uint256 weiAmount = tipJar.convertForeignCurrencyToWei("USD", amount);
        uint256 expectedWei = (5e14 * amount) / CURRENCY_SCALING_FACTOR;

        assertEq(weiAmount, expectedWei);
    }

    /*//////////////////////////////////////////////////////////////
                            INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testCompleteWorkflow() public {
        // 1. Owner sets a new exchange rate
        vm.prank(owner);
        tipJar.setExchangeRate("GBP", 8e14);

        // 2. Users tip in different currencies and ETH
        uint256 usdAmount = 10 * CURRENCY_SCALING_FACTOR;
        uint256 eurAmount = 5 * CURRENCY_SCALING_FACTOR;
        uint256 gbpAmount = 3 * CURRENCY_SCALING_FACTOR;
        uint256 ethAmount = 0.1 ether;

        uint256 usdWei = tipJar.convertForeignCurrencyToWei("USD", usdAmount);
        uint256 eurWei = tipJar.convertForeignCurrencyToWei("EUR", eurAmount);
        uint256 gbpWei = tipJar.convertForeignCurrencyToWei("GBP", gbpAmount);

        vm.prank(user1);
        tipJar.tipInCurrency{value: usdWei}("USD", usdAmount);

        vm.prank(user1);
        tipJar.tipInCurrency{value: eurWei}("EUR", eurAmount);

        vm.prank(user2);
        tipJar.tipInCurrency{value: gbpWei}("GBP", gbpAmount);

        vm.prank(user2);
        tipJar.tipInEth{value: ethAmount}();

        // 3. Check total contributions
        uint256 expectedTotal = usdWei + eurWei + gbpWei + ethAmount;
        assertEq(tipJar.totalContributions(), expectedTotal);
        assertEq(tipJar.getBalance(), expectedTotal);

        // 4. Check individual contributions
        assertEq(tipJar.getContribution(user1), usdWei + eurWei);
        assertEq(tipJar.getContribution(user2), gbpWei + ethAmount);

        // 5. Owner withdraws all funds
        uint256 ownerBalanceBefore = owner.balance;
        vm.prank(owner);
        tipJar.withdraw();

        assertEq(tipJar.getBalance(), 0);
        assertEq(owner.balance, ownerBalanceBefore + expectedTotal);
    }

    /*//////////////////////////////////////////////////////////////
                            EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function testVerySmallCurrencyAmounts() public {
        // Test with 1 unit of currency (0.00000001 USD)
        uint256 smallAmount = 1;
        uint256 expectedWei = tipJar.convertForeignCurrencyToWei("USD", smallAmount);

        vm.prank(user1);
        tipJar.tipInCurrency{value: expectedWei}("USD", smallAmount);

        assertEq(tipJar.getContribution(user1), expectedWei);
    }

    function testVeryLargeExchangeRate() public {
        uint256 largeRate = type(uint128).max;

        vm.prank(owner);
        tipJar.setExchangeRate("EXPENSIVE", largeRate);

        assertEq(tipJar.getExchangeRate("EXPENSIVE"), largeRate);
    }

    function testOverwriteExchangeRate() public {
        uint256 originalRate = tipJar.getExchangeRate("USD");
        uint256 newRate = originalRate * 2;

        vm.prank(owner);
        tipJar.setExchangeRate("USD", newRate);

        assertEq(tipJar.getExchangeRate("USD"), newRate);
        assertNotEq(tipJar.getExchangeRate("USD"), originalRate);
    }
}
