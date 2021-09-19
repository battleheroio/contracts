// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "./shared/BattleHeroData.sol";
import "./shared/IBattleHeroFactory.sol";
import "./shared/IBattleHero.sol";

contract USDT{
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {}
    function allowance(address owner, address spender) external view returns (uint256) {}
}

contract BattleHeroMarketplace is
    Context,
    AccessControlEnumerable{

    enum AcceptedToken {BATH}
    struct Auction{
        IBattleHeroFactory.Hero hero;
        AcceptedToken token;
        uint256 price;
    }
    IBattleHeroFactory _erc721;
    IBattleHero _bath;
    Auction[] auctions;    
    address _feeAddress;
    constructor(address erc721,  address bath){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _erc721     = IBattleHeroFactory(erc721);
        _bath       = IBattleHero(bath);
        _feeAddress = _msgSender();
    }

    modifier isSetup() {
        require(address(_erc721) != address(0), "Setup not correctly");        
        require(address(_bath) != address(0), "Setup not correctly");        
        _;
    }
    
    function setBATH(address bath) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _bath = IBattleHero(bath);
    }

    function addNFT(uint256 tokenId, uint256 price, AcceptedToken token) isSetup public{
        require(isSelling(tokenId) == false, "This NFT is currently on marketplace");
        require(_erc721.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(_erc721.isApproved(address(this), tokenId), "You should to approve this NFT first");     
        require(_erc721.isLocked(tokenId) == false, "Hero is locked");
        IBattleHeroFactory.Hero memory h = _erc721.heroeOfId(tokenId);
        Auction memory auction = Auction(h, token, price);
        auctions.push(auction);
        _erc721.lockHero(tokenId);
    }

    function buyNFT(uint256 index) isSetup public returns(bool){               
        Auction memory auction = auctions[index];        
        require(auctions[index].hero.exists == true, "Currently not selling");           
        uint256 fee = (auctions[index].price / 100) * 5;           
        _erc721.unlockHero(auction.hero.index);
        require(_bath.allowance(msg.sender, address(this)) >= auctions[index].price, "Insufficient funds BATH");        
        _bath.transferFrom(msg.sender, auctions[index].hero.owner, auctions[index].price - fee);        
        _bath.transferFrom(msg.sender, _feeAddress, fee);        
        _erc721.transferFrom(auction.hero.owner, msg.sender, auction.hero.index);        
        auctions = removeA(index);
        return true;
    }

    function removeA(uint index) internal returns(Auction[] storage) {
        if (index >= auctions.length) {
            return auctions;
        }

        for (uint i = index; i<auctions.length-1; i++){
            auctions[i] = auctions[i+1];
        }
        auctions.pop();
        return auctions;
    }

    function removeAuction(uint256 index) isSetup public{
        Auction memory auction = auctions[index];
        require(_erc721.ownerOf(auction.hero.index) == msg.sender, "You are not the owner of this NFT");
        auctions = removeA(index);
    }

    function isSelling(uint256 tokenId) public view returns(bool){        
        bool exists = false;        
        if(auctions.length == 0){
            return false;
        }
        for(uint i = 0; i <= auctions.length - 1; i++){
            if(auctions[i].hero.index == tokenId && auctions[i].hero.exists == true){
                exists = true;
            }            
        }
        return exists;
    }

    function getAuction(uint256 index) public view returns(Auction memory){
        return auctions[index];
    }

    function getAuctions(uint page) public view returns(Auction[] memory) {           
        uint results_per_page = 10;
        uint greeter_than = results_per_page * page;
        uint start_pointer = (results_per_page * page) - results_per_page;
        uint heroes_length = auctions.length;
        uint counter = 0;
        Auction[] memory h = new Auction[](results_per_page);
        for(uint i = start_pointer; i < greeter_than; i++){
            if(i <= heroes_length - 1){  
                if(auctions[i].hero.exists == false){
                    continue;
                }
                h[counter]        = auctions[i];
                counter = counter + 1;
            }
        }
        return h;
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}