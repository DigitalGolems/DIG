// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./BEP721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../Utils/Owner.sol";
import "../Utils/SafeMath.sol";
import "../Utils/ControlledAccess.sol";
import "./Interfaces/ICard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "./Interfaces/IDigitalGolems.sol";

contract DigitalGolems is BEP721URIStorage, Owner, ControlledAccess, IDigitalGolems {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    using SafeMath for uint;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    string presaleBaseCID = "Qmb7pUXwe5G4fUMV7ghDx4GkyQw8ZNYfkssEpCFnsV6ui6";
    string presaleBaseURISuffix = ".json";

    string laboratoryBaseCID = "";
    string laboratoryBaseURISuffix = ".json";

    string stakingBaseCID = "";
    string stakingBaseURISuffix = ".json";

    address private _stakingAddress;
    address private _presaleAddress;
    address private _labAddress;

    constructor() BEP721("Digital.Golems", "DIG") {
    }

    function changePresaleBaseCID(string memory newCID) public isOwner {
        presaleBaseCID = newCID;
    }

    function changeLaboratoryCID(string memory newCID) public isOwner {
        laboratoryBaseCID = newCID;
    }

    function changeStakingBaseCID(string memory newCID) public isOwner {
        stakingBaseCID = newCID;
    }

    function setStakingAddress(address _staking) public isOwner {
        _stakingAddress = _staking;
    }

    function setLabAddress(address _lab) public isOwner {
        _labAddress = _lab;
    }

    function setPresaleAddress(address _presale) public isOwner {
        _presaleAddress = _presale;
    }

    function setCard(address _card) public isOwner {
        card = ICard(_card);
    }

    function awardItemLaboratory(
        address player,
        uint256 orderID
    )
        public
        onlyValidAddresses
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        string memory id = orderID.toString();
        string memory tokenURI = string(abi.encodePacked(
          "https://ipfs.io/ipfs/",
          laboratoryBaseCID,
          "/",
          id,
          laboratoryBaseURISuffix
        ));
        _setTokenURI(newItemId, tokenURI);
        card.createCard(
            player,
            newItemId
        );
    }

    function awardItemStaking(
        address player,
        uint256 orderID
    )
        public
        onlyValidAddresses
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        string memory id = orderID.toString();
        string memory tokenURI = string(abi.encodePacked(
          "https://ipfs.io/ipfs/",
          stakingBaseCID,
          "/",
          id,
          stakingBaseURISuffix
        ));
        _setTokenURI(newItemId, tokenURI);
        card.createCard(
            player,
            newItemId
        );
    }

    //for presale
    //only presale address
    function mintPresale(
        address player
    )
        public
        onlyValidAddresses
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        string memory id = newItemId.toString();
        string memory tokenURI = string(abi.encodePacked(
          "https://ipfs.io/ipfs/",
          presaleBaseCID,
          "/",
          id,
          presaleBaseURISuffix
        ));
        _setTokenURI(newItemId, tokenURI);
        card.createCard(
            player,
            newItemId
        );
    }

    function ownerMint(
        address player,
        string memory tokenURI
    )
        public
        isOwner
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);
        card.createCard(
            player,
            newItemId
        );
    }

    modifier onlyValidAddresses() {
        require(
            (msg.sender == _presaleAddress)
            ||
            (msg.sender == _stakingAddress)
            ||
            (msg.sender == _labAddress)
            , "only Valid Addresses");
        _;
    }

}
