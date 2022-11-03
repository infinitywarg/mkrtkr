// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../interfaces/IPosition.sol";

contract Position is IPosition, ERC1155 {
  address public immutable pool;
  mapping(uint256 => uint256) public supply;

  constructor(address _pool) ERC1155("") {
    pool = _pool;
  }

  modifier onlyPool() {
    require(msg.sender == pool, "Caller not Pool");
    _;
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount
  ) external onlyPool returns (bool success) {
    _mint(account, id, amount, "");
    success = true;
  }

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) external onlyPool returns (bool success) {
    _burn(account, id, value);
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
