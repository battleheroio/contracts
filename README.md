<p align="center">
 <img src="https://gblobscdn.gitbook.com/assets%2F-Mh4TPo3HsBma6e1dTXg%2F-MibLdmf2ntz2qK1I7T7%2F-MibNOF1OMfuYcU892D7%2FGameWallpaper%20(1).jpeg?alt=media&token=9651c27a-89d8-446d-bf72-6adc48075221" alt="SDVersion"/>
</p>
The Battle Hero project was from the minute 0, to create a NFT game where not only rewarded with coins, if not reward those who spend hours playing, enjoying a fun game, entertaining and above all at the forefront with other games today. This game was developed by and for players.   

----

## STEPS TO DEPLOY

 - Deploy BattleHeroTeamWallet

 - Deploy BattleHeroRewardWallet

 - Deploy BattleHeroGenScience

 - Deploy BattleHeroData

 - Deploy BattleHero with next dependencies:     
    - Airdrop Wallet ( Contract Address )
    - Marketing Wallet ( Account )
    - Liquidity Wallet ( Account )
    - Team Wallet ( Contract Address )
    - Reward Wallet ( Contract Address )
    - Reserve Wallet ( Account )

- Deploy BattleHeroFactory with next dependencies: 
    - BattleHeroData ( Contract Address )

- Deploy BattleHeroBreeder with next dependencies: 
    - BattleHeroGenScience ( Contract Address )
    - BattleHeroFactory ( Contract Address )

- Deploy BattleHeroTrainer with next dependencies:
    - BattleHeroData ( Contract Address )
    - BattleHeroFactory ( Contract Address )
    - BattleHero ( Contract Address )
    - BattleHeroRewardWallet ( Contract Address )

- Deploy BattleHeroChestShop with next dependencies: 
    - BattleHero ( Contract Address )
    - BattleHeroGenScience ( Contract Address )
    - BattleHeroBreeder ( Contract Address )

- Deploy BattleHeroMarketplace with next dependencies: 
    - BattleHeroFactory ( Contract Address )
    - USDT ( Contract Address )
    - BattleHero ( Contract Address )

- BattleHeroBreeder should execute `addBreeder(address breeder)` for BattleHeroChestoShop
- BattleHeroFactory should execute `setMinterRole(address role)` for BattleHeroBreeder
- BattleHeroFactory should execute `setLockerRole(address role)` for BattleHeroMarketplace
- BattleHeroFactory should execute `setLockerRole(address role)` for BattleHeroTrainer
- BattleHeroRewardWallet should execute `addRewardDistributorRole(address role)` for BattleHeroTrainer


#### Approves
 - Approve Marketplace to spend NFT
 - Approve Trainer to spend BATH
 - Approve Marketplace to spend BATH
 - Approve ChestShop to spend BATH
 