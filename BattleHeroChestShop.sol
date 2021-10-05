// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./shared/IBattleHero.sol";
import "./shared/IBattleHeroGenScience.sol";
import "./shared/IBattleHeroBreeder.sol";
import "./node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BattleHeroChestShop is Context, AccessControlEnumerable {

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
    mapping(ChestType => uint) _prices;
    mapping(address => Chest[]) _buyed;    

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
        
        _prices[ChestType.CHARACTER] = 2000 ether;
        _prices[ChestType.WEAPON]    = 2000 ether;         
        _prices[ChestType.MIX]       = 3000 ether; 
    }

    modifier isSetup() {
        require(address(_erc20) != address(0), "Setup not correctly");
        require(address(_genScience) != address(0), "Setup not correctly");
        require(address(_breeder) != address(0), "Setup not correctly");
        _;
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

    function buy(ChestType chestType) external {
        require(_erc20.balanceOf(msg.sender) >= _prices[chestType], "Insufficient BATH");
        _buyed[msg.sender].push(Chest(chestType, ChestRarity.RANDOM, false, _buyed[msg.sender].length, block.timestamp));
        _erc20.burnFrom(msg.sender, _prices[chestType]);
    }
    function open(uint index) public {
        Chest memory chest = _buyed[msg.sender][index];
        uint[] memory ids = new uint[](2);           
        require(chest.opened == false, "Chest is currently opened");
        require(chest.chestRarity == ChestRarity.RANDOM, "Invalid chest on presale");    
        require(chest.when > 0, "Invalid chest");
        if (chest.chestType == ChestType.WEAPON) {
            string memory weapon = _genScience.generateWeapon();
            ids[0] = _breeder.breed(msg.sender, weapon);
            emit ChestOpened(index, msg.sender, block.timestamp, ids);
        }
        if (chest.chestType == ChestType.CHARACTER) {
            string memory character = _genScience.generateCharacter();
            ids[0] = _breeder.breed(msg.sender, character);
            emit ChestOpened(index, msg.sender, block.timestamp, ids);
        }
        _buyed[msg.sender][index].opened = true;
    }  



}
