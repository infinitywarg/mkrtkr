// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPosition.sol";
import "../libraries/SmartToken.sol";

contract Pool is Ownable {
  address public position;

  struct EventData {
    bytes32 name;
    uint256 start;
    uint256 end;
    bool completed;
    bool result;
  }

  mapping(uint128 => EventData) public events;
  mapping(uint128 => mapping(uint16 => uint64)) public makerPositions;
  mapping(uint128 => mapping(uint16 => uint64)) public takerPositions;

  function initialize(address _position) external onlyOwner {
    position = _position;
  }

  function create(
    bytes32 name,
    uint256 start,
    uint256 end
  ) external onlyOwner {
    require(start > block.timestamp && end > start, "Invalid Timestamps");
    EventData memory e = EventData(name, start, end, false, false);
    uint128 id = uint128(bytes16(keccak256(abi.encode(e))));
    events[id] = e;
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

  function make(
    uint128 eventId,
    uint16 odds,
    uint64 value
  ) external {
    uint256 makerId = tokenId(SmartToken.Metadata(eventId, 0, odds, value));
    uint256 takerId = tokenId(SmartToken.Metadata(eventId, 1, odds, value));
    // validate if sender has enough collateral
    makerPositions[eventId][odds] += (odds * value) / 1e2;
    IPosition(position).mint(msg.sender, makerId, value, "");
    IPosition(position).mint(address(this), takerId, value, "");
  }

  function take(
    uint128 eventId,
    uint16 odds,
    uint64 value
  ) external {
    uint256 makerId = tokenId(SmartToken.Metadata(eventId, 0, odds, value));
    uint256 takerId = tokenId(SmartToken.Metadata(eventId, 1, odds, value));
    require(IPosition(position).balanceOf(address(this), takerId) >= value, "Not enough Market");
    takerPositions[eventId][odds] += value;
    // validate if sender has enough collateral
  }

  // no need embded value in the tokenId, instead embded mint_timestamp
  // update the SmartToken library
  // to calculate the timebased claim on the pool at the time of redemption for MAKERS
}
