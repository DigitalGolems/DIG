// SPDX-License-Identifier: GPL-3.0

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.10;

import "../Utils/SafeMath.sol";
import "../Utils/Owner.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../Game/Rent/IRent.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./Interfaces/ICard.sol";

contract Card is VRFConsumerBase, Owner, ICard {
    using Counters for Counters.Counter;
    Counters.Counter private _cardIds;
    bytes32 internal keyHash;
    uint256 internal fee;
    address public _LINK = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06; // LINK Token
    address VRFC = 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C; // VRF Coordinator
    uint256 _fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network) //BSC TEST

    using SafeMath for uint;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    address private _gameAddress;
    address private _conservationAddress;
    address private _digAddress;
    IRent private rent;

    uint8 public amountOfNumAbilities = 7;
    uint8 public amountOfBoolAbilities= 11;
    uint8 public amountOfKinds = 5;
    uint8 public amountOfSeries = 8;

    //↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ Number of kind
    // Human - 0
    // Amphibian - 1
    // Insectoid - 2
    // Bird - 3
    // Animal - 4
    //series
    //0 - 0 generation,
    //1 - 1 generation
    //2 - 2 generation,
    //3 - 3 generation
    //4 - new generation,
    //5 - missing models
    //6 - elemental/epics,
    //7 - gold.

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ Sequence number for NUMBER ability
    // uint16 flashlightLength - 0
    // uint16 goingSpeed - 1
    // uint16 spentEnergy - 2
    // uint16 trapRadius - 3;
    // uint16 snareRadius - 4;
    // uint16 radarSize - 5;
    // uint16 jumpHeight - 6;

    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ Sequence number for BOOL ability
    // bool gasResistance - 0;
    // bool corrosionResistance - 1;
    // bool electoAmomalyResistance - 2;
    // bool coldResistance - 3;
    // bool heatResistance - 4;
    // bool sandPassing - 5;
    // bool waterPassing - 6;
    // bool firePassing - 7;
    // bool acidPassing; - 8;
    // bool seesMines - 9;
    // bool seesTraps - 10;
    mapping(uint => mapping(uint8 => uint16)) _golemToNumAbility;
    //always ability needs for feeding and preservation
    //cant feed golem more than always
    mapping(uint => mapping(uint8 => uint16)) _golemToAlwaysNumAbility;
    mapping(uint => mapping(uint8 => bool)) _golemToBoolAbility;
    mapping(uint => address) public golemToOwner;
    mapping(address => uint) public ownerGolemCount;
    mapping(bytes32 => uint) public requestIDToCardID;

    constructor()
        VRFConsumerBase(
            VRFC,
            _LINK
        )
    {
        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        fee = _fee;
    }

    function setGameAddress(address _game) public isOwner {
        _gameAddress = _game;
    }

    function setDIGAddress(address _dig) public isOwner {
        _digAddress = _dig;
    }

    function setConserveAddress(address _conserve) public isOwner {
        _conservationAddress = _conserve;
    }

    function setRentAddress(address _rent) public isOwner {
        rent = IRent(_rent);
    }

    //changing amount of abilies by owner
    //every has new abilities amount
    function changeAmountOfNumAbilities(uint8 _newAmount) public isOwner {
        amountOfNumAbilities = _newAmount;
    }

    //changing amount of abilies by owner
    //every has new abilities amount
    function changeAmountOfBoolAbilities(uint8 _newAmount) public isOwner {
        amountOfBoolAbilities = _newAmount;
    }

    function getAmountOfNumAbilities() public view returns(uint8){
        return amountOfNumAbilities;
    }

    function getAmountOfBoolAbilities() public view returns(uint8){
        return amountOfBoolAbilities;
    }

    //change amount of golem kinds
    function changeAmountOfKinds(uint8 _newAmount) public isOwner {
        amountOfKinds = _newAmount;
    }

    //change amount of golem series
    function changeAmountOfSeries(uint8 _newAmount) public isOwner {
        amountOfSeries = _newAmount;
    }

    function getAmountOfKinds() public view returns(uint8){
        return amountOfKinds;
    }

    function getAmountOfSeries() public view returns(uint8){
        return amountOfSeries;
    }

    //transfer card
    //with modifier onlyDIG because used only when NFT that tied to card is transfered
    function transferCard(uint _cardID, address _from, address _to) public onlyDIG {
        //checks if its rented card or just on the market
        (uint256 _rentItemID, bool _existRentItem) = rent.getItemIDByCardID(_cardID);
        //cant transfer if item with this card exist
        if (_existRentItem == true) {
            require(rent.isClosed(_rentItemID) == true, "Its on Rent Market");
        }
        //writing data
        ownerGolemCount[_to] = ownerGolemCount[_to].add(1);
        ownerGolemCount[_from] = ownerGolemCount[_from].sub(1);
        golemToOwner[_cardID] = _to;
        emit TransferCard(_cardID, _from, _to);
    }//ЧЕКНУТЬ EXIST

    //public function of card creation
    //using only for NFT contract
    function createCard(
        address player, //card player
        uint256 ID     //NFT ID
    )
        public
        onlyDIG
    {
        _createCard(
            player,
            ID
            );
        emit MintCard(
                ID,
                player
        );
    }

    //private function for card creation
    function _createCard(
        address player,
        uint256 _ID
    )
        private
    {
        //adding golem to player
        golemToOwner[_ID] = player;
        //player golem count +1
        _cardIds.increment();
        ownerGolemCount[player] = ownerGolemCount[player].add(1);
        //reques randomness is used for randomly adding abilities to golem
        fulfillRandomnessTest(_ID, block.timestamp); //TESTING
        // require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK"); CHAINLINK
        // requestIDToCardID[requestRandomness(keyHash, fee)] = _ID; CHAINLINK
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        //creating cycle for num abilities
        for (uint8 i = 0; i < amountOfNumAbilities; i++) {
            //create new random for different values
            uint16 rand = (uint16(uint256(keccak256(abi.encode(randomness, i))) % 10 )) + 1;
            //add ability to golem
            _golemToNumAbility[requestIDToCardID[requestId]][i] = rand;
            //add always ability to golem
            _golemToAlwaysNumAbility[requestIDToCardID[requestId]][i] = rand;
        }
        for (uint8 i = 0; i < amountOfBoolAbilities; i++) {
            //create new random for different values
            uint8 rand = (uint8(uint256(keccak256(abi.encode(randomness, i))) % 10 )) + 1;
            //if rand more than 5 bool ability is true
            //if less is false
            _golemToBoolAbility[requestIDToCardID[requestId]][i] = rand > 5 ? true : false;
        }
    }

    //TESTING
    function fulfillRandomnessTest(uint256 id, uint256 randomness) internal {
        for (uint8 i = 0; i < amountOfNumAbilities; i++) {
            uint16 rand = (uint16(uint256(keccak256(abi.encode(randomness, i))) % 10 )) + 1;
            _golemToNumAbility[id][i] = rand;
            _golemToAlwaysNumAbility[id][i] = rand;
        }
        for (uint8 i = 0; i < amountOfBoolAbilities; i++) {
            uint8 rand = (uint8(uint256(keccak256(abi.encode(randomness, i))) % 10 )) + 1;
            _golemToBoolAbility[id][i] = rand > 5 ? true : false;
        }
    }

    function isAllInitialAbilities(uint256 _ID) public view returns(bool flag) {
        for (uint8 i = 0; i < amountOfNumAbilities; i++) {
            if (_golemToNumAbility[_ID][i] == _golemToAlwaysNumAbility[_ID][i]){
                flag = true;
            } else {
                flag == false;
                break;
            }
        }
    }

    //counts different between always ability and actual
    function diffrenceBetweenInitialAndActualMaxAbilities(uint256 _ID) public view returns(uint16 diff){
        (uint16 maxAbility, uint8 i) = getMaxAbility(_ID);
        diff = maxAbility - _golemToNumAbility[_ID][i];
    }

    //get max ability
    //using for creating fed deposit in rent contract
    //fed deposit = max ability * fed price
    function getMaxAbility(uint256 _ID) public view returns(uint16 max, uint8 _i) {
        max = 0;
        for (uint8 i = 0; i < amountOfNumAbilities; i++) {
            if (_golemToAlwaysNumAbility[_ID][i] > max){
                max = _golemToAlwaysNumAbility[_ID][i];
                _i = i;
            }
        }
    }

    //onlyGameOrConservation
    //after session each ability is decreased by one
    function decreaseNumAbilityAfterSession(uint256 _ID) public onlyGameOrConservation {
        for (uint8 i = 0; i < amountOfNumAbilities; i++) {
            if (_golemToNumAbility[_ID][i] != 0){
                _golemToNumAbility[_ID][i] = _golemToNumAbility[_ID][i].sub(1);
            }
        }
    }

    //increasing all abilities by one after golem feeding
    function increaseNumAbilityAfterFeeding(uint256 _ID) public onlyGameOrConservation {
        require(isAllInitialAbilities(_ID) == false, "Already Fed");
        for (uint8 i = 0; i < amountOfNumAbilities; i++) {
            //actual ability cant be more than always
            if (_golemToNumAbility[_ID][i] < _golemToAlwaysNumAbility[_ID][i]) {
                _golemToNumAbility[_ID][i] = _golemToNumAbility[_ID][i].add(1);
            }
        }
    }

    //after preservation increasing always abilities
    function increaseNumAbilityAfterPreservation(uint256 _ID, uint8 _num) public onlyGameOrConservation {
        _golemToAlwaysNumAbility[_ID][_num] = _golemToAlwaysNumAbility[_ID][_num].add(1);
    }

    //get value from number ability
    function getNumAbilityInt(uint256 _id, uint8 _num) public view returns(uint16 int_) {
        int_ = _golemToNumAbility[_id][_num];
    }

    function getAlwaysNumAbilityInt(uint256 _id, uint8 _num) public view returns(uint16 int_) {
        int_ = _golemToAlwaysNumAbility[_id][_num];
    }

    //get value from bool ability
    function getBoolAbilityBool(uint256 _id, uint8 _num) public view returns(bool bool_) {
        bool_ = _golemToBoolAbility[_id][_num];
    }

    //card quantity of player
    function cardCount(address _owner) public view returns(uint) {
        return ownerGolemCount[_owner];
    }

    //get owner of card
    function cardOwner(uint _id) public view returns(address) {
        return golemToOwner[_id];
    }

    //get all cards that player have
    function getCardsByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](ownerGolemCount[_owner]);
        uint256 counter = 0;
        uint256 current = _cardIds.current();
        for (uint i = 1; i <= current; i++) {
            if (golemToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function withdrawLINK() public isOwner{
        LinkTokenInterface(_LINK).transfer(owner, LinkTokenInterface(_LINK).balanceOf(address(this)));
    }

    modifier onlyGameOrConservation() {
        require(
            (msg.sender == _gameAddress)
            ||
            (msg.sender == _conservationAddress)
            , "Only Game,Conservation");
        _;
    }

    modifier onlyDIG() {
        require(
            msg.sender == _digAddress,
            "Only DIG"
        );
        _;
    }

    modifier onlyRent() {
        require(
            msg.sender == address(rent),
            "Only Rent"
        );
        _;
    }

}
