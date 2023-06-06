// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract tUSDC is ERC20, ERC20Burnable {
    constructor() ERC20("USDCTOKEN", "tUSDC") {
        _mint(0x51027631B9DEF86e088C33368eC4E3A4BE0aD264, 10000000000 * 10 ** decimals());
    }
}