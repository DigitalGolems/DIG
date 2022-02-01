// SPDX-License-Identifier: GPL-3.0

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.10;

import "../Utils/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Card is VRFConsumerBase{
    bytes32 internal keyHash;
    uint256 internal fee;
    address public _LINK = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06; // LINK Token
    address VRFC = 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C; // VRF Coordinator
    uint256 _fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network) //BSC TEST

    using SafeMath for uint;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    uint8 public amountOfNumAbilities = 7;
    uint8 public amountOfBoolAbilities= 11;
    uint8 public amountOfKinds = 5;
    uint8 public amountOfSeries = 8;
    // uint256 public amountOfGolems = 0;
    
    event MintCard(
        uint8 kind,
        uint8 series,
        string _tokenURI,
        address owner
    );
    event TransferCard(uint _cardID, address _owner, address _to);
    
    //ВОЗМОЖНО ЗДЕСЬ БУДЕТ СЧИТАТЬСЯ ВРЕМЯ ЧТО НЕ ИСПОЛЬЗОВАЛСЯ ГОЛЕМ
    struct Golem{
        uint8 kind;         //↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ Number of kind
        uint8 series;       // Human - 0
        string URI;         // Amphibian - 1
    }                       // Insectoid - 2
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
   
    Golem[] public golems;
    mapping(uint => mapping(uint8 => uint16)) _golemToNumAbility;
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

    
    function _transferCard(uint _cardID, address _from, address _to) internal {
        ownerGolemCount[_to] = ownerGolemCount[_to].add(1);
        ownerGolemCount[_from] = ownerGolemCount[_from].sub(1);
        golemToOwner[_cardID] = _to;
        emit TransferCard(_cardID, _from, _to);
    }

    function createCard(
        address player,
        uint256 ID,
        uint8 kind, 
        uint8 series, 
        string memory tokenURI
    ) 
        internal 
    {
        require((kind < amountOfKinds) && (series < amountOfSeries), "Not enough");
        _createCard(
            player,
            ID,
            kind, 
            series, 
            tokenURI
            );
        emit MintCard(
                kind,
                series,
                tokenURI,
                player
        );
    }

    function _createCard(
        address player,
        uint256 _ID,
        uint8 _kind, 
        uint8 _series, 
        string memory _tokenURI
    ) 
        private 
    {
        golems.push(
            Golem(
                _kind,
                _series,
                _tokenURI
            )
        );
        
        golemToOwner[_ID] = player;
        ownerGolemCount[player] = ownerGolemCount[player].add(1);
        fulfillRandomnessTest(_ID, block.timestamp); //TESTING
        // require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK"); CHAINLINK
        // requestIDToCardID[requestRandomness(keyHash, fee)] = _ID; CHAINLINK
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        for (uint8 i = 0; i < amountOfNumAbilities; i++) {
            uint16 rand = (uint16(uint256(keccak256(abi.encode(randomness, i))) % 10 )) + 1;
            _golemToNumAbility[requestIDToCardID[requestId]][i] = rand;
            _golemToAlwaysNumAbility[requestIDToCardID[requestId]][i] = rand;
        }
        for (uint8 i = 0; i < amountOfBoolAbilities; i++) {
            uint8 rand = (uint8(uint256(keccak256(abi.encode(randomness, i))) % 10 )) + 1;
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

    //get value from number ability
    function getNumAbilityInt(uint256 _id, uint8 _num) public view returns(uint16 int_) {
        int_ = _golemToNumAbility[_id][_num];
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

    //get card series
    function getGolemSeries(uint _id) public view returns(uint8){
        return golems[_id - 1].series;
    }

    //get card kind
    function getGolemKind(uint _id) public view returns(uint8){    
        return golems[_id - 1].kind;
    }

    //get card uri
    function getGolemURI(uint _id) public view returns(string memory){
        return golems[_id - 1].URI;
    }

    //get all cards that player have
    function getCardsByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](ownerGolemCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < golems.length; i++) {
            if (golemToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }


}