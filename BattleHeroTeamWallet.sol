// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BattleHeroTeamWallet is Context{
    
    using SafeMath for uint256;
    
    mapping(address => uint256) private _unlocked;
    
    address private _beneficiary;
    uint256 private _start;
    uint256 private _duration;
    
    event TokensUnlocked(address token, uint256 amount);

    constructor(){
        _beneficiary = _msgSender();
        _start       = block.timestamp;
        _duration    = 1825 days;        
    }

    function unlock(address token) public virtual{
        uint256 unlockable = unlockedAmount(token) - _unlocked[token];
        _unlocked[token] = _unlocked[token].add(unlockable);
        SafeERC20.safeTransfer(IERC20(token), _beneficiary, unlockable);
        emit TokensUnlocked(token, unlockable);
    }

    function unlockedAmount(address token) public view virtual returns (uint256) {
        if (block.timestamp < _start) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration)) {
            return _historicalBalance(token);
        } else {
            return _historicalBalance(token).mul( block.timestamp.sub(_start) ).div(_duration);
        }
    }

    function _historicalBalance(address token) internal view virtual returns (uint256) {
        return IERC20(token).balanceOf(address(this)) + _unlocked[token];
    }

}