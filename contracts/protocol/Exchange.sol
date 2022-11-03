// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPosition.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange is Ownable {
  struct Game {
    bytes4 team1;
    bytes4 team2;
    bytes8 series;
    uint32 startTime;
    uint32 endTime;
    bool completed;
    bool result;
  }

  address public position;
  address public cash;
  uint128 public gameCounter;

  // from gameId
  mapping(uint128 => Game) public games;
  // from poolId
  mapping(uint256 => uint128) public makerBalance;
  mapping(uint256 => uint128) public takerBalance;
  mapping(uint256 => uint128) public matchedBalance;

  function initialize(address _position, address _cash) external onlyOwner {
    position = _position;
    cash = _cash;
  }

  function poolId(uint16 odds, uint128 gameId) public view returns (uint256 id) {}

  function tokenIds(uint256 pool) public view returns (uint256 makerId, uint256 takerId) {}

  function tokenData(uint256 id)
    public
    view
    returns (
      uint8 side,
      uint16 odds,
      uint128 gameId
    )
  {}

  function startGame(
    bytes4 team1,
    bytes4 team2,
    bytes8 series,
    uint32 startTime
  ) external onlyOwner {
    require(startTime > block.timestamp, "Invalid Start");
    Game memory game = Game(team1, team2, series, startTime, startTime + 4 hours, false, false);
    games[gameCounter] = game;
    gameCounter++;
  }

  function endGame(uint128 gameId, bool result) external onlyOwner {
    require(games[gameId].startTime != 0, "Game doesnt exist");
    require(games[gameId].endTime < block.timestamp, "Game in Progress");
    games[gameId].completed = true;
    games[gameId].result = result;
  }

  function make(
    uint16 odds,
    uint128 gameId,
    uint128 value
  ) external {
    require(games[gameId].startTime - block.timestamp <= 6 hours, "Bets not Open");
    uint256 pool = poolId(odds, gameId);
    (uint256 makerId, uint256 takerId) = tokenIds(pool);
    uint128 amount = (odds * value) / 1e2;
    makerBalance[pool] += amount;
    IPosition(position).mint(msg.sender, makerId, value);
    IPosition(position).mint(address(this), takerId, value);
    IERC20(cash).transferFrom(msg.sender, address(this), amount);
  }

  function take(
    uint16 odds,
    uint128 gameId,
    uint128 value
  ) external {
    require(games[gameId].startTime - block.timestamp <= 6 hours, "Bets not Open");
    uint256 pool = poolId(odds, gameId);
    (, uint256 takerId) = tokenIds(pool);
    require(IPosition(position).balanceOf(address(this), takerId) >= value, "Not enough Market");
    uint128 amount = (odds * value) / 1e2;
    takerBalance[pool] += value;
    matchedBalance[pool] += amount;
    IPosition(position).safeTransferFrom(address(this), msg.sender, takerId, value, "");
    IERC20(cash).transferFrom(msg.sender, address(this), value);
  }

  function redeem(uint256 tokenId, uint128 value) external {
    uint256 tokenBalance = IPosition(position).balanceOf(msg.sender, tokenId);
    require(tokenBalance >= value, "Low Balance");
    (uint8 side, uint16 odds, uint128 gameId) = tokenData(tokenId);
    require(!games[gameId].completed, "Game not Completed");
    uint256 pool = poolId(odds, gameId);
    uint128 amount;
    if (side == 0) {
      if (games[gameId].result) {
        // maker loses
        uint128 makerRatio = uint128((value * 1e6) / IPosition(position).totalSupply(tokenId));
        amount = (makerBalance[pool] + takerBalance[pool] - matchedBalance[pool]) * makerRatio;
      } else {
        // maker wins
        uint128 makerRatio = uint128((value * 1e6) / IPosition(position).totalSupply(tokenId));
        amount = (makerBalance[pool] + takerBalance[pool]) * makerRatio;
      }
    } else {
      if (games[gameId].result) {
        // taker wins
        amount = (odds * value) / 1e2;
      }
    }
    IERC20(cash).transfer(msg.sender, amount);
    IPosition(position).burn(msg.sender, tokenId, value);
  }
}
