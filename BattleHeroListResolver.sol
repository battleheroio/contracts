// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./shared/IBattleHeroFactory.sol";


contract BattleHeroListResolver{
    IBattleHeroFactory _factory;
    constructor(){
        _factory = IBattleHeroFactory(0xc3d210fc7741F998D45247d0eA6B451B32f06b74);        
    }

    function heroesOf(address owner) public view returns(uint256[] memory){
        uint256 tokenCount = _factory.balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256[] memory _heroesId = _factory.heroesId();
            uint256 totalHeroes     = _heroesId.length;
            uint256 resultIndex     = 0;
            // We count on the fact that all cats have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 heroId;
            for (heroId = 0; heroId <= totalHeroes; heroId++) {
                // if (_factory.ownerOf( _heroesId[heroId] ) == owner) {
                    // result[resultIndex] = _heroesId[heroId];
                    // resultIndex++;
                // }
            }
            return result;
        }
    }


}