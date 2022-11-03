// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICoupon.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange is Ownable {
  uint16 private constant MAX_ODDS = 9999;
  uint16 private constant MIN_ODDS = 1;
  uint64 private constant MAX_VALUE = 10000000 * 1e6;
  uint64 private constant MIN_VALUE = 10 * 1e6;
  uint256 private constant BIT_PREFIX = 0;
  uint256 private constant BITMASK_POSITION = 2**8 - 1;
  uint256 private constant BITMASK_ODDS = 2**16 - 1;
  uint256 private constant BITMASK_GAMEID = 2**64 - 1;
  uint256 private constant BITMASK_EXCHANGE = 2**160 - 1;
  uint256 private constant MAKER_POSITION = 0;
  uint256 private constant TAKER_POSITION = 1;

  struct Game {
    bytes4 team1;
    bytes4 team2;
    bytes8 series;
    uint32 startTime;
    uint32 endTime;
    bool completed;
    bool result;
  }

  ICoupon private coupon;
  IERC20 private cash;
  uint64 public gameCounter;

  // from gameId
  mapping(uint64 => Game) public games;
  // from poolId
  mapping(uint256 => uint128) public makerBalance;
  mapping(uint256 => uint128) public takerBalance;
  mapping(uint256 => uint128) public matchedBalance;

  function initialize(address _coupon, address _cash) external onlyOwner {
    coupon = ICoupon(_coupon);
    cash = IERC20(_cash);
  }

  function poolId(uint16 odds, uint64 gameId) public view returns (uint256 id) {
    require(odds <= MAX_ODDS && odds >= MIN_ODDS, "Invalid Odds");
    require(games[gameId].startTime != 0, "Invalid Game");
    id = (BIT_PREFIX << 240) | (uint256(odds) << 224) | (uint256(gameId) << 160) | uint256(uint160(address(this)));
  }

  function tokenIds(uint256 pool) public view returns (uint256 makerId, uint256 takerId) {
    require(address(uint160(pool & BITMASK_EXCHANGE)) == address(this), "Invalid Pool Id");
    makerId = (BIT_PREFIX << 248) | (MAKER_POSITION << 240) | pool;
    takerId = (BIT_PREFIX << 248) | (TAKER_POSITION << 240) | pool;
  }

  function tokenData(uint256 id)
    public
    view
    returns (
      uint8 position,
      uint16 odds,
      uint64 gameId
    )
  {
    require(address(uint160(id & BITMASK_EXCHANGE)) == address(this), "Invalid Pool Id");
    position = uint8((id & (BITMASK_POSITION << 240)) >> 240);
    odds = uint16((id & (BITMASK_ODDS << 224)) >> 224);
    gameId = uint64((id & (BITMASK_GAMEID << 160)) >> 160);
  }

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

  function endGame(uint64 gameId, bool result) external onlyOwner {
    require(games[gameId].startTime != 0, "Game doesnt exist");
    require(games[gameId].endTime < block.timestamp, "Game in Progress");
    games[gameId].completed = true;
    games[gameId].result = result;
  }

  function make(
    uint16 odds,
    uint64 gameId,
    uint128 value
  ) external {
    require(games[gameId].startTime - block.timestamp <= 6 hours, "Bets not Open");
    uint256 pool = poolId(odds, gameId);
    (uint256 makerId, uint256 takerId) = tokenIds(pool);
    uint128 amount = (odds * value) / 1e2;
    makerBalance[pool] += amount;
    coupon.mint(msg.sender, makerId, value);
    coupon.mint(address(this), takerId, value);
    cash.transferFrom(msg.sender, address(this), amount);
  }

  function take(
    uint16 odds,
    uint64 gameId,
    uint128 value
  ) external {
    require(games[gameId].startTime - block.timestamp <= 6 hours, "Bets not Open");
    uint256 pool = poolId(odds, gameId);
    (, uint256 takerId) = tokenIds(pool);
    require(coupon.balanceOf(address(this), takerId) >= value, "Not enough Market");
    uint128 amount = (odds * value) / 1e2;
    takerBalance[pool] += value;
    matchedBalance[pool] += amount;
    coupon.safeTransferFrom(address(this), msg.sender, takerId, value, "");
    cash.transferFrom(msg.sender, address(this), value);
  }

  function redeem(uint256 tokenId, uint128 value) external {
    uint256 tokenBalance = coupon.balanceOf(msg.sender, tokenId);
    require(tokenBalance >= value, "Low Balance");
    (uint8 side, uint16 odds, uint64 gameId) = tokenData(tokenId);
    require(!games[gameId].completed, "Game not Completed");
    uint256 pool = poolId(odds, gameId);
    uint128 amount;
    if (side == 0) {
      if (games[gameId].result) {
        // maker loses
        uint128 makerRatio = uint128((value * 1e6) / coupon.totalSupply(tokenId));
        amount = (makerBalance[pool] + takerBalance[pool] - matchedBalance[pool]) * makerRatio;
      } else {
        // maker wins
        uint128 makerRatio = uint128((value * 1e6) / coupon.totalSupply(tokenId));
        amount = (makerBalance[pool] + takerBalance[pool]) * makerRatio;
      }
    } else {
      if (games[gameId].result) {
        // taker wins
        amount = (odds * value) / 1e2;
      }
    }
    cash.transfer(msg.sender, amount);
    coupon.burn(msg.sender, tokenId, value);
  }
}
