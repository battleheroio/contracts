// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./shared/IBattleHero.sol";
import "./shared/IBattleHeroGenScience.sol";
import "./shared/IBattleHeroBreeder.sol";
import "./node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract BattleHeroPresaleChestShop is Context, AccessControlEnumerable, Ownable {

    IBattleHeroGenScience _genScience;
    IBattleHeroBreeder _breeder;

    using SafeMath for uint256;
    

    bytes32 public constant ECOSYSTEM_ROLE = keccak256("ECOSYSTEM_ROLE");

    enum ChestType {
        CHARACTER,
        WEAPON,
        MIX
    }
    enum ChestRarity {
        COMMON,
        LOW_RARE,
        RARE,
        EPIC,
        LEGEND,
        MITIC,
        RANDOM
    }

    struct Chest{
        ChestType chestType;
        ChestRarity chestRarity;
        bool opened;
        uint index;
        uint when;
    }

    mapping(ChestType => mapping(ChestRarity => mapping(uint => uint))) _caps;
    mapping(ChestRarity => uint) _prices;
    uint256 _presaleStart;
    mapping(address => Chest[]) _buyed;
    address _beneficiary;

    uint256 MAX_DAYS = 3 days;
    uint256 ROUND_DURATION = 1 days;

    event ChestOpened(uint index, address from,uint when, uint[] tokenIds);

    constructor(
        address genScience,
        address breeder
    ) {
        _setupRole(ECOSYSTEM_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _genScience   = IBattleHeroGenScience(genScience);
        _breeder      = IBattleHeroBreeder(breeder);
        _beneficiary  = 0xb8Ce421729232eCD5DFc7BD0adFe1f4DAd9D9CcE;        
        _presaleStart = block.timestamp; // 1 October 2021 at 19:00 GMT on mainnet         

        _prices[ChestRarity.LOW_RARE] = 80000000000000000 wei;
        _prices[ChestRarity.RARE]     = 250000000000000000 wei;         
        _prices[ChestRarity.EPIC]     = 600000000000000000 wei; 
        _prices[ChestRarity.LEGEND]   = 1350000000000000000 wei;        
        _prices[ChestRarity.MITIC]    = 1980000000000000000 wei;

        _caps[ChestType.CHARACTER][ChestRarity.LOW_RARE][0] = 600;
        _caps[ChestType.WEAPON][ChestRarity.LOW_RARE][0]    = 600;
        _caps[ChestType.CHARACTER][ChestRarity.RARE][0]     = 375;
        _caps[ChestType.WEAPON][ChestRarity.RARE][0]        = 375; 
        _caps[ChestType.CHARACTER][ChestRarity.EPIC][0]     = 150;
        _caps[ChestType.WEAPON][ChestRarity.EPIC][0]        = 150; 
        _caps[ChestType.CHARACTER][ChestRarity.LEGEND][0]   = 10;
        _caps[ChestType.WEAPON][ChestRarity.LEGEND][0]      = 10; 
        _caps[ChestType.CHARACTER][ChestRarity.MITIC][0]    = 3;
        _caps[ChestType.WEAPON][ChestRarity.MITIC][0]       = 3; 

        _caps[ChestType.CHARACTER][ChestRarity.LOW_RARE][1] = 600;
        _caps[ChestType.WEAPON][ChestRarity.LOW_RARE][1]    = 600;
        _caps[ChestType.CHARACTER][ChestRarity.RARE][1]     = 375;
        _caps[ChestType.WEAPON][ChestRarity.RARE][1]        = 375; 
        _caps[ChestType.CHARACTER][ChestRarity.EPIC][1]     = 150;
        _caps[ChestType.WEAPON][ChestRarity.EPIC][1]        = 150; 
        _caps[ChestType.CHARACTER][ChestRarity.LEGEND][1]   = 10;
        _caps[ChestType.WEAPON][ChestRarity.LEGEND][1]      = 10; 
        _caps[ChestType.CHARACTER][ChestRarity.MITIC][1]    = 3;
        _caps[ChestType.WEAPON][ChestRarity.MITIC][1]       = 3; 

        _caps[ChestType.CHARACTER][ChestRarity.LOW_RARE][2] = 600;
        _caps[ChestType.WEAPON][ChestRarity.LOW_RARE][2]    = 600;
        _caps[ChestType.CHARACTER][ChestRarity.RARE][2]     = 375;
        _caps[ChestType.WEAPON][ChestRarity.RARE][2]        = 375; 
        _caps[ChestType.CHARACTER][ChestRarity.EPIC][2]     = 150;
        _caps[ChestType.WEAPON][ChestRarity.EPIC][2]        = 150; 
        _caps[ChestType.CHARACTER][ChestRarity.LEGEND][2]   = 10;
        _caps[ChestType.WEAPON][ChestRarity.LEGEND][2]      = 10; 
        _caps[ChestType.CHARACTER][ChestRarity.MITIC][2]    = 3;
        _caps[ChestType.WEAPON][ChestRarity.MITIC][2]       = 3; 

    }


    function startPresale() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _presaleStart = block.timestamp;
    }

    modifier isSetup() {
        require(address(_genScience) != address(0), "Setup not correctly");
        require(address(_breeder) != address(0), "Setup not correctly");
        _;
    }
    function timeToOpen() public view returns(uint){
        return _presaleStart - block.timestamp;
    }
    function chestsOf(address from, uint256 page) public view returns(Chest[] memory) {
        uint results_per_page       = 10;
        uint greater_than           = results_per_page * page;
        uint start_pointer          = (results_per_page * page) - results_per_page;
        Chest[] memory chests       = new Chest[](results_per_page);   
        uint counter                = 0;
        for(uint i = start_pointer; i < greater_than; i++){
            if(i < _buyed[from].length){
                Chest memory ch = _buyed[from][i];
                chests[counter] = ch;
                counter = counter + 1;
            }           
        }
        return chests;
    }
    function buy(ChestType chestType, ChestRarity chestRarity) external payable {
        require(msg.value >= _prices[chestRarity], "Insufficient BNB");
        require(block.timestamp >= _presaleStart && block.timestamp <= (_presaleStart + MAX_DAYS), "Time out");
        if(block.timestamp >= _presaleStart && block.timestamp <= _presaleStart + ROUND_DURATION){
            require(_caps[chestType][chestRarity][0] > 0, "Sold out");            
            _caps[chestType][chestRarity][0] = _caps[chestType][chestRarity][0].sub(1);
            _buyed[msg.sender].push(Chest(chestType, chestRarity, false, _buyed[msg.sender].length, block.timestamp));
            payable(_beneficiary).transfer(msg.value);
            return;
        }
        if(block.timestamp >= _presaleStart + ROUND_DURATION && block.timestamp <= _presaleStart + (ROUND_DURATION * 2)){
            require(_caps[chestType][chestRarity][1] > 0, "Sold out");
            _caps[chestType][chestRarity][1] = _caps[chestType][chestRarity][1].sub(1);
            _buyed[msg.sender].push(Chest(chestType, chestRarity, false, _buyed[msg.sender].length, block.timestamp));
            payable(_beneficiary).transfer(msg.value);
            return;
        }
        if(block.timestamp >= _presaleStart + (ROUND_DURATION * 2) && block.timestamp <= MAX_DAYS){
            require(_caps[chestType][chestRarity][2] > 0, "Sold out");
            _caps[chestType][chestRarity][2] = _caps[chestType][chestRarity][2].sub(1);
            _buyed[msg.sender].push(Chest(chestType, chestRarity, false, _buyed[msg.sender].length, block.timestamp));
            payable(_beneficiary).transfer(msg.value);
            return;
        }
        revert();
    }
    function open(uint index) public {
        Chest memory chest = _buyed[msg.sender][index];
        uint[] memory ids = new uint[](2);           
        require(chest.opened == false, "Chest is currently opened");
        require(chest.chestRarity != ChestRarity.RANDOM, "Invalid chest on presale");    
        require(chest.when > 0, "Invalid chest");
        if (chest.chestType == ChestType.WEAPON) {
            string memory weapon = _genScience.generateWeapon(
                chestRaritytoRarity(chest.chestRarity)
            );
            ids[0] = _breeder.breed(msg.sender, weapon);
            emit ChestOpened(index, msg.sender, block.timestamp, ids);
        }
        if (chest.chestType == ChestType.CHARACTER) {
            string memory character = _genScience.generateCharacter(
                chestRaritytoRarity(chest.chestRarity)
            );
            ids[0] = _breeder.breed(msg.sender, character);
            emit ChestOpened(index, msg.sender, block.timestamp, ids);
        }    
        _buyed[msg.sender][index].opened = true;
    }
    function setGenScience(address genScience) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _genScience = IBattleHeroGenScience(genScience);
    }
    function setBreeder(address breeder) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _breeder = IBattleHeroBreeder(breeder);
    }
    function chestRaritytoRarity(ChestRarity chestRarity) public pure returns(IBattleHeroGenScience.Rarity){
        if(chestRarity == ChestRarity.COMMON){
            return IBattleHeroGenScience.Rarity.COMMON;
        }
        if(chestRarity == ChestRarity.LOW_RARE){
            return IBattleHeroGenScience.Rarity.LOW_RARE;
        }
        if(chestRarity == ChestRarity.RARE){
            return IBattleHeroGenScience.Rarity.RARE;
        }
        if(chestRarity == ChestRarity.EPIC){
            return IBattleHeroGenScience.Rarity.EPIC;
        }
        if(chestRarity == ChestRarity.LEGEND){
            return IBattleHeroGenScience.Rarity.LEGEND;
        }
        if(chestRarity == ChestRarity.MITIC){
            return IBattleHeroGenScience.Rarity.MITIC;
        }
        return IBattleHeroGenScience.Rarity.COMMON;
    }
    function selling() public view returns(uint256[5][5] memory){
        uint256[5][5] memory chestCaps;

        if(block.timestamp >= _presaleStart && block.timestamp <= _presaleStart + ROUND_DURATION){        
            
            chestCaps[0][0] = _caps[ChestType.CHARACTER][ChestRarity.LOW_RARE][0];
            chestCaps[0][1] = _caps[ChestType.CHARACTER][ChestRarity.RARE][0];
            chestCaps[0][2] = _caps[ChestType.CHARACTER][ChestRarity.EPIC][0];
            chestCaps[0][3] = _caps[ChestType.CHARACTER][ChestRarity.LEGEND][0];
            chestCaps[0][4] = _caps[ChestType.CHARACTER][ChestRarity.MITIC][0];

            chestCaps[1][0] = _caps[ChestType.WEAPON][ChestRarity.LOW_RARE][0];  
            chestCaps[1][1] = _caps[ChestType.WEAPON][ChestRarity.RARE][0];
            chestCaps[1][2] = _caps[ChestType.WEAPON][ChestRarity.EPIC][0];        
            chestCaps[1][3] = _caps[ChestType.WEAPON][ChestRarity.LEGEND][0];
            chestCaps[1][4] = _caps[ChestType.WEAPON][ChestRarity.MITIC][0];
        }
        if(block.timestamp >= _presaleStart + ROUND_DURATION && block.timestamp <= _presaleStart + (ROUND_DURATION * 2)){
            chestCaps[0][0] = _caps[ChestType.CHARACTER][ChestRarity.LOW_RARE][1];
            chestCaps[0][1] = _caps[ChestType.CHARACTER][ChestRarity.RARE][1];
            chestCaps[0][2] = _caps[ChestType.CHARACTER][ChestRarity.EPIC][1];
            chestCaps[0][3] = _caps[ChestType.CHARACTER][ChestRarity.LEGEND][1];
            chestCaps[0][4] = _caps[ChestType.CHARACTER][ChestRarity.MITIC][1];

            chestCaps[1][0] = _caps[ChestType.WEAPON][ChestRarity.LOW_RARE][1];  
            chestCaps[1][1] = _caps[ChestType.WEAPON][ChestRarity.RARE][1];
            chestCaps[1][2] = _caps[ChestType.WEAPON][ChestRarity.EPIC][1];        
            chestCaps[1][3] = _caps[ChestType.WEAPON][ChestRarity.LEGEND][1];
            chestCaps[1][4] = _caps[ChestType.WEAPON][ChestRarity.MITIC][1];
        }
        if(block.timestamp >= _presaleStart + (ROUND_DURATION * 2) && block.timestamp <= _presaleStart + (ROUND_DURATION * 3)){
            chestCaps[0][0] = _caps[ChestType.CHARACTER][ChestRarity.LOW_RARE][2];
            chestCaps[0][1] = _caps[ChestType.CHARACTER][ChestRarity.RARE][2];
            chestCaps[0][2] = _caps[ChestType.CHARACTER][ChestRarity.EPIC][2];
            chestCaps[0][3] = _caps[ChestType.CHARACTER][ChestRarity.LEGEND][2];
            chestCaps[0][4] = _caps[ChestType.CHARACTER][ChestRarity.MITIC][2];

            chestCaps[1][0] = _caps[ChestType.WEAPON][ChestRarity.LOW_RARE][2];  
            chestCaps[1][1] = _caps[ChestType.WEAPON][ChestRarity.RARE][2];
            chestCaps[1][2] = _caps[ChestType.WEAPON][ChestRarity.EPIC][2];        
            chestCaps[1][3] = _caps[ChestType.WEAPON][ChestRarity.LEGEND][2];
            chestCaps[1][4] = _caps[ChestType.WEAPON][ChestRarity.MITIC][2];
        } 
        return chestCaps;
    }
    function emergencyWithdraw() public onlyOwner{
        payable(_beneficiary).transfer(payable(address(this)).balance);
    }
    function changeBeneficiary(address beneficiary) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _beneficiary = beneficiary;
    }
    function destroySmartContract() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        selfdestruct(payable(msg.sender));
    }
}
