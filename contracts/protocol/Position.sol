// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../interfaces/IPosition.sol";

contract Position is IPosition, ERC1155 {
  address public pool;
  mapping(uint256 => uint256) public supply;

  constructor() ERC1155("") {}

  modifier onlyPool() {
    require(msg.sender == pool, "Caller Not Pool");
    _;
  }

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external onlyPool returns (bool success) {
    _mint(to, id, amount, data);
    success = true;
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external onlyPool returns (bool success) {
    _mintBatch(to, ids, amounts, data);
    success = true;
  }

  function burn(
    address from,
    uint256 id,
    uint256 value
  ) external onlyPool returns (bool success) {
    _burn(from, id, value);
    success = true;
  }

  function burnBatch(
    address from,
    uint256[] memory ids,
    uint256[] memory values
  ) external onlyPool returns (bool success) {
    _burnBatch(from, ids, values);
    success = true;
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    if (from == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        supply[ids[i]] += amounts[i];
      }
    }

    if (to == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        uint256 id = ids[i];
        uint256 amount = amounts[i];
        uint256 _supply = supply[id];
        require(_supply >= amount, "Burn exceeds Supply");
        unchecked {
          supply[id] = _supply - amount;
        }
      }
    }
  }
}
