// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICoupon.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange is Ownable {
  uint256 private constant MAX_ODDS = 9999;
  uint256 private constant MIN_ODDS = 1;
  uint256 private constant MAX_VALUE = 10000000 * 1e6;
  uint256 private constant MIN_VALUE = 10 * 1e6;
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
  uint256 public gameCounter;
  bool public initialized;

  // from gameId
  mapping(uint256 => Game) public games;
  // from poolId
  mapping(uint256 => uint256) public makerBalance;
  mapping(uint256 => uint256) public takerBalance;
  mapping(uint256 => uint256) public matchedValue;

  modifier whenInitialized() {
    require(initialized, "Not Initialized");
    _;
  }

  function initialize(address _coupon, address _cash) external onlyOwner {
    coupon = ICoupon(_coupon);
    cash = IERC20(_cash);
    initialized = true;
  }

  function poolId(uint256 odds, uint256 gameId) public view returns (uint256 id) {
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
      uint256 position,
      uint256 odds,
      uint256 gameId
    )
  {
    require(address(uint160(id & BITMASK_EXCHANGE)) == address(this), "Invalid Pool Id");
    position = (id & (BITMASK_POSITION << 240)) >> 240;
    odds = (id & (BITMASK_ODDS << 224)) >> 224;
    gameId = (id & (BITMASK_GAMEID << 160)) >> 160;
  }

  function startGame(
    bytes4 team1,
    bytes4 team2,
    bytes8 series,
    uint32 startTime
  ) external onlyOwner whenInitialized {
    require(startTime > block.timestamp, "Invalid Start");
    Game memory game = Game(team1, team2, series, startTime, startTime + 4 hours, false, false);
    games[++gameCounter] = game;
  }

  function endGame(uint256 gameId, bool result) external onlyOwner whenInitialized {
    Game memory game = games[gameId];
    require(game.startTime != 0, "Game doesnt exist");
    require(game.endTime < block.timestamp, "Game in Progress");
    game.completed = true;
    game.result = result;
    games[gameId] = game;
  }

  function make(
    uint256 odds,
    uint256 gameId,
    uint256 value
  ) external whenInitialized {
    Game memory game = games[gameId];
    require(game.startTime - block.timestamp <= 6 hours, "Bets not Open");
    uint256 pool = poolId(odds, gameId);
    (uint256 makerId, ) = tokenIds(pool);
    uint256 amount = (odds * value) / 1e2;
    makerBalance[pool] += amount;
    coupon.mint(msg.sender, makerId, value);
    cash.transferFrom(msg.sender, address(this), amount);
  }

  function take(
    uint256 odds,
    uint256 gameId,
    uint256 value
  ) external whenInitialized {
    Game memory game = games[gameId];
    require(game.startTime - block.timestamp <= 6 hours, "Bets not Open");
    uint256 pool = poolId(odds, gameId);
    (uint256 makerId, uint256 takerId) = tokenIds(pool);
    require(coupon.totalSupply(makerId) - matchedValue[pool] >= value, "Not enough Market");
    takerBalance[pool] += value;
    matchedValue[pool] += value;
    coupon.mint(msg.sender, takerId, value);
    cash.transferFrom(msg.sender, address(this), value);
  }

  function redeem(uint256 tokenId, uint256 value) external whenInitialized {
    uint256 tokenBalance = coupon.balanceOf(msg.sender, tokenId);
    require(tokenBalance >= value, "Low Balance");
    (uint256 side, uint256 odds, uint256 gameId) = tokenData(tokenId);
    Game memory game = games[gameId];
    require(!game.completed, "Game not Completed");
    uint256 pool = poolId(odds, gameId);
    uint256 amount;
    uint256 totalBalance = makerBalance[pool] + takerBalance[pool];
    if (side == 0) {
      if (game.result) {
        // maker loses
        uint256 makerRatio = uint256((value * 1e6) / coupon.totalSupply(tokenId));
        uint256 matchedBalance = (odds * matchedValue[pool]) / 1e2;
        amount = (totalBalance - matchedBalance) * makerRatio;
      } else {
        // maker wins
        uint256 makerRatio = uint256((value * 1e6) / coupon.totalSupply(tokenId));
        amount = totalBalance * makerRatio;
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
