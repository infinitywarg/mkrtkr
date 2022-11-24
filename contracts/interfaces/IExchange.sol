// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IExchange {
  function initialize(address _coupon, address _cash) external;

  function startGame(
    bytes4 team1,
    bytes4 team2,
    bytes8 series,
    uint32 startTime
  ) external;

  function endGame(uint64 gameId, bool result) external;

  function make(
    uint16 odds,
    uint64 gameId,
    uint128 value
  ) external;

  function take(
    uint16 odds,
    uint64 gameId,
    uint128 value
  ) external;

  function redeem(uint256 tokenId, uint128 value) external;
}
