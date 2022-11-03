// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Cash is ERC20 {
  mapping(address => uint256) public lastDrop;

  constructor() ERC20("MkrTkr", "MKTK") {
    _mint(address(this), 1000000000000 * 10**decimals());
  }

  function faucet(uint256 amount) external {
    require(amount <= 1000 * 10**decimals(), "Dont be Greedy");
    // require(block.timestamp - lastDrop[msg.sender] >= 3 hours, "Let it Cool");
    lastDrop[msg.sender] = block.timestamp;
    _transfer(address(this), msg.sender, amount);
  }

  function decimals() public pure override returns (uint8) {
    return 6;
  }
}
