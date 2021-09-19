// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./shared/BattleHeroData.sol";
import "./shared/IBattleHeroFactory.sol";
import "./shared/IBattleHero.sol";
import "./shared/DateTime.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./shared/IBattleHeroRewardWallet.sol";

/**
 * BattleHeroTrainer
 * This contract controls the training of the heroes and their weapons. 
 * In it you can receive PE that, these can be exchanged for BATH  
 */
contract BattleHeroTrainer is DateTime{
    enum Type{
        CHARACTER, 
        WEAPON
    }
    struct TrainPair{
        uint256 character;
        uint256 weapon;        
    }
    struct Training{
        uint[][] pairs;
        uint timestamp;
        uint blockNumber;
        bool exists;
    }
    uint8 public constant pe_decimals = 18;
    uint256 public constant PE_ESCALE = 1 * 10 ** uint256(pe_decimals);
    uint256 public TRAINING_LOCK_TIME = 8600;
    address owner;
    mapping(address => Training) trainings;
    mapping(address => uint256) pe;
    mapping(address => uint256) extraSlots;
    mapping(uint256 => bool) tokenIdTraining;
    BattleHeroData battleHeroData;
    IBattleHeroFactory erc721;
    IBattleHero erc20;
    IBattleHeroRewardWallet rewardWallet;
    uint256 MIN_SLOTS  = 3;
    uint256 MAX_SLOTS  = 30;
    uint256 SLOT_PRICE = 500000000000000000;
    using SafeMath for uint256;

    constructor(
        address bHeroData, 
        address erc721address, 
        address erc20address, 
        address rWallet){            
        owner = msg.sender;
        setBattleHeroData(bHeroData);
        setERC721(erc721address);
        setERC20(erc20address);
        setBattleHeroRewardWallet(rWallet);
    }

    /**
     * @dev Set new contract address for BattleHeroRewardWallet.
     *
     * Requirements:
     * - `battleHeroRewardWallet` cannot be the zero address.     
     * - `sender` is owner
     */
    function setBattleHeroRewardWallet(address battleHeroRewardWallet) public {
        require(msg.sender == owner);
        require(battleHeroRewardWallet != address(0));
        rewardWallet = IBattleHeroRewardWallet(battleHeroRewardWallet);
    }
    /**
     * @dev Set new contract address for BattleHeroData.
     *
     * Requirements:
     * - `battleHeroDataAddress` cannot be the zero address.     
     * - `sender` is owner
     */
    function setBattleHeroData(address battleHeroDataAddress) public {
        require(msg.sender == owner);
        require(battleHeroDataAddress != address(0));
        battleHeroData = BattleHeroData(battleHeroDataAddress);
    }

    /**
     * @dev Set new contract address for BattleHeroFactory.
     *
     * Requirements:
     * - `battleHeroFactoryAddress` cannot be the zero address.     
     * - `sender` is owner
     */
    function setERC721(address battleHeroFactoryAddress) public {
        require(msg.sender == owner);
        require(battleHeroFactoryAddress != address(0));
        erc721 = IBattleHeroFactory(battleHeroFactoryAddress);
    }

    /**
     * @dev Set new contract address for BattleHero.
     *
     * Requirements:
     * - `battleHeroAddress` cannot be the zero address.     
     * - `sender` is owner
     */
    function setERC20(address battleHeroAddress) public {
        require(msg.sender == owner);
        require(battleHeroAddress != address(0));
        erc20 = IBattleHero(battleHeroAddress);
    }

    /**
     * @dev Modifier for check if contracts are setup
     */
    modifier isSetup() {
        require(address(battleHeroData) != address(0), "Setup not correctly");        
        require(address(erc721) != address(0), "Setup not correctly");        
        require(address(erc20) != address(0), "Setup not correctly");        
        _;
    }

    /**
     * @dev Check if tokenId is weapon or not    
     */
    function isWeapon(uint256 tokenId) public view returns (bool){
        IBattleHeroFactory.Hero memory hero = erc721.heroeOfId(tokenId);
        BattleHeroData.DeconstructedGen memory deconstructed = battleHeroData.deconstructGen(hero.genetic);                        
        return deconstructed._type > 49;
    }

    /**
     * @dev Return current training
     */
    function currentTraining(address _owner) public view returns(Training memory){
        return trainings[_owner];
    }

    /**
     * @dev Buy new train slot
     */
    function buySlot() isSetup public returns(bool){
        require(erc20.balanceOf(msg.sender) >= SLOT_PRICE, "Insufficient BATH balance");
        erc20.burnFrom(msg.sender, SLOT_PRICE);
        extraSlots[msg.sender] = extraSlots[msg.sender].add(1);
        return true;
    }

    /**
     * @dev Return slots for `_owner`
     */
    function getSlots(address _owner) public view returns(uint256){
        uint256 _extraSlots = 0;
        if(extraSlots[_owner] > 0){
                _extraSlots = extraSlots[_owner];
        }
        uint256 _totalExtraSlots = _extraSlots;
        return _totalExtraSlots + MIN_SLOTS;
    }
    
    /**
     * @dev Check if is owner of tokenId
     */
    function isOwner(uint256 tokenId, address _owner) public view returns(bool){
            return erc721.ownerOf(tokenId) == _owner;
    }

    /**
     * @dev Set `pairs` of character <-> weapon to train
     * 
     * Requirements: 
     * - have more slots than pairs length
     * - can not set same weapon or same character twice
     * - index 0 of pair should be character and index 1 of pair should be weapon
     * - check if is owner
     * - check if is currently training
     */
    function train(uint[][] calldata pairs) isSetup public{
        uint256 slots = getSlots(msg.sender);      
        uint256 l     = pairs.length;      
        require(pairs.length <= slots, "Buy more slots");
            for(uint i = 0; i <= l - 1; i++){
                require(tokenIdTraining[pairs[i][1]] != true, "You are setting same weapon twice");
                require(tokenIdTraining[pairs[i][0]] != true, "You are setting same character twice");
                require(isWeapon(pairs[i][1]) == true, "Not a weapon");
                require(isWeapon(pairs[i][0]) == false, "Not a character");
                require(isOwner(pairs[i][1], msg.sender) == true, "You are not owner");
                require(isOwner(pairs[i][0], msg.sender) == true, "You are not owner");    
                require(erc721.isLocked(pairs[i][0]) == false, "Hero is locked");
                require(erc721.isLocked(pairs[i][1]) == false, "Hero is locked");
                erc721.lockHero(pairs[i][0]);
                erc721.lockHero(pairs[i][1]);
                tokenIdTraining[pairs[i][1]] = true;
                tokenIdTraining[pairs[i][0]] = true;
            }
        require(trainings[msg.sender].exists != true, "Currently training");        
        trainings[msg.sender] = Training(pairs, block.timestamp, block.number, true);
    }

    /**
     * Do calculation for training pairs
     */
    function calculateTrainingReward(uint[][] calldata pairs) public view returns(uint){            
        return rewardPerTrain(Training(pairs, 0, 0, true));
    }

    /**
     * Cancel current train
     */
    function cancelTrain() public {
        Training memory training = trainings[msg.sender];
        cleanTokenIds(training.pairs);
        delete trainings[msg.sender];    
    }

    /**
     * Claim train
     * Requirements: 
     * - Should pass 24 hours from training start
     */
    function claimTrain() isSetup public {
        Training memory training = trainings[msg.sender];
        uint timestamp           = training.timestamp;     
        uint currentTimestamp    = block.timestamp;
        uint timestampDiff       = currentTimestamp - timestamp;
        if(msg.sender != owner){
            require(timestampDiff >= TRAINING_LOCK_TIME, "You need to wait");
        }
        uint256 reward = rewardPerTrain(training);
        pe[msg.sender] = pe[msg.sender].add(reward);
        cleanTokenIds(training.pairs);
        delete trainings[msg.sender];        
    }

    /**
     * Clean training token ids. Internal use
     */
    function cleanTokenIds(uint[][] memory pairs) internal{
        for(uint i = 0; i <= pairs.length - 1; i++){
                erc721.unlockHero(pairs[i][0]);
                erc721.unlockHero(pairs[i][1]);
                tokenIdTraining[pairs[i][1]] = false;
                tokenIdTraining[pairs[i][0]] = false;
        }
    }

    /**
     * Return balance of PE
     */
    function balanceOfPe(address _owner) public view returns(uint256){
            return pe[_owner];
    }

    /**
     * Calculate reward per training
     */
    function rewardPerTrain(Training memory training) public view returns(uint256){
        uint256 reward = 0;
        uint256 pairsLength = training.pairs.length;
        for(uint256 i = 0; i <= pairsLength - 1; i++){
                uint256 characterId = training.pairs[i][0];
                BattleHeroData.DeconstructedGen memory characterDeconstructed = battleHeroData.deconstructGen(erc721.heroeOfId(characterId).genetic);        
                BattleHeroData.TrainingLevel memory trainingLevelCharacter = battleHeroData.getTrainingLevel(characterDeconstructed._rarity);

                uint256 weaponId = training.pairs[i][1];
                BattleHeroData.DeconstructedGen memory weaponDeconstructed = battleHeroData.deconstructGen(erc721.heroeOfId(weaponId).genetic);        
                BattleHeroData.TrainingLevel memory trainingLevelWeapon = battleHeroData.getTrainingLevel(weaponDeconstructed._rarity);
                        
                uint r = ((((trainingLevelWeapon.level * (trainingLevelWeapon.pct)) + (trainingLevelCharacter.level * (trainingLevelCharacter.pct)))) * PE_ESCALE) / 100;
                reward = reward.add(r);             
        }
        return reward;
    }

    function exchangePE() public{
        uint256 _pe       = pe[msg.sender];
        uint256 _exchange = _pe.div(5);
        rewardWallet.addReward(msg.sender, _exchange);
        pe[msg.sender]    = 0;
    }
}

