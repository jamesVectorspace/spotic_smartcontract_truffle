// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SPOTICTOKEN.sol" ;
import "./tUSDT.sol";
import "./tUSDC.sol";

contract Exchange {
    SPOTICTOKEN private SPOTIC;

    address exchange_owner ;

    uint256 exchange_rate = 3500;
    uint256 hardCap = 3000000;
    uint256 openTime;
    uint256 seasonPeriod = 31536000;
    uint256 limitedCnt = 3000;
    uint256 totalSupply = 15000000000;

    address _SOPOTIC_TOKEN_ADDR;
    address _tUSDC_TOKEN_ADDR;
    address _tUSDT_TOKEN_ADDR;

    bool openedExchange = false;

    constructor ( address _SPOTIC, address _tUSDT, address _tUSDC ) {
        openTime = block.timestamp;

        SPOTIC = SPOTICTOKEN(_SPOTIC);

        exchange_owner = msg.sender ;
        _SOPOTIC_TOKEN_ADDR = _SPOTIC;
        _tUSDC_TOKEN_ADDR = _tUSDC;
        _tUSDT_TOKEN_ADDR = _tUSDT;

        SPOTIC.setOwnerAddress(address(this));
        SPOTIC.mint(address(this), totalSupply);
    }

    function setExchangeOwner(address _new_owner) public onlyOwner {
        exchange_owner = _new_owner;
    }

    function getExchangeOwner() external view returns(address) {
        return exchange_owner;
    }

    function getTotalSupply() external view returns(uint256) {
        return totalSupply;
    }

    function openExchangeDapp() public onlyOwner {
        openedExchange = true;
    }

    function closeExchangeDapp() public onlyOwner {
        openedExchange = false;
    }

    function getOpenStatus() external view returns(bool) {
        return openedExchange;
    }

    function getSeasonPeriod() external view returns(uint256) {
        return seasonPeriod;
    }

    function getHardCap() external view returns(uint256) {
        return hardCap;
    }

    function getLimitedCnt() external view returns(uint256) {
        return limitedCnt;
    }

    function setLimitedCnt(uint256 _new_limited_cnt) public onlyOwner {
        limitedCnt = _new_limited_cnt;
    }

    function setHardCap(uint256 _hardCap) public onlyOwner {
        hardCap = _hardCap;
    }

    function setExchangeRate(uint256 new_rate) public onlyOwner {
        exchange_rate = new_rate;
    }

    function getExchangeRate() external view returns(uint256) {
        return exchange_rate;
    }

    function transferWithUSDT(uint256 transfer_amount, uint256 usdt_amount) external isLockedHardCap isOpenExchangeDapp isFinishedSeasonPeriod isOverflowLimitedCnt(transfer_amount) payable {
        hardCap -= transfer_amount;
        IERC20(_tUSDT_TOKEN_ADDR).transferFrom(msg.sender, address(this), usdt_amount);
        SPOTIC.tranferToken(msg.sender, transfer_amount);
    }

    function transferWithUSDC(uint256 transfer_amount, uint256 usdc_amount) external isLockedHardCap isOpenExchangeDapp isFinishedSeasonPeriod isOverflowLimitedCnt(transfer_amount) payable {
        hardCap -= transfer_amount;
        IERC20(_tUSDC_TOKEN_ADDR).transferFrom(msg.sender, address(this), usdc_amount);
        SPOTIC.tranferToken(msg.sender, transfer_amount);
    }

    function transfer(uint256 transfer_amount) external isLockedHardCap isOpenExchangeDapp isFinishedSeasonPeriod isOverflowLimitedCnt(transfer_amount) payable {
        hardCap -= transfer_amount / exchange_rate;
        SPOTIC.tranferToken(msg.sender, transfer_amount);
    }

    function retransfer(uint256 retransfer_amount) external isLockedHardCap isOpenExchangeDapp isFinishedSeasonPeriod isOverflowLimitedCnt(retransfer_amount) payable {
        hardCap += retransfer_amount / exchange_rate;
        SPOTIC.retransferToken(msg.sender, address(this), retransfer_amount);
    }

    function getOpenTime() external view returns(uint256) {
        return openTime;
    }

    modifier isLockedHardCap() {
        require(hardCap > 0, "locked hard cap") ;
        _;
    }

    modifier isOpenExchangeDapp() {
        require(openedExchange, "close exchange dapp");
        _;
    }

    modifier isFinishedSeasonPeriod() {
        require(block.timestamp < openTime + seasonPeriod, 'season period was ended');
        _;
    }

    modifier isOverflowLimitedCnt(uint256 transfer_amount) {
        require( limitedCnt > transfer_amount / exchange_rate, 'overflow limited count' );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == exchange_owner, 'not owner');
        _;
    }
}
