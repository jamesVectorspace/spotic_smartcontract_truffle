// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract SPOTICTOKEN is ERC20, ERC20Burnable {
    address owner = address(0);

    constructor() ERC20("SPOTICTOKEN", "SPOTIC") {
    }

    function setOwnerAddress(address _owner) public {
        require(owner == address(0), "can't change owner address") ;

        owner = _owner;
    }

    function mint(address to, uint256 amount) public isOwner {
        _mint(to, amount * 10 ** decimals());
    }

    function tranferToken(address _to, uint256 amount) public isOwner {
        transfer(_to,  amount * 10 ** decimals());
    }

    function retransferToken(address _from, address _to, uint256 amount) public isOwner {
        transferFrom(_from, _to, amount * 10 ** decimals());
    }

    modifier isOwner {
        require(msg.sender == owner);
        _;
    }
}