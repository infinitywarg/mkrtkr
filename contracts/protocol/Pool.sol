// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPosition.sol";
import "../libraries/SmartToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Pool is Ownable {
  address public position;
  address public cash;

  struct EventData {
    bytes22 name;
    uint32 start;
    uint32 end;
    bool completed;
    bool result;
  }

  mapping(uint96 => EventData) public events;
  mapping(uint96 => mapping(uint16 => uint64)) public makerBalance;
  mapping(uint96 => mapping(uint16 => uint64)) public takerBalance;

  function initialize(address _position, address _cash) external onlyOwner {
    position = _position;
    cash = _cash;
  }

  function create(
    bytes22 name,
    uint32 start,
    uint32 end
  ) external onlyOwner {
    require(start > block.timestamp && end > start, "Invalid Timestamps");
    EventData memory e = EventData(name, start, end, false, false);
    uint96 id = uint96(bytes12(keccak256(abi.encode(e))));
    events[id] = e;
  }

  function complete(uint96 eventId, bool result) external onlyOwner {
    require(events[eventId].end != 0, "Invalid Event");
    require(events[eventId].end < block.timestamp, "Event in Progress");
    events[eventId].completed = true;
    events[eventId].result = result;
  }

  function tokenId(
    uint16 odds,
    uint64 value,
    uint96 eventId
  ) public view returns (uint256 makerId, uint256 takerId) {
    require(events[eventId].end != 0, "Invalid Event");
    SmartToken.Metadata memory makerData = SmartToken.Metadata(0, odds, value, uint32(block.timestamp), eventId);
    SmartToken.Metadata memory takerData = SmartToken.Metadata(0, odds, value, uint32(block.timestamp), eventId);
    makerId = SmartToken.tokenId(makerData);
    takerId = SmartToken.tokenId(takerData);
  }

  function tokenData(uint256 id) public view returns (SmartToken.Metadata memory data) {
    data = SmartToken.tokenData(id);
  }

  function make(
    uint16 odds,
    uint64 value,
    uint96 eventId
  ) external {
    // allow bets only upto 6 hours before event starts
    require(events[eventId].start - block.timestamp <= 6 hours, "Bets not Open");
    (uint256 makerId, uint256 takerId) = tokenId(odds, value, eventId);
    uint64 amount = (odds * value) / 1e2;
    makerBalance[eventId][odds] += amount;
    IPosition(position).mint(msg.sender, makerId, value);
    IPosition(position).mint(address(this), takerId, value);
    IERC20(cash).transferFrom(msg.sender, address(this), amount);
  }

  function take(
    uint16 odds,
    uint64 value,
    uint96 eventId
  ) external {
    (uint256 makerId, uint256 takerId) = tokenId(odds, value, eventId);
    IPosition(position).safeTransferFrom(address(this), msg.sender, takerId, value, "");
    IERC20(cash).transferFrom(msg.sender, address(this), value);
  }

  function redeem(uint256 id, uint64 value) external {
    require(IPosition(position).balanceOf(msg.sender, id) >= value, "Low Balance");
    SmartToken.Metadata memory data = tokenData(id);
    require(events[data.eventId].completed, "Event in Progress");

    if (data.position == 0) {
      if (events[data.eventId].result) {
        // event happened, maker loses
        IERC20(cash).transfer(msg.sender, value);
      } else {
        // event didnt happen, maker wins
        IERC20(cash).transfer(msg.sender, (data.odds * value) / 1e2);
      }
    } else {
      if (events[data.eventId].result) {
        // event happened, taker wins
        IERC20(cash).transfer(msg.sender, (data.odds * value) / 1e2);
      }
    }

    IPosition(position).burn(msg.sender, id, value);
  }
}
