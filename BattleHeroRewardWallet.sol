// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./node_modules/@openzeppelin/contracts/utils/Context.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";


contract BattleHeroRewardWallet is Context, AccessControlEnumerable{
    
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");
    mapping(address => uint ) _lastClaim;
    using SafeMath for uint256;

    mapping(address => uint256) _canClaim;          
    event TokensClaimed(address user, uint256 amount);
    uint claimDays = 5 days;

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(REWARD_DISTRIBUTOR_ROLE, _msgSender());
    }
    
    function addRewardDistributorRole(address distributorRole) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _setupRole(REWARD_DISTRIBUTOR_ROLE, distributorRole);
    }

    function addReward(address beneficiary, uint256 amount) public {
        require(hasRole(REWARD_DISTRIBUTOR_ROLE, _msgSender()), "your not reward distributor");
        _canClaim[beneficiary] = _canClaim[beneficiary].add(amount);
    }

    function rewardOf(address from) public view returns(uint256){
        return _canClaim[from];
    }

    function changeClaimDays(uint _days) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You are not an admin");
        claimDays = _days;
    }

    function claim(address _bath) public virtual{
        require(block.timestamp >= _lastClaim[msg.sender] + claimDays, "You need to wait for next claim");
        require(IERC20(_bath).balanceOf(address(this)) > 0, "No reward tokens left");
        require(rewardOf(msg.sender) > 0, "No reward to claim");
        address beneficiary     = msg.sender;
        uint256 claimable       = _canClaim[beneficiary];                
        SafeERC20.safeTransfer(IERC20(_bath), beneficiary, claimable);
        _canClaim[beneficiary] = _canClaim[beneficiary].sub(claimable);
        require(_canClaim[beneficiary] == 0);
        _lastClaim[msg.sender] = block.timestamp;
        emit TokensClaimed(beneficiary, claimable);
    }
}   