// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../Utils/Owner.sol";
import "../Utils/SafeMath.sol";
import "../Utils/ControlledAccess.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";


contract DigitalGolems is ERC721URIStorage, Owner, ControlledAccess {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using SafeMath for uint;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    address private _gameAddress;
    address private _presaleAddress;
    address private _labAddress;

    constructor() ERC721("Digital.Golems", "DIG") {
    }

    function setGameAddress(address _game) public isOwner {
        _gameAddress = _game;
    }

    function setLabAddress(address _lab) public isOwner {
        _labAddress = _lab;
    }

    function setPresaleAddress(address _presale) public isOwner {
        _presaleAddress = _presale;
    }
 
    function changeAmountOfNumAbilities(uint8 _newAmount) public isOwner {
        amountOfNumAbilities = _newAmount;
    }

    function changeAmountOfBoolAbilities(uint8 _newAmount) public isOwner {
        amountOfBoolAbilities = _newAmount;
    }

    function getAmountOfNumAbilities() public view returns(uint8){
        return amountOfNumAbilities;
    }

    function getAmountOfBoolAbilities() public view returns(uint8){
        return amountOfBoolAbilities;
    }

    function changeAmountOfKinds(uint8 _newAmount) public isOwner {
        amountOfKinds = _newAmount;
    }

    function changeAmountOfSeries(uint8 _newAmount) public isOwner {
        amountOfSeries = _newAmount;
    }

    function getAmountOfKinds() public view returns(uint8){
        return amountOfKinds;
    }

    function getAmountOfSeries() public view returns(uint8){
        return amountOfSeries;
    }

    function awardItem(
        address player,
        string memory tokenURI, 
        uint8 _v,
        bytes32 r,
        bytes32 s,
        uint8[] memory kindSeries
    )
        public 
        onlyGameOrPresale
        onlyValidMint(_v, r, s, tokenURI, player)
    {
        //проверить есть ли ассеты
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);
        createCard(
            player,
            newItemId,
            kindSeries[0], 
            kindSeries[1], 
            tokenURI
        );
    }


    //onlyGameOrPresale
    function decreaseNumAbilityAfterSession(uint256 _ID) public onlyGameOrPresale {
        for (uint8 i = 0; i < amountOfNumAbilities; i++) {
            if (_golemToNumAbility[_ID][i] != 0){
                _golemToNumAbility[_ID][i] = _golemToNumAbility[_ID][i].sub(1);
            }
        }
    }

    function increaseNumAbilityAfterFeeding(uint256 _ID) public onlyGameOrPresale {
        for (uint8 i = 0; i < amountOfNumAbilities; i++) {
            if (_golemToNumAbility[_ID][i] < _golemToAlwaysNumAbility[_ID][i]) {
                _golemToNumAbility[_ID][i] = _golemToNumAbility[_ID][i].add(1);
            }
        }
    }

    function increaseNumAbilityAfterPreservation(uint256 _ID, uint8 _num) public onlyGameOrPresale {
        _golemToAlwaysNumAbility[_ID][_num] = _golemToAlwaysNumAbility[_ID][_num].add(1);
    }

    //for presale
    //only presale address
    function mintPresale(
        address player, 
        string memory tokenURI,
        uint8 kind,
        uint8 series
    )
        public
        onlyGameOrPresale
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);
        createCard(
            player,
            newItemId,
            kind, 
            series, 
            tokenURI
        );
    }

    function ownerMint(
        address player, 
        string memory tokenURI,
        uint8 kind,
        uint8 series
    )
        public 
        isOwner
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);
        createCard(
            player,
            newItemId,
            kind, 
            series, 
            tokenURI
        );
    }

    modifier onlyGameOrPresale() {
        require(
            (msg.sender == _presaleAddress) 
            || 
            (msg.sender == _gameAddress)
            ||
            (msg.sender == _labAddress) 
            , "Only Game,Lab,Presale");
        _;
    }

    function withdrawLINK() public isOwner{
        LinkTokenInterface(_LINK).transfer(owner, LinkTokenInterface(_LINK).balanceOf(address(this)));
    }

}