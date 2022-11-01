// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

library SmartToken {
  uint256 private constant BITSHIFT_EVENTID = 128;
  uint256 private constant BITSHIFT_POSITION = 120;
  uint256 private constant BITSHIFT_ODDS = 104;
  uint256 private constant BITSHIFT_VALUE = 40;
  uint256 private constant BITMASK_EVENTID = 2**128 - 1;
  uint256 private constant BITMASK_POSITION = 2**8 - 1;
  uint256 private constant BITMASK_ODDS = 2**16 - 1;
  uint256 private constant BITMASK_VALUE = 2**64 - 1;
  uint256 private constant BITMASK_POOLBYTES = 2**40 - 1;
  uint8 private constant MAKER_POSITION = 0;
  uint8 private constant TAKER_POSITION = 1;
  uint16 private constant MAX_ODDS = 10000;
  uint16 private constant MIN_ODDS = 0;
  uint64 private constant MAX_VALUE = 1000000 * 1e6;
  uint64 private constant MIN_VALUE = 100 * 1e6;

  struct Metadata {
    uint128 eventId;
    uint8 position;
    uint16 odds;
    uint64 value;
  }

  function tokenId(Metadata memory data) internal view returns (uint256 id) {
    // eventId check to happen in the pool contract
    require(data.position == MAKER_POSITION || data.position == TAKER_POSITION, "Invalid Position");
    require(data.odds <= MAX_ODDS && data.odds >= MIN_ODDS, "Invalid Odds");
    require(data.value <= MAX_VALUE && data.value >= MIN_VALUE, "Invalid Value");
    id =
      (uint256(data.eventId) << BITSHIFT_EVENTID) |
      (uint256(data.position) << BITSHIFT_POSITION) |
      (uint256(data.odds) << BITSHIFT_ODDS) |
      (uint256(data.value) << BITSHIFT_VALUE) |
      uint256(uint40(uint160(address(this))));
  }

  function tokenData(uint256 id) internal view returns (Metadata memory data) {
    require(uint40(uint160(address(this))) == uint40(id & BITMASK_POOLBYTES), "Invalid Pool");

    data.eventId = uint128((id & (BITMASK_EVENTID << BITSHIFT_EVENTID)) >> BITSHIFT_EVENTID);

    uint8 position = uint8((id & (BITMASK_POSITION << BITSHIFT_POSITION)) >> BITSHIFT_POSITION);
    require(position == MAKER_POSITION || position == TAKER_POSITION, "Invalid Position");

    uint16 odds = uint16((id & (BITMASK_ODDS << BITSHIFT_ODDS)) >> BITSHIFT_ODDS);
    require(odds <= MAX_ODDS && odds >= MIN_ODDS, "Invalid Odds");

    uint64 value = uint64((id & (BITMASK_VALUE << BITSHIFT_VALUE)) >> BITSHIFT_VALUE);
    require(value <= MAX_VALUE && value >= MIN_VALUE, "Invalid Value");

    data.position = position;
    data.odds = odds;
    data.value = value;
  }

  //["12345","1","182","1200000000"]
}
