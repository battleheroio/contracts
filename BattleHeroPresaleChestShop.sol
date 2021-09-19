// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./shared/IBattleHero.sol";
import "./shared/IBattleHeroGenScience.sol";
import "./shared/IBattleHeroBreeder.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract BattleHeroPresaleChestShop is Context, AccessControlEnumerable, Ownable {

    IBattleHero _erc20;
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
    event ChestOpened(uint index, address from,uint when, uint[] tokenIds);

    constructor(
        address erc20address,
        address genScience,
        address breeder
    ) {
        _setupRole(ECOSYSTEM_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _erc20        = IBattleHero(erc20address);
        _genScience   = IBattleHeroGenScience(genScience);
        _breeder      = IBattleHeroBreeder(breeder);
        _beneficiary  = _msgSender();
         //_presaleStart = 1633089600; // 1 October 2021 at 12:00 GMT on mainnet
         // now for testnet
        _presaleStart = block.timestamp; // 1 October 2021 at 12:00 GMT on mainnet

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



    modifier isSetup() {
        require(address(_erc20) != address(0), "Setup not correctly");
        require(address(_genScience) != address(0), "Setup not correctly");
        require(address(_breeder) != address(0), "Setup not correctly");
        _;
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
        require(block.timestamp >= _presaleStart && block.timestamp <= _presaleStart + 3 days, "Time out");
        if(block.timestamp >= _presaleStart && block.timestamp <= _presaleStart + 1 days){
            require(_caps[chestType][chestRarity][0] > 0, "Sold out");            
            _caps[chestType][chestRarity][0] = _caps[chestType][chestRarity][0].sub(1);
            _buyed[msg.sender].push(Chest(chestType, chestRarity, false, _buyed[msg.sender].length, block.timestamp));
            payable(_beneficiary).transfer(msg.value);
        }
        if(block.timestamp >= _presaleStart + 1 days && block.timestamp <= _presaleStart + 2 days){
            require(_caps[chestType][chestRarity][1] > 0, "Sold out");
            _caps[chestType][chestRarity][1] = _caps[chestType][chestRarity][0].sub(1);
            _buyed[msg.sender].push(Chest(chestType, chestRarity, false, _buyed[msg.sender].length, block.timestamp));
            payable(_beneficiary).transfer(msg.value);

        }
        if(block.timestamp >= _presaleStart + 2 days && block.timestamp <= _presaleStart + 3 days){
            require(_caps[chestType][chestRarity][2] > 0, "Sold out");
            _caps[chestType][chestRarity][2] = _caps[chestType][chestRarity][0].sub(1);
            _buyed[msg.sender].push(Chest(chestType, chestRarity, false, _buyed[msg.sender].length, block.timestamp));
            payable(_beneficiary).transfer(msg.value);
        }
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

    function setERC20(address erc20) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "You dont have role"
        );
        _erc20 = IBattleHero(erc20);
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

    function selling() public view returns(uint256[6][6] memory){
        uint256[6][6] memory chestCaps;

        if(block.timestamp >= _presaleStart && block.timestamp <= _presaleStart + 1 days){        
            
            chestCaps[0][0] = _caps[ChestType.CHARACTER][ChestRarity.LOW_RARE][0];
            chestCaps[0][1] = _caps[ChestType.CHARACTER][ChestRarity.RARE][0];
            chestCaps[0][2] = _caps[ChestType.CHARACTER][ChestRarity.EPIC][0];
            chestCaps[0][3] = _caps[ChestType.CHARACTER][ChestRarity.LEGEND][0];
            chestCaps[0][4] = _caps[ChestType.CHARACTER][ChestRarity.EPIC][0];
            chestCaps[0][5] = _caps[ChestType.CHARACTER][ChestRarity.MITIC][0];

            chestCaps[1][0] = _caps[ChestType.WEAPON][ChestRarity.LOW_RARE][0];  
            chestCaps[1][1] = _caps[ChestType.WEAPON][ChestRarity.RARE][0];
            chestCaps[1][2] = _caps[ChestType.WEAPON][ChestRarity.EPIC][0];
            chestCaps[1][3] = _caps[ChestType.WEAPON][ChestRarity.LEGEND][0];
            chestCaps[1][4] = _caps[ChestType.WEAPON][ChestRarity.EPIC][0];        
            chestCaps[1][5] = _caps[ChestType.WEAPON][ChestRarity.MITIC][0];
        }
        if(block.timestamp >= _presaleStart + 1 days && block.timestamp <= _presaleStart + 2 days){
          chestCaps[0][0] = _caps[ChestType.CHARACTER][ChestRarity.LOW_RARE][1];
            chestCaps[0][1] = _caps[ChestType.CHARACTER][ChestRarity.RARE][1];
            chestCaps[0][2] = _caps[ChestType.CHARACTER][ChestRarity.EPIC][1];
            chestCaps[0][3] = _caps[ChestType.CHARACTER][ChestRarity.LEGEND][1];
            chestCaps[0][4] = _caps[ChestType.CHARACTER][ChestRarity.EPIC][1];
            chestCaps[0][5] = _caps[ChestType.CHARACTER][ChestRarity.MITIC][1];

            chestCaps[1][0] = _caps[ChestType.WEAPON][ChestRarity.LOW_RARE][1];  
            chestCaps[1][1] = _caps[ChestType.WEAPON][ChestRarity.RARE][1];
            chestCaps[1][2] = _caps[ChestType.WEAPON][ChestRarity.EPIC][1];
            chestCaps[1][3] = _caps[ChestType.WEAPON][ChestRarity.LEGEND][1];
            chestCaps[1][4] = _caps[ChestType.WEAPON][ChestRarity.EPIC][1];        
            chestCaps[1][5] = _caps[ChestType.WEAPON][ChestRarity.MITIC][1];
        }
        if(block.timestamp >= _presaleStart + 2 days && block.timestamp <= _presaleStart + 3 days){
            chestCaps[0][0] = _caps[ChestType.CHARACTER][ChestRarity.LOW_RARE][2];
            chestCaps[0][1] = _caps[ChestType.CHARACTER][ChestRarity.RARE][2];
            chestCaps[0][2] = _caps[ChestType.CHARACTER][ChestRarity.EPIC][2];
            chestCaps[0][3] = _caps[ChestType.CHARACTER][ChestRarity.LEGEND][2];
            chestCaps[0][4] = _caps[ChestType.CHARACTER][ChestRarity.EPIC][2];
            chestCaps[0][5] = _caps[ChestType.CHARACTER][ChestRarity.MITIC][2];

            chestCaps[1][0] = _caps[ChestType.WEAPON][ChestRarity.LOW_RARE][2];  
            chestCaps[1][1] = _caps[ChestType.WEAPON][ChestRarity.RARE][2];
            chestCaps[1][2] = _caps[ChestType.WEAPON][ChestRarity.EPIC][2];
            chestCaps[1][3] = _caps[ChestType.WEAPON][ChestRarity.LEGEND][2];
            chestCaps[1][4] = _caps[ChestType.WEAPON][ChestRarity.EPIC][2];        
            chestCaps[1][5] = _caps[ChestType.WEAPON][ChestRarity.MITIC][2];
        } 
        return chestCaps;
    }

}
