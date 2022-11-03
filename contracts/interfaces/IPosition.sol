// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IPosition is IERC1155 {
  function mint(
    address account,
    uint256 id,
    uint256 amount
  ) external returns (bool success);

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) external returns (bool success);
}
