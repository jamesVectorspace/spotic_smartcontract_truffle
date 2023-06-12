// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Spotic.sol";

contract SalesToken is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address payable public investorAddr;
    address payable public ownerAddr;

    EnumerableSet.AddressSet tokenAddresses;

    // AggregatorV3Interface internal priceFeed;

    uint256 public bnbRate = 3500;
    uint256 public tokenRate = 11;

    uint256 public hardCap = 300000000000000000000000000;
    uint256 public startTime;
    uint256 public endTime = 1690789011;
    uint256 public purchaseLimit = 10000000000000000000000;
    uint256 public referralPercent = 1000; // 10% = 1000 / 10000

    bool private paused = false;
    bool private unlimited = false;

    address public spoticAddr;

    mapping(address => uint256) purchasedAmount;

    constructor() {
        startTime = block.timestamp;
        investorAddr = payable(msg.sender);
        ownerAddr = payable(msg.sender);
        // get rate bnb/usd
        // priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        // (, int256 price, , , ) = priceFeed.latestRoundData();

        // // convert the price from 8 decimal places to 18 decimal places
        // uint256 decimals = uint256(priceFeed.decimals());
        // uint256 rate = uint256(price) * 10**(18 - decimals);

        // tokenRate = rate;
    }

    function checkIfOwner() public view returns (bool) {
        return msg.sender == ownerAddr || msg.sender == investorAddr;
    }

    function contractStarted() internal view returns (bool) {
        return block.timestamp >= startTime;
    }

    function getExchangeOwner() public view returns (address) {
        return investorAddr;
    }

    function getBnbRate() public view returns (uint256) {
        return bnbRate;
    }

    function getPurchaseLimit() public view returns (uint256) {
        return purchaseLimit;
    }

    function getStatusOfLimit() public view returns (bool) {
        return unlimited;
    }

    function getStartedTime() public view returns (uint256) {
        return startTime;
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    function getStatus() public view returns (bool) {
        return paused;
    }

    function getHardCap() public view returns (uint256) {
        return hardCap;
    }

    function getReferralPercent() public view returns (uint256) {
        return referralPercent;
    }

    function addToken(address tokenAddress) external onlyOwner {
        if (!tokenAddresses.contains(tokenAddress)) {
            tokenAddresses.add(tokenAddress);
        }
    }

    function setBnbRate(uint256 _bnbRate) external onlyOwner {
        bnbRate = _bnbRate;
    }

    function setInvestor(address _investorAddr) external onlyOwner {
        investorAddr = payable(_investorAddr);
    }

    function setHardCap(uint256 _hardCap) external onlyOwner {
        hardCap = _hardCap;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    function setPurchaseLimit(uint256 _purchaseLimit) external onlyOwner {
        purchaseLimit = _purchaseLimit;
        unlimited = false;
    }

    function setReferralPercent(uint256 _referralPercent) external onlyOwner {
        referralPercent = _referralPercent;
    }

    function setSpoticAddr(address _spoticAddr) external onlyOwner {
        spoticAddr = _spoticAddr;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setUnlimited() external onlyOwner {
        unlimited = true;
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        Spotic spoticInstance = Spotic(spoticAddr);
        spoticInstance.mint(amount);
        return true;
    }

    function burn(uint256 amount) public onlyOwner returns (bool) {
        Spotic spoticInstance = Spotic(spoticAddr);
        spoticInstance.burn(amount);
        return true;
    }

    function purchaseWithBnb() external payable isPaused existedSpotic {
        IBEP20 spoticInstance = IBEP20(spoticAddr);
        uint256 balance = spoticInstance.balanceOf(address(this));
        uint256 amount = msg.value * bnbRate;
        require(amount > 0, "You have to purchase more than zero");
        require(amount < balance, "You cant purchase more than balance");
        if (!unlimited) {
            require(
                purchaseLimit > purchasedAmount[msg.sender] + amount,
                "You cant purchase more than limit"
            );
        }

        spoticInstance.transfer(msg.sender, amount);

        purchasedAmount[msg.sender] += amount;
        hardCap -= amount;
    }

    function referralPurchaseWithBnb(
        address _referrencedAddress
    ) external payable isPaused existedSpotic {
        IBEP20 spoticInstance = IBEP20(spoticAddr);
        uint256 balance = spoticInstance.balanceOf(address(this));
        uint256 amount = msg.value * bnbRate;
        require(amount > 0, "You have to purchase more than zero");
        require(amount < balance, "You cant purchase more than balance");
        if (!unlimited) {
            require(
                purchaseLimit > purchasedAmount[msg.sender] + amount,
                "You cant purchase more than limit"
            );
        }
        require(
            _referrencedAddress != address(0),
            "Referrenced Address should not zero"
        );
        uint256 referrencedAmount = amount.mul(referralPercent).div(10000);

        spoticInstance.transfer(msg.sender, amount - referrencedAmount);

        purchasedAmount[msg.sender] += amount - referrencedAmount;
        hardCap -= amount;
    }

    function purchaseBnbWithSpotic(
        uint256 spoticAmount
    ) external payable isPaused existedSpotic {
        IBEP20 spoticInstance = IBEP20(spoticAddr);
        uint256 balance = spoticInstance.balanceOf(msg.sender);
        uint256 amount = spoticAmount.div(bnbRate);
        require(amount > 0, "You have to purchase more than zero");
        require(amount < balance, "You cant purchase more than balance");

        spoticInstance.transferFrom(msg.sender, address(this), spoticAmount);
        payable(msg.sender).transfer(amount);
    }

    function referralPurchaseBnbWithSpotic(
        address _referrencedAddress,
        uint256 spoticAmount
    ) external payable isPaused existedSpotic {
        IBEP20 spoticInstance = IBEP20(spoticAddr);
        uint256 balance = spoticInstance.balanceOf(msg.sender);
        uint256 amount = spoticAmount * bnbRate;
        require(amount > 0, "You have to purchase more than zero");
        require(amount < balance, "You cant purchase more than balance");

        require(
            _referrencedAddress != address(0),
            "Referrenced Address should not zero"
        );
        uint256 referrencedAmount = amount.mul(referralPercent).div(10000);

        payable(_referrencedAddress).transfer(referrencedAmount);
        payable(msg.sender).transfer(amount - referrencedAmount);

        spoticInstance.transferFrom(msg.sender, address(this), spoticAmount);

        // purchasedAmount[msg.sender] -= spoticAmount;
        // hardCap += spoticAmount;
    }

    function purchaseWithToken(
        uint256 tokenAmount,
        address tokenAddress
    ) external payable isPaused existedSpotic {
        IBEP20 tokenInstance = IBEP20(tokenAddress);
        IBEP20 spoticInstance = IBEP20(spoticAddr);

        uint256 balance = tokenInstance.balanceOf(msg.sender);
        uint256 amount = tokenAmount * tokenRate;
        require(amount > 0, "You have to purchase more than zero");
        require(amount < balance, "You cant purchase more than balance");
        require(
            tokenAddresses.contains(tokenAddress),
            "This token is not approved yet"
        );

        if (!unlimited) {
            require(
                purchaseLimit > purchasedAmount[msg.sender] + amount,
                "You cant purchase more than limit"
            );
        }

        spoticInstance.transfer(msg.sender, amount);
        tokenInstance.transferFrom(msg.sender, address(this), tokenAmount);

        purchasedAmount[msg.sender] += amount;
        hardCap -= amount;
    }

    function referralPurchaseWithToken(
        address _referrencedAddress,
        uint256 tokenAmount,
        address tokenAddress
    ) external isPaused existedSpotic {
        IBEP20 tokenInstance = IBEP20(tokenAddress);
        IBEP20 spoticInstance = IBEP20(spoticAddr);
        uint256 balance = tokenInstance.balanceOf(msg.sender);
        uint256 amount = tokenAmount * tokenRate;
        require(amount > 0, "You have to purchase more than zero");
        require(amount < balance, "You cant purchase more than balance");
        require(
            tokenAddresses.contains(tokenAddress),
            "This token is not approved yet"
        );

        if (!unlimited) {
            require(
                purchaseLimit > purchasedAmount[msg.sender] + amount,
                "You cant purchase more than limit"
            );
        }
        require(
            _referrencedAddress != address(0),
            "Referrenced Address should not zero"
        );
        uint256 referrencedAmount = amount.mul(referralPercent).div(10000);

        spoticInstance.transfer(msg.sender, amount - referrencedAmount);
        spoticInstance.transfer(_referrencedAddress, referrencedAmount);
        tokenInstance.transferFrom(msg.sender, address(this), tokenAmount);

        purchasedAmount[msg.sender] += amount - referrencedAmount;
        hardCap -= amount;
    }

    function purchaseTokenWithSpotic(
        uint256 spoticAmount,
        address tokenAddress
    ) external payable isPaused existedSpotic {
        IBEP20 tokenInstance = IBEP20(tokenAddress);
        IBEP20 spoticInstance = IBEP20(spoticAddr);
        uint256 balance = spoticInstance.balanceOf(msg.sender);
        uint256 amount = spoticAmount.div(tokenRate);
        require(amount > 0, "You have to purchase more than zero");
        require(amount < balance, "You cant purchase more than balance");
        require(
            tokenAddresses.contains(tokenAddress),
            "This token is not approved yet"
        );

        spoticInstance.transferFrom(msg.sender, address(this), spoticAmount);
        tokenInstance.transfer(msg.sender, amount);

        // purchasedAmount[msg.sender] -= spoticAmount;
        // hardCap += spoticAmount;
    }

    function referralPurchaseTokenWithSpotic(
        address _referrencedAddress,
        uint256 spoticAmount,
        address tokenAddress
    ) external payable isPaused existedSpotic {
        IBEP20 tokenInstance = IBEP20(tokenAddress);
        IBEP20 spoticInstance = IBEP20(spoticAddr);
        uint256 balance = tokenInstance.balanceOf(msg.sender);
        uint256 amount = spoticAmount.div(tokenRate);
        require(amount > 0, "You have to purchase more than zero");
        require(amount < balance, "You cant purchase more than balance");
        require(
            tokenAddresses.contains(tokenAddress),
            "This token is not approved yet"
        );
        if (!unlimited) {
            require(
                purchaseLimit > purchasedAmount[msg.sender] + amount,
                "You cant purchase more than limit"
            );
        }
        require(
            _referrencedAddress != address(0),
            "Referrenced Address should not zero"
        );
        uint256 referrencedAmount = amount.mul(referralPercent).div(10000);

        tokenInstance.transfer(msg.sender, amount - referrencedAmount);
        tokenInstance.transfer(_referrencedAddress, referrencedAmount);
        spoticInstance.transferFrom(msg.sender, address(this), spoticAmount);

        // purchasedAmount[msg.sender] += spoticAmount;
        // hardCap += spoticAmount;
    }

    function withdrawBnb() external onlyInvestor {
        payable(address(msg.sender)).transfer(address(this).balance);
    }

    function withdrawAll() external onlyInvestor {
        for (uint256 i = 0; i < tokenAddresses.length(); i++) {
            IBEP20 tokenInstance = IBEP20(tokenAddresses.at(i));

            tokenInstance.transfer(
                msg.sender,
                tokenInstance.balanceOf(address(this))
            );
            tokenInstance.transfer(
                msg.sender,
                tokenInstance.balanceOf(address(this))
            );
        }

        payable(address(msg.sender)).transfer(address(this).balance);
    }

    function getBnbBalance() public view returns (uint256 bnbAmount) {
        return address(this).balance;
    }

    function getTokenBalance(
        address tokenAddress
    ) public view returns (uint256 bnbAmount) {
        IBEP20 tokenInstance = IBEP20(tokenAddress);
        return tokenInstance.balanceOf(address(this));
    }

    modifier onlyInvestor() {
        require(msg.sender == investorAddr, "not owner");
        _;
    }

    modifier isPaused() {
        require(!paused, "purchasing is paused");
        _;
    }

    modifier existedSpotic() {
        require(spoticAddr != address(0), "Spotic Address is not set");
        _;
    }
}
