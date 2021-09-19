// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./shared/Whitelist.sol";

contract BattleHeroAirdropWallet is Context, Whitelist{
    
    uint8 _decimals      = 18;
    uint256 _scale       = 1 * 10 ** _decimals;

    using SafeMath for uint256;
    
    mapping(address => uint256) private _claimed;
    mapping(address => uint256) private _locked;
    mapping(address => uint256) private _total;
    mapping(address => uint256) private _bnbInvested;

    address private _beneficiary;
    address private _owner;
    uint256 private _vestingTime;
    uint256 private _overflow;
    uint256 private _airdropDuration;

    uint256 private _bathPrice      = 10526000000000 wei;

    uint256 private _firstClaimAvailable;
    uint256 private _airdropStarts;
    uint256 private _subDate;

    uint256 private constant MAX_ACCEPTED = 3 ether;
    uint256 private constant MIN_ACCEPTED = 100000000000000000 wei;


    event TokensClaimed(address token, uint256 amount);

    constructor(){  
        _beneficiary = _msgSender();
        _owner       = _msgSender();
        // Mainnet
        _firstClaimAvailable       = 1634731200; // 20 October 2021 12:00 UTC 
        _airdropStarts             = 1634299200; // 15 October 2021 12:00 UTC
        _vestingTime               = 120 days;
        _subDate                   = 1632139200; // 20 September 2021 12:00 UTC
        _airdropDuration           = 1 days;
    }

    function tokenPrice() public view returns (uint256) {
       return _bathPrice;
    }
    receive() external payable{
        invest();
    }
    function invest() public payable onlyWhitelisted{
        _bnbInvested[msg.sender] = _bnbInvested[msg.sender].add(msg.value);
        require(_bnbInvested[msg.sender] <= MAX_ACCEPTED, "You reach max bnb invest");
        require(msg.value >= MIN_ACCEPTED && msg.value <= MAX_ACCEPTED, "Minimum 0.01 BNB and maximum 3 BNB");        
        require(block.timestamp >= _airdropStarts && block.timestamp <= (_airdropStarts + _airdropDuration), "Airdrop not start or ended");        
        uint256 bnb         = msg.value;
        uint256 tokens      = _getTokenAmount(bnb, tokenPrice());
        _locked[msg.sender] = _locked[msg.sender].add(tokens);
        _total[msg.sender]  = _total[msg.sender].add(tokens);
        payable(_beneficiary).transfer(msg.value);        
    }

    function lockedOf(address from) public view returns(uint256){
        return _locked[from];
    }
    function claimedOf(address from) public view returns(uint256){
        return _claimed[from];
    }
    function totalOf(address from) public view returns(uint256){
        return _total[from];
    }
    function _getTokenAmount(uint256 _weiAmount, uint256 _tokenPrice) public view returns (uint256) {
        return _weiAmount.div(_tokenPrice) * _scale;
    }

    function claim(address token) public onlyWhitelisted{
        require(block.timestamp >= _firstClaimAvailable, "You can not claim until 20 october 12:00");
        require(_locked[msg.sender] > 0, "You claim all of your tokens");
        uint256 claimable     = getTokensToClaim(msg.sender) - _claimed[msg.sender];
        _claimed[msg.sender]  = _claimed[msg.sender].add(claimable);  
        _locked[msg.sender]   = _locked[msg.sender].sub(claimable);      
        SafeERC20.safeTransfer(IERC20(token), msg.sender, claimable);
        emit TokensClaimed(token, claimable);
    }

    function getTokensToClaim(address from) public view virtual returns (uint256) {
        if ( block.timestamp < _firstClaimAvailable ) {
            return 0;
        } else if ( block.timestamp >= _firstClaimAvailable.add( _vestingTime )) {
            return _historicalBalance( from );
        } else {     
            return _historicalBalance( from ).mul( block.timestamp.sub( _subDate ) ).div( _vestingTime );
        }
    }

    function _historicalBalance(address from) internal view virtual returns (uint256) {
        return (_locked[from] + _claimed[from]);
    }

    function balance(address token) public view returns(uint256){
        return IERC20(token).balanceOf(address(this));
    }       

    function changeBathPrice(uint256 price) public{
        require(msg.sender == _owner);
        _bathPrice = price;
    }

}