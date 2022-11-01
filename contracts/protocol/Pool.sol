// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/SmartToken.sol";

contract Pool is Ownable {
  struct EventData {
    bytes32 name;
    uint256 start;
    uint256 end;
    bool completed;
    bool result;
  }

  mapping(uint128 => EventData) public events;
  mapping(uint128 => bool) public eventExists;

  function create(
    bytes32 name,
    uint256 start,
    uint256 end
  ) external onlyOwner {
    require(start > block.timestamp && end > start, "Invalid Timestamps");
    EventData memory e = EventData(name, start, end, false, false);
    uint128 id = uint128(bytes16(keccak256(abi.encode(e))));
    events[id] = e;
    eventExists[id] = true;
  }

  function complete(uint128 id, bool result) external onlyOwner {
    require(events[id].end != 0, "Invalid Event");
    require(events[id].end < block.timestamp, "Event in Progress");
    events[id].completed = true;
    events[id].result = result;
  }

  function tokenId(SmartToken.Metadata memory data) public view returns (uint256 id) {
    require(events[data.eventId].end != 0, "Invalid Event");
    id = SmartToken.tokenId(data);
  }

  function tokenData(uint256 id) public view returns (SmartToken.Metadata memory data) {
    data = SmartToken.tokenData(id);
    require(events[data.eventId].end != 0, "Invalid Event");
  }

  function make() external {}

  function take() external {}
}
