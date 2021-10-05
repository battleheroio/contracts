// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./node_modules/@openzeppelin/contracts/utils/Context.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./shared/Whitelist.sol";


contract BattleHeroAirdropWallet is Context, Whitelist{
    
    uint8 _decimals      = 18;
    uint256 _scale       = 1 * 10 ** _decimals;

    using SafeMath for uint256;
    
    mapping(address => uint256) private _claimed;
    mapping(address => uint256) private _locked;
    mapping(address => uint256) private _total;
    mapping(address => uint256) private _usdtInvested;

    address private _beneficiary;
    address private _owner;
    uint256 private _vestingTime;
    uint256 private _overflow;
    uint256 private _saleEnd;

    uint256 private _bathPrice            = 5000000000000000 wei; // 0,005 BUSD

    uint256 private _firstClaimAvailable;
    uint256 private _saleStarts;
    uint256 private _subDate;    
    uint256 private _totalClaimableDate;
    
    uint256 private constant MAX_ACCEPTED = 1000 ether; // 1000 BUSD MAX
    uint256 private constant MIN_ACCEPTED = 1000000000000000000 wei; // 1 BUSD MIN
    
    address private BUSD                  = 0x55d398326f99059fF775485246999027B3197955;

    event TokensClaimed(address token, uint256 amount);

    constructor(){  
        _beneficiary = 0xb8Ce421729232eCD5DFc7BD0adFe1f4DAd9D9CcE;
        _owner       = _msgSender();
        // Mainnet
        _firstClaimAvailable       = 1634756400; // 20 October 2021 19:00 UTC 
        _subDate                   = 1632164400; // 20 September 2021 19:00 UTC
        _saleStarts                = 1634324400; // 15 October 2021 19:00 UTC 
        _saleEnd                   = 1634410800; // 16 October 2021 19:00 UTC 
        _vestingTime               = 120 days;       
        _totalClaimableDate        = 90 days;        
    }
    function tokenPrice() public view returns (uint256) {
       return _bathPrice;
    }
    receive() external payable{
        revert();
    }
    function invest(uint256 amount) public onlyWhitelisted{
        _usdtInvested[msg.sender] = _usdtInvested[msg.sender].add(amount);
        require(IERC20(BUSD).balanceOf(msg.sender) >= amount, "You dont have sufficient BUSD");
        require(IERC20(BUSD).allowance(msg.sender, address(this)) >= amount, "You dont grant allowance to contract");
        require(_usdtInvested[msg.sender] <= MAX_ACCEPTED, "You have already deposit a maximum of 3 BNB");
        require(amount >= MIN_ACCEPTED && amount <= MAX_ACCEPTED, "Minimum 0.1 BUSD and maximum 1500 BUSD");        
        require(block.timestamp >= _saleStarts && block.timestamp <=  _saleEnd, "Airdrop has not started or ended");        
        uint256 bnb         = amount;
        uint256 tokens      = _getTokenAmount(bnb, tokenPrice());
        _locked[msg.sender] = _locked[msg.sender].add(tokens);
        _total[msg.sender]  = _total[msg.sender].add(tokens);        
        IERC20(BUSD).transferFrom(msg.sender, _beneficiary, amount);
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
        return _weiAmount.mul(_scale) / _tokenPrice;
    }
    function claim(address token) public onlyWhitelisted{
        require(block.timestamp >= _firstClaimAvailable, "You can not claim until 20 october 19:00");
        require(_locked[msg.sender] > 0, "All tokens are already claimed");
        uint256 claimable     = getTokensToClaim(msg.sender) - _claimed[msg.sender];
        _claimed[msg.sender]  = _claimed[msg.sender].add(claimable);  
        _locked[msg.sender]   = _locked[msg.sender].sub(claimable);      
        SafeERC20.safeTransfer(IERC20(token), msg.sender, claimable);
        emit TokensClaimed(token, claimable);
    }
    function getTokensToClaim(address from) public view virtual returns (uint256) {
        if ( block.timestamp < _firstClaimAvailable ) {
            return 0;
        } else if ( block.timestamp >= _firstClaimAvailable.add( _totalClaimableDate ) ) {
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
    function changeBUSD(address usdt) public onlyOwner{
        BUSD = usdt;
    }
}