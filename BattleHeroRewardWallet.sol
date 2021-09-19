// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";


contract BattleHeroRewardWallet is Context, AccessControlEnumerable{
    
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");

    using SafeMath for uint256;

    mapping(address => uint256) _canReward;          
    event TokensClaimed(address user, uint256 amount);

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
        _canReward[beneficiary] = _canReward[beneficiary].add(amount);
    }

    function rewardOf(address from) public view returns(uint256){
        return _canReward[from];
    }

    function claim(address _bath) public virtual{
        require(IERC20(_bath).balanceOf(address(this)) > 0, "No reward tokens left");
        address beneficiary     = msg.sender;
        uint256 claimable       = _canReward[beneficiary];                
        SafeERC20.safeTransfer(IERC20(_bath), beneficiary, claimable);
        _canReward[beneficiary] = _canReward[beneficiary].sub(claimable);
        require(_canReward[beneficiary] == 0);
        emit TokensClaimed(beneficiary, claimable);
    }
}   