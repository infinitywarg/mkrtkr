// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IPosition is IERC1155 {
  function supply(uint256 id) external view returns (uint256 total);

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external returns (bool success);

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external returns (bool success);

  function burn(
    address from,
    uint256 id,
    uint256 value
  ) external returns (bool success);

  function burnBatch(
    address from,
    uint256[] memory ids,
    uint256[] memory values
  ) external returns (bool success);
}
