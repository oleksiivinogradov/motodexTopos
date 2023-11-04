// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact alex@cfc.io if you like to use code

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/Address.sol";

//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./IMotoDEXnft.sol";

contract MotoDEX is Ownable,IERC721Receiver {
    error NotAvaliable();
    error RequireUSDT();
    error RequireMinimalFee();
    error MustBeTrackOrMoto();
    error MustBeGameServer();
    error CantPayToAddressZero();
    error ReentrantGuard();
    error YouAreNotOwner();
    error BellowMinimalInterval();

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public nftContract;
    uint256 public minimalFeeInUSD;
//    AggregatorV3Interface internal priceFeed;
    // tracks:
    uint8 public constant TRACK_LONDON = 100;
    uint8 public constant TRACK_DUBAI = 101;
    uint8 public constant TRACK_ABU_DHABI = 102;
    uint8 public constant TRACK_BEIJIN = 103;
    uint8 public constant TRACK_MOSCOW = 104;
    uint8 public constant TRACK_MELBURN = 105;
    uint8 public constant TRACK_PETERBURG = 106;
    uint8 public constant TRACK_TAIPEI = 107;
    uint8 public constant TRACK_PISA = 108;
    uint8 public constant TRACK_ISLAMABAD = 109;

    // motos:
    uint8 public constant RED_BULLER = 0;
    uint8 public constant ZEBRA_GRRR = 1;
    uint8 public constant ROBO_HORSE = 2;
    uint8 public constant METAL_EYES = 3;
    uint8 public constant BROWN_KILLER = 4;
    uint8 public constant CRAZY_LINE = 5;

    mapping(uint256 => address) public tracksOwners;
    mapping(uint256 => address) public motoOwners;
    mapping(uint256 => uint256) public motoOwnersFeeAmount;
    uint256 balanceOf;

    uint256 public motoOwnersFeesSum;

    struct GameSession {
        uint256 latestUpdateTime;
        uint256 latestTrackTimeResult;
        uint8 attempts;
    }

    struct GameBid {
        uint256 amount;          // Amount of funds
        uint256 trackId;
        uint256 motoId;
        uint256 timestamp;
        address bidder;
        address token;
    }

    mapping(uint256 => mapping(uint256 => GameSession)) public gameSessions;
    mapping(uint => GameBid) public gameBids;
    uint256 gameBidsCount;
    mapping(uint256 => uint256) gameBidsSumPerTrack;

    uint256 public priceMainCoinUSD;
    function getPriceMainCoinUSD() public view returns (uint256) {
        return priceMainCoinUSD;
    }
    function setPriceMainCoinUSD(uint256 price) public onlyOwner {
        priceMainCoinUSD = price;
    }

    function getLatestPrice() public view returns (uint256, uint8) {
//        if (priceMainCoinUSD > 0)
            return (priceMainCoinUSD, 18);

//        (,int256 price,,,) = priceFeed.latestRoundData();
//        uint8 decimals = priceFeed.decimals();
//        return (uint256(price), decimals);
    }
    uint256 public _networkId;

    constructor(uint256 networkId, address _nftContract) {
        _networkId = networkId;
        nftContract =_nftContract;
//        if (networkId == 1)  priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH mainnet
//        if (networkId == 4) priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);// ETH rinkeby
//        if (networkId == 42) priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);// ETH kovan
//        if (networkId == 56) priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);// BCS mainnet
//        if (networkId == 97) priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);// BCS testnet
//        if (networkId == 80001) priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);// Matic testnet
//        if (networkId == 137) {
//            priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);// Matic mainnet
//            valueDecrease = 100000000000000000;
//        }
//        if (networkId == 1001) {
//            priceMainCoinUSD = 283500000000000000;// klaytn testnet
//        }
//        if (networkId == 1281) {
//            priceMainCoinUSD = 2835000000000000000000;// octopus testnet
//        }
//        if (networkId == 9000) {
//            priceMainCoinUSD = 2835000000000000000000;// evmos testnet
//        }
//        if (networkId == 15555) {
//            priceMainCoinUSD = 2835000000000000000000;// trust testnet
//        }
        minimalFeeInUSD = 1000000000000000000; // $1
        latestEpochUpdate = block.timestamp;
        priceMainCoinUSD = 1500000000000000000000;

        //        if (networkId == 1313161554) {
//            priceFeed = AggregatorV3Interface(0x842AF8074Fa41583E3720821cF1435049cf93565);// Aurora mainnet
//            valueDecrease = 100000000000000;
//        }
//        if (networkId == 1313161555) {
//            priceMainCoinUSD = 1500000000000000000000;// Aurora testnet
//            valueDecrease = 100000000000000;
//        }
//        if (networkId == 5) {
//            priceMainCoinUSD = 1500000000000000000000;// goerli testnet
//            valueDecrease = 100;
//        }
//        if (networkId == 1029) {
//            priceMainCoinUSD = 2835000000000000000000000000000000;// BTTC testnet
//            valueDecrease = 100;
//        }
//        if (networkId == 50021) {
//            priceMainCoinUSD = 1500000000000000000000;// BTTC testnet
//            valueDecrease = 100;
//        }
//        if (networkId == 108) {
//            priceMainCoinUSD = 3000000000000000;// thundercore mainnet
//            valueDecrease = 100;
//        }
//        if (networkId == 18) {
//            priceMainCoinUSD = 3000000000000000;// thundercore testnet
//            valueDecrease = 100;
//        }
//        if (networkId == 7001) {
//            priceMainCoinUSD = 3000000000000000;//  testnet
//            valueDecrease = 100;
//        }
//        if (networkId == 5001) {
//            priceMainCoinUSD = 1500000000000000000000;//  testnet
//            valueDecrease = 100;
//        }
//        if (networkId == 15557) {
//            priceMainCoinUSD = 1500000000000000000000;//  testnet
//            valueDecrease = 100;
//        }
//        if (networkId == 17777) {
//            priceMainCoinUSD = 1500000000000000000;//  testnet
//            valueDecrease = 10000;
//        }
//        if (networkId == 5000) {
//            priceMainCoinUSD = 420000000000000000;//
//            valueDecrease = 100;
//        }
        if (networkId == 8453) {
            priceMainCoinUSD = 1500000000000000000000;
            valueDecrease = 100;
        }
//        if (networkId == 88002) {
//            priceMainCoinUSD = 1500000000000000000000;
//            valueDecrease = 100;
//        }
        if (networkId == 1001) {
            priceMainCoinUSD = 1500000000000000000000;
            valueDecrease = 100;
        }
        if (networkId == 10243) {
            priceMainCoinUSD = 1500000000000000000000;
            valueDecrease = 100;
        }
        if (networkId == 2359) {
            priceMainCoinUSD = 1500000000000000000000;
            valueDecrease = 100;
        }
    }
    /*
        getters/setters
    */
    function _setNftContract(address _nftContract) public onlyOwner nonReentrant {
        nftContract =_nftContract;
    }

    function _setEpochMinimalInterval(uint256 _epochMinimalInterval) public onlyOwner nonReentrant {
        epochMinimalInterval = _epochMinimalInterval;
    }

    function _setMinimalFee(uint256 _minimalFeeInUSD) public onlyOwner nonReentrant {
        minimalFeeInUSD = _minimalFeeInUSD;
    }

    function _setTrackOwnerAdmin(address trackOwner, uint256 tokenId) public onlyOwner nonReentrant {
        tracksOwners[tokenId] = trackOwner;
    }

    function _setMotoOwnerAdmin(address motoOwner, uint256 tokenId) public onlyOwner nonReentrant {
        motoOwners[tokenId] = motoOwner;
    }

    function _setGameSessionAdmin(uint256 trackTokenId, uint256 motoTokenId, uint256 latestTrackTimeResult) public onlyOwner nonReentrant {
        bool isUpdate = false;

        if (latestTrackTimeResult == 0) gameSessions[trackTokenId][motoTokenId] = GameSession(block.timestamp, 0, 0);
        else {
            gameSessions[trackTokenId][motoTokenId].latestUpdateTime = block.timestamp;
            gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult = latestTrackTimeResult;
            gameSessions[trackTokenId][motoTokenId].attempts = gameSessions[trackTokenId][motoTokenId].attempts + 1;
        }
        emit CreateOrUpdateGameSession(trackTokenId, motoTokenId, latestTrackTimeResult, block.timestamp, isUpdate);
    }

    function _removeSessionAdmin(uint256 trackTokenId, uint256 motoTokenId) public onlyOwner nonReentrant {
        delete gameSessions[trackTokenId][motoTokenId];
    }

    function getNftContract() public view returns (address) {
        return nftContract;
    }

    function getMinimalFee() public view returns (uint256) {
        return minimalFeeInUSD;
    }

    function getTrackOwner(uint256 tokenId) public view returns (address) {
        return tracksOwners[tokenId];
    }

    function getMotoOwner(uint256 tokenId) public view returns (address) {
        return motoOwners[tokenId];
    }

    function getGameSession(uint256 trackTokenId, uint256 motoTokenId) public view returns (uint256, uint256, uint8) {
        GameSession memory gs = gameSessions[trackTokenId][motoTokenId];
        return (gs.latestUpdateTime, gs.latestTrackTimeResult, gs.attempts);
    }


    struct GameSessionFull {
        uint256 trackId;
        uint256 trackType;
        uint256 trackHealth;
        uint256 motoId;
        uint256 motoType;
        uint256 motoHealth;
        uint256 latestUpdateTime;
        uint256 latestTrackTimeResult;
        uint8 attempts;
        uint256 gameBidsSumTrack;
    }

    function getGameSessions() public view returns (GameSessionFull [] memory, uint256) {
        uint256 [] memory trackIds;
        uint256 trackIdsCount;
        uint256 [] memory motoIds;
        uint256 motoIdsCount;
        (trackIds, trackIdsCount, motoIds, motoIdsCount) = fillMotosTracksIdsAddedToContract();

//        uint256 [] memory trackIdsMotosFeesSum = new uint256 [](balanceOf);
//        uint256 [] memory trackIdsBestTime = new uint256 [](balanceOf);
//        uint256 [] memory trackIdsMotoIdIndexWinner = new uint256 [](balanceOf);

//        while (balanceOfLocal > 0) {
//            balanceOfLocal = balanceOfLocal - 1;
//            uint256 tokenIdOfOwnerByIndex = IERC721Enumerable(nftContract).tokenOfOwnerByIndex(address (this), balanceOfLocal);
//            uint8 typeForId = IMotoDEXnft(nftContract).getTypeForId(tokenIdOfOwnerByIndex);
//            if (typeForId < 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(motoIds, tokenIdOfOwnerByIndex))) {
//                motoIds[motoIdsCount] = tokenIdOfOwnerByIndex;
//                motoIdsCount++;
//            } else if (typeForId >= 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(trackIds, tokenIdOfOwnerByIndex))) {
//                trackIds[trackIdsCount] = tokenIdOfOwnerByIndex;
//                trackIdsCount++;
//            }
//        }
        GameSessionFull [] memory list = new GameSessionFull[](balanceOf);
        uint256 listCount = 0;
        for (uint trackIdIndex = 0; trackIdIndex < trackIdsCount; trackIdIndex++) {
            uint256 trackTokenId = trackIds[trackIdIndex];

            for (uint motoIdIndex = 0; motoIdIndex < motoIdsCount; motoIdIndex++) {
                uint256 motoTokenId = motoIds[motoIdIndex];
                if (gameSessions[trackTokenId][motoTokenId].latestUpdateTime > 0) {
                    GameSession memory gs = gameSessions[trackTokenId][motoTokenId];

                    uint256 latestUpdateTime = gs.latestUpdateTime;
                    uint256 latestTrackTimeResult = gs.latestTrackTimeResult;
                    uint8 attempts = gs.attempts;
                    list[listCount] = GameSessionFull(
                        trackTokenId,
                        IMotoDEXnft(nftContract).getTypeForId(trackTokenId),
                        IMotoDEXnft(nftContract).getHealthForId(trackTokenId),
                        motoTokenId,
                        IMotoDEXnft(nftContract).getTypeForId(motoTokenId),
                        IMotoDEXnft(nftContract).getHealthForId(motoTokenId),
                        latestUpdateTime,
                        latestTrackTimeResult,
                        attempts,
                        gameBidsSumPerTrack[trackTokenId]
                    );
                    listCount++;
                }
            }
        }
        return (list, listCount);
    }

    function isTokenIdPresent(uint256 [] memory allIds, uint256 tokenId) public view returns (bool) {
        for (uint i = 0; i < allIds.length; i++) {
            if (allIds[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    function indexOf(uint256 [] memory elements, uint256 searchItem) public view returns (uint256) {
        for (uint256 i = 0; i < elements.length; i++) {
            if (elements[i] == searchItem) {
                return i;
            }
        }
        return type(uint256).max;
    }

    struct GameSessionGet {
        uint256 trackTokenId;
        uint256 motoTokenId;
        uint256 latestUpdateTime;
        uint256 latestTrackTimeResult;
        uint8 attempts;
    }

    struct GameSessionForTrack {
        uint256 trackTokenId;
        GameSessionGet [] sessions;
        uint256 sessionsCount;
    }


    function getAllGameBids() public view returns (GameBid [] memory, uint256) {
        GameBid [] memory gameBidsFor = new GameBid[](gameBidsCount);
        for (uint i = 0; i < gameBidsCount; i++) {
            gameBidsFor[i] = gameBids[i];
        }
        return (gameBidsFor, gameBidsCount);
    }

    /*
        main functions
    */
    function valueInMainCoin(uint256 valueInUSD) public view returns (uint256) {
        uint256 priceMainToUSDreturned;
        uint8 decimals;
        (priceMainToUSDreturned,decimals) = getLatestPrice();
        uint256 valueToCompare = valueInUSD.mul(10 ** decimals).div(priceMainToUSDreturned);
        return valueToCompare;
    }

    function _checkTypeMoto(uint256 tokenId) private {
        uint8 typeForID = IMotoDEXnft(nftContract).getTypeForId(tokenId);
        if(
            typeForID != RED_BULLER &&
            typeForID != ZEBRA_GRRR &&
            typeForID != ROBO_HORSE &&
            typeForID != METAL_EYES &&
            typeForID != BROWN_KILLER &&
            typeForID != CRAZY_LINE) revert MustBeTrackOrMoto();
    }

    function _checkTypeTrack(uint256 tokenId) private {
        uint8 typeForID = IMotoDEXnft(nftContract).getTypeForId(tokenId);
        if(
            typeForID != TRACK_LONDON &&
            typeForID != TRACK_DUBAI &&
            typeForID != TRACK_ABU_DHABI &&
            typeForID != TRACK_BEIJIN &&
            typeForID != TRACK_MOSCOW &&
            typeForID != TRACK_MELBURN &&
            typeForID != TRACK_PETERBURG &&
            typeForID != TRACK_TAIPEI &&
            typeForID != TRACK_PISA &&
            typeForID != TRACK_ISLAMABAD) revert MustBeTrackOrMoto();
    }

    event AddTrack(uint256 indexed tokenId, uint256 value, address token);

    uint public valueDecrease = 10000000;
    function setValueDecrease(uint _valueDecrease) public onlyOwner {
        valueDecrease = _valueDecrease;
    }


    function addTrack(uint256 tokenId) payable public nonReentrant {
        if (_networkId == 503129905 || _networkId == 1482601649) revert NotAvaliable();
        if (msg.value < valueInMainCoin(minimalFeeInUSD).sub(valueDecrease)) revert RequireMinimalFee();
        _checkTypeTrack(tokenId);
        IMotoDEXnft(nftContract).approveMainContract(address(this), tokenId);
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);
        tracksOwners[tokenId] = msg.sender;
        balanceOf++;
        emit AddTrack(tokenId,msg.value, address (0));
    }

    function addTrackToken(uint256 tokenId, address token) public nonReentrant {
        if (_networkId != 1482601649) revert NotAvaliable();
        if (IMotoDEXnft(nftContract).getUSDT() != token) revert RequireUSDT();
        _checkTypeTrack(tokenId);
        IMotoDEXnft(nftContract).approveMainContract(address(this), tokenId);
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);
        tracksOwners[tokenId] = msg.sender;
        balanceOf++;
        IERC20(token).safeTransferFrom(msg.sender, address(this), minimalFeeInUSD);
        emit AddTrack(tokenId, minimalFeeInUSD, token);
    }

    event ReturnTrack(uint256 indexed tokenId);

    function returnTrack(uint256 tokenId) public nonReentrant {
        if(msg.sender != tracksOwners[tokenId]) revert YouAreNotOwner();
        _checkTypeTrack(tokenId);
        IERC721(nftContract).safeTransferFrom(address(this), msg.sender , tokenId);
        balanceOf--;
        delete tracksOwners[tokenId];
        emit ReturnTrack(tokenId);
    }

    event AddMoto(uint256 indexed tokenId, uint256 value, address token);
    function addMoto(uint256 tokenId) payable public nonReentrant {
        if (_networkId == 503129905 || _networkId == 1482601649) revert NotAvaliable();
        if (msg.value < valueInMainCoin(minimalFeeInUSD).sub(valueDecrease)) revert RequireMinimalFee();
        _checkTypeMoto(tokenId);
        IMotoDEXnft(nftContract).approveMainContract(address(this), tokenId);
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);
        motoOwners[tokenId] = msg.sender;
        motoOwnersFeeAmount[tokenId] =  motoOwnersFeeAmount[tokenId] + msg.value;
        balanceOf++;
        emit AddMoto(tokenId, msg.value, address(0));
    }

    function addMotoToken(uint256 tokenId, address token) public nonReentrant {
        if (_networkId != 1482601649) revert NotAvaliable();
        if (IMotoDEXnft(nftContract).getUSDT() != token) revert RequireUSDT();
        _checkTypeMoto(tokenId);
        IMotoDEXnft(nftContract).approveMainContract(address(this), tokenId);
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);
        motoOwners[tokenId] = msg.sender;
        motoOwnersFeeAmount[tokenId] =  motoOwnersFeeAmount[tokenId] + minimalFeeInUSD;
        balanceOf++;
        IERC20(token).safeTransferFrom(msg.sender, address(this), minimalFeeInUSD);
        emit AddMoto(tokenId, minimalFeeInUSD, token);
    }

    event ReturnMoto(uint256 indexed tokenId);

    function returnMoto(uint256 tokenId) public nonReentrant {
        if(msg.sender != motoOwners[tokenId]) revert YouAreNotOwner();
        _checkTypeMoto(tokenId);
        IERC721(nftContract).safeTransferFrom(address(this), msg.sender , tokenId);
        balanceOf--;
        delete motoOwners[tokenId];
        emit ReturnMoto(tokenId);
    }


    event CreateOrUpdateGameSession(uint256 indexed trackTokenId,uint256 indexed motoTokenId, uint256 latestTrackTimeResult,uint256 timestamp, bool isUpdate);

    function createOrUpdateGameSessionFor(uint256 trackTokenId, uint256 motoTokenId, uint256 latestTrackTimeResult) public {
        if(IMotoDEXnft(nftContract).isGameServer(msg.sender) != true) revert MustBeGameServer();
        if(IERC721(nftContract).ownerOf(trackTokenId) != address(this)) revert YouAreNotOwner();
        if(IERC721(nftContract).ownerOf(motoTokenId) != address(this)) revert YouAreNotOwner();
        if (latestTrackTimeResult == 0) {
            gameSessions[trackTokenId][motoTokenId] = GameSession(block.timestamp, 0, 0);
            emit CreateOrUpdateGameSession(
                trackTokenId,
                motoTokenId,
                gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult,
                gameSessions[trackTokenId][motoTokenId].latestUpdateTime,
                false);
        } else {
            gameSessions[trackTokenId][motoTokenId].latestUpdateTime = block.timestamp;
            gameSessions[trackTokenId][motoTokenId].attempts++;
            gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult = latestTrackTimeResult;
            emit CreateOrUpdateGameSession(
                trackTokenId,
                motoTokenId,
                gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult,
                gameSessions[trackTokenId][motoTokenId].latestUpdateTime,
                true);
        }
    }

    uint256 public latestEpochUpdate;
    uint256 public epochMinimalInterval;


    function isPresentIn(EpochPayment [] memory payments, uint256 paymentsCount, address bidder) public view returns (bool, uint) {
        for (uint indexPayment = 0; indexPayment < paymentsCount; indexPayment++) {
            EpochPayment memory epochPayment = payments[indexPayment];
            if (epochPayment.to == bidder) return (true,indexPayment);
        }
        return (false,type(uint256).max);
    }

    enum ReceiverType{ TRACK, MOTO, BIDDER, PLATFORM}
    event EpochPayFor(uint256 indexed tokenId, address receiver, uint256 amount, ReceiverType receiverType); // 0 - track owner, 1 - moto, 2 - bidder

    struct EpochPayment {
        uint256 amount;
        address to;
        uint256 trackTokenId;
        uint256 motoTokenId;
        uint256 indexForDelete;
        ReceiverType receiverType;
        uint256 amountPlatform;
    }

    function decreasedByHealthLevel(uint256 amount, uint256 tokenId) public view returns (uint256) {
        return amount.mul(IMotoDEXnft(nftContract).getHealthForId(tokenId)).div(IMotoDEXnft(nftContract).getPriceForType(IMotoDEXnft(nftContract).getTypeForId(tokenId)));
    }

    function fillMotosTracksIdsAddedToContract() public view returns
        (uint256 [] memory, uint256,
        uint256 [] memory, uint256)
    {
        uint256 balanceOfLocal = balanceOf;
        uint256 [] memory trackIds = new uint256 [](balanceOf);
        uint256 trackIdsCount;
        uint256 [] memory motoIds = new uint256 [](balanceOf);
        uint256 motoIdsCount;
        while (balanceOfLocal > 0) {
            balanceOfLocal = balanceOfLocal - 1;
            uint256 tokenIdOfOwnerByIndex = IERC721Enumerable(nftContract).tokenOfOwnerByIndex(address (this), balanceOfLocal);
            uint8 typeForId = IMotoDEXnft(nftContract).getTypeForId(tokenIdOfOwnerByIndex);
            if (typeForId < 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(motoIds, tokenIdOfOwnerByIndex))) {
                motoIds[motoIdsCount] = tokenIdOfOwnerByIndex;
                motoIdsCount++;
            } else if (typeForId >= 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(trackIds, tokenIdOfOwnerByIndex))) {
                trackIds[trackIdsCount] = tokenIdOfOwnerByIndex;
                trackIdsCount++;
            }
        }
        return (trackIds, trackIdsCount, motoIds, motoIdsCount);
    }

    function syncEpochResultsMotos() public view returns (EpochPayment [] memory, uint256) {
//        uint256 balanceOfLocal = balanceOf;//IERC721(nftContract).balanceOf(address (this));
        uint256 [] memory trackIds;
        uint256 trackIdsCount;
        uint256 [] memory motoIds;
        uint256 motoIdsCount;
        (trackIds, trackIdsCount, motoIds, motoIdsCount) = fillMotosTracksIdsAddedToContract();

        uint256 [] memory trackIdsMotosFeesSum = new uint256 [](balanceOf);
        uint256 [] memory trackIdsBestTime = new uint256 [](balanceOf);
        uint256 [] memory trackIdsMotoIdIndexWinner = new uint256 [](balanceOf);

//        while (balanceOfLocal > 0) {
//            balanceOfLocal = balanceOfLocal - 1;
//            uint256 tokenIdOfOwnerByIndex = IERC721Enumerable(nftContract).tokenOfOwnerByIndex(address (this), balanceOfLocal);
//            uint8 typeForId = IMotoDEXnft(nftContract).getTypeForId(tokenIdOfOwnerByIndex);
//            if (typeForId < 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(motoIds, tokenIdOfOwnerByIndex))) {
//                motoIds[motoIdsCount] = tokenIdOfOwnerByIndex;
//                motoIdsCount++;
//            } else if (typeForId >= 100 && (tokenIdOfOwnerByIndex == 0 || !isTokenIdPresent(trackIds, tokenIdOfOwnerByIndex))) {
//                trackIds[trackIdsCount] = tokenIdOfOwnerByIndex;
//                trackIdsCount++;
//            }
//        }
        for (uint trackIdIndex = 0; trackIdIndex < trackIdsCount; trackIdIndex++) {
            uint256 trackTokenId = trackIds[trackIdIndex];

            for (uint motoIdIndex = 0; motoIdIndex < motoIdsCount; motoIdIndex++) {
                uint256 motoTokenId = motoIds[motoIdIndex];
                if (gameSessions[trackTokenId][motoTokenId].latestUpdateTime > 0) {
                    trackIdsMotosFeesSum[trackIdIndex] = trackIdsMotosFeesSum[trackIdIndex] + motoOwnersFeeAmount[motoTokenId];

                    if (trackIdsBestTime[trackIdIndex] == 0) {
                        trackIdsBestTime[trackIdIndex] = gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult;
                        trackIdsMotoIdIndexWinner[trackIdIndex] = motoIdIndex;
                    } else {
                        // if trackIdsBestTime higher than new - set  latestTrackTimeResult and trackIdsMotoIdIndexWinner index as winner of track
                        if (trackIdsBestTime[trackIdIndex] < gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult) {
                            trackIdsBestTime[trackIdIndex] = gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult;
                            trackIdsMotoIdIndexWinner[trackIdIndex] = motoIdIndex;
                        }
                    }
                }
            }
        }

        EpochPayment [] memory payments = new EpochPayment[](trackIdsCount.mul(2));
        uint256 paymentsCount;

        for (uint trackIdIndex = 0; trackIdIndex < trackIdsCount; trackIdIndex++) {
            if (trackIdsMotosFeesSum[trackIdIndex] > 0) {
                uint256 trackId = trackIds[trackIdIndex];
//                require(trackOwner != address(0x0000000000000000000000000000000000000000), "syncEpochResultsMotos() trackOwner == 0x0");
//                require(motoOwner != address(0x0000000000000000000000000000000000000000), "syncEpochResultsMotos() motoOwner == 0x0");

                payments[paymentsCount] = EpochPayment(
                    decreasedByHealthLevel(trackIdsMotosFeesSum[trackIdIndex].mul(60).div(100),  motoIds[trackIdsMotoIdIndexWinner[trackIdIndex]]),
                    motoOwners[motoIds[trackIdsMotoIdIndexWinner[trackIdIndex]]],
                        trackId,
                    motoIds[trackIdsMotoIdIndexWinner[trackIdIndex]],
                    type(uint256).max,
                    ReceiverType.MOTO,
                    trackIdsMotosFeesSum[trackIdIndex].mul(10).div(100)
                );
                paymentsCount++;

                payments[paymentsCount] = EpochPayment(
                    decreasedByHealthLevel(trackIdsMotosFeesSum[trackIdIndex].mul(IMotoDEXnft(nftContract).getPercentForTrack(trackId)).div(100), trackId),
                    tracksOwners[trackId],
                        trackId,
                    motoIds[trackIdsMotoIdIndexWinner[trackIdIndex]],
                    type(uint256).max,
                    ReceiverType.TRACK,
                    0
                );
                paymentsCount++;
            }
        }
        return (payments, paymentsCount);
    }

    function syncEpochResultsPaymentsAggregate(
        EpochPayment [] memory _payments, uint256 _paymentsCount
    ) public view returns (
        EpochPayment [] memory, uint256
    ) {
        EpochPayment [] memory payments = new EpochPayment[](_paymentsCount);
        uint256 paymentsCount;

        for (uint i = 0; i < _paymentsCount; i++) {
            EpochPayment memory _payment = _payments[i];
            bool isPresent = false;
            uint256 paymentIndex;
            (isPresent, paymentIndex) = isPresentIn(payments, paymentsCount, _payment.to);
            if (isPresent) {
                payments[paymentIndex].amount = payments[paymentIndex].amount + _payment.amount;
                payments[paymentIndex].amountPlatform = payments[paymentIndex].amountPlatform + _payment.amountPlatform;
            } else {
                payments[paymentsCount] = _payment;
                paymentsCount++;
            }
        }
        return (payments, paymentsCount);
    }

    function syncEpochResultsMotosFinal() public view returns (
        EpochPayment [] memory, uint256
    ) {
        EpochPayment [] memory payments;
        uint256 paymentsCount;
        (payments, paymentsCount) = syncEpochResultsMotos();

        EpochPayment [] memory paymentsFinal;
        uint256 paymentsFinalCount;
        (paymentsFinal, paymentsFinalCount) = syncEpochResultsPaymentsAggregate(payments, paymentsCount);

        return (paymentsFinal,paymentsFinalCount);
    }


    function syncEpochResultsBids() public view returns (EpochPayment [] memory, uint256) {
        EpochPayment [] memory payments = new EpochPayment[](gameBidsCount.mul(3));
        uint256 paymentsCount;
//        uint256 balanceOfLocal = balanceOf;//IERC721(nftContract).balanceOf(address (this));
        uint256 [] memory trackIds;
        uint256 trackIdsCount;
        uint256 [] memory motoIds;
        uint256 motoIdsCount;
        (trackIds, trackIdsCount, motoIds, motoIdsCount) = fillMotosTracksIdsAddedToContract();

        uint256 [] memory trackIdsBestTime = new uint256 [](balanceOf);
        uint256 [] memory trackIdsMotoIdIndexWinner = new uint256 [](balanceOf);

        for (uint trackIdIndex = 0; trackIdIndex < trackIdsCount; trackIdIndex++) {
            uint256 trackTokenId = trackIds[trackIdIndex];

            for (uint motoIdIndex = 0; motoIdIndex < motoIdsCount; motoIdIndex++) {
                uint256 motoTokenId = motoIds[motoIdIndex];
                if (gameSessions[trackTokenId][motoTokenId].latestUpdateTime > 0) {
                    // if trackIdsBestTime zero - set  latestTrackTimeResult and trackIdsMotoIdIndexWinner index as winner of track
                    if (trackIdsBestTime[trackIdIndex] == 0) {
                        trackIdsBestTime[trackIdIndex] = gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult;
                        trackIdsMotoIdIndexWinner[trackIdIndex] = motoIdIndex;
                    } else {
                        // if trackIdsBestTime higher than new - set  latestTrackTimeResult and trackIdsMotoIdIndexWinner index as winner of track
                        if (trackIdsBestTime[trackIdIndex] < gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult) {
                            trackIdsBestTime[trackIdIndex] = gameSessions[trackTokenId][motoTokenId].latestTrackTimeResult;
                            trackIdsMotoIdIndexWinner[trackIdIndex] = motoIdIndex;
                        }
                    }
                }
            }
        }

        uint256 bidsWinCount = 0;
        uint256 bidsWinSum = 0;
        GameBid [] memory bidsWin = new GameBid [](balanceOf);
//        for (uint trackIdIndex = 0; trackIdIndex < trackIdsCount; trackIdIndex++) {
//            uint256 trackTokenId = trackIds[trackIdIndex];
        for (uint indexGameBid = 0; indexGameBid < gameBidsCount; indexGameBid++) {
            GameBid memory gameBid = gameBids[indexGameBid];
            if (gameBid.amount > 0) {
                uint256 trackTokenIdIndex = indexOf(trackIds, gameBid.trackId);
                uint256 motoTokenIdIndex = indexOf(motoIds, gameBid.motoId);

                if (trackIdsMotoIdIndexWinner[trackTokenIdIndex] == motoTokenIdIndex) {
                    // bid win
                    bidsWin[bidsWinCount] = gameBid;
                    bidsWinCount++;
                    bidsWinSum = bidsWinSum + gameBid.amount;
                }
            }
        }
//        }
        /*У нас два разных пула:
1. Все минимальные фее за игру это пул 1 для каждого трека отдельные
2. Все ставки это пул 2 для каждого трека отдельные

Пул 1 распределяется понятно как - 60% выигравшему мото, 30% владельцу трека, 10% проекту

Пул 2 распределяют все кто поставил на выигравшего мото за вычетом 10% проекту, 10% владельцу трека, 10% владельцу мото который выиграл. Выигравшие получают пул за вычетом пропорционально размеру ставки к их сумме.
*/
        for (uint indexGameBid = 0; indexGameBid < bidsWinCount; indexGameBid++) {
            GameBid memory gameBid = bidsWin[indexGameBid];
            uint256 amountToDistribute = gameBidsSumPerTrack[gameBid.trackId].mul(gameBid.amount).div(bidsWinSum);
            payments[paymentsCount] = EpochPayment(
                amountToDistribute.mul(70).div(100),
                gameBid.bidder,
                gameBid.trackId,
                gameBid.motoId,
                indexGameBid,
                ReceiverType.BIDDER,
                amountToDistribute.mul(10).div(100)
            );
            paymentsCount++;
            payments[paymentsCount] = EpochPayment(
                decreasedByHealthLevel(amountToDistribute.mul(10).div(100).mul(IMotoDEXnft(nftContract).getPercentForTrack(gameBid.trackId)).div(100), gameBid.trackId),
                tracksOwners[gameBid.trackId],
                gameBid.trackId,
                gameBid.motoId,
                indexGameBid,
                ReceiverType.TRACK,
                0 // already added 10% from previous payment
            );
            paymentsCount++;
            payments[paymentsCount] = EpochPayment(
                decreasedByHealthLevel(amountToDistribute.mul(10).div(100).mul(IMotoDEXnft(nftContract).getPercentForTrack(gameBid.trackId)).div(100), gameBid.trackId),
                motoOwners[gameBid.motoId],
                gameBid.trackId,
                gameBid.motoId,
                indexGameBid,
                ReceiverType.MOTO,
                0 // already added 10% from previous payment
            );
            paymentsCount++;
        }

        //        for (uint indexGameBid; indexGameBid < gameBidsCount; indexGameBid++) {
//            GameBid memory gameBid = gameBids[indexGameBid];
//            if (gameBid.amount > 0) {
//                uint256 trackTokenIdIndex = indexOf(trackIds, gameBid.trackId);
//                uint256 motoTokenIdIndex = indexOf(motoIds, gameBid.motoId);
//
//                if (trackIdsMotoIdIndexWinner[trackTokenIdIndex] == motoTokenIdIndex) {
//                    payments[paymentsCount] = EpochPayment(
//                        gameBidsSumPerTrack[gameBid.trackId].mul(60).div(100),
//                        gameBid.bidder,
//                        gameBid.trackId,
//                        gameBid.motoId,
//                        indexGameBid,
//                        ReceiverType.BIDDER,
//                        gameBidsSumPerTrack[gameBid.trackId].mul(10).div(100)
//                    );
//                    paymentsCount++;
//                    payments[paymentsCount] = EpochPayment(
//                        decreasedByHealthLevel(gameBidsSumPerTrack[gameBid.trackId].mul(IMotoDEXnft(nftContract).getPercentForTrack(gameBid.trackId)).div(100), gameBid.trackId),
//                        tracksOwners[gameBid.trackId],
//                        gameBid.trackId,
//                        gameBid.motoId,
//                        indexGameBid,
//                        ReceiverType.TRACK,
//                        0 // already added 10% from previous payment
//                    );
//                    paymentsCount++;
//
//                }
//            }
//        }
        return (payments, paymentsCount);
    }



    function syncEpochResultsBidsFinal() public view returns (
        EpochPayment [] memory, uint256
    ) {
        EpochPayment [] memory payments;
        uint256 paymentsCount;
        // TODO gameBidsForDelete
        (payments, paymentsCount) = syncEpochResultsBids();

        EpochPayment [] memory paymentsFinal;
        uint256 paymentsFinalCount;
        (paymentsFinal, paymentsFinalCount) = syncEpochResultsPaymentsAggregate(payments, paymentsCount);

        return (paymentsFinal,paymentsFinalCount);
    }

    struct TokenIdOwnerType {
        uint256 trackTokenId;
        uint8 trackType;
        uint256 motoTokenId;
        uint8 motoType;
        address owner;
    }

    function tokenIdsAndOwners() public view returns (TokenIdOwnerType [] memory, uint256){
        uint256 balanceOfLocal = balanceOf;//IERC721(nftContract).balanceOf(address (this));
        TokenIdOwnerType [] memory result = new TokenIdOwnerType [](balanceOf);
        uint256 resultCount;
        while (balanceOfLocal > 0) {
            balanceOfLocal = balanceOfLocal - 1;
            uint256 tokenIdOfOwnerByIndex = IERC721Enumerable(nftContract).tokenOfOwnerByIndex(address (this), balanceOfLocal);
            uint8 typeForId = IMotoDEXnft(nftContract).getTypeForId(tokenIdOfOwnerByIndex);
            if (typeForId < 100) {
                result[resultCount] = TokenIdOwnerType(
                    type(uint256).max,
                    type(uint8).max,
                    tokenIdOfOwnerByIndex,
                    typeForId,
                    motoOwners[tokenIdOfOwnerByIndex]
                );
            } else if (typeForId >= 100) {
                result[resultCount] = TokenIdOwnerType(
                    tokenIdOfOwnerByIndex,
                    typeForId,
                    type(uint256).max,
                    type(uint8).max,
                    tracksOwners[tokenIdOfOwnerByIndex]
                );
            }
            resultCount++;

        }
        return (result, resultCount);
    }

    function _syncEpochDelete() private {
        uint256 [] memory trackIds;
        uint256 trackIdsCount;
        uint256 [] memory motoIds;
        uint256 motoIdsCount;
        (trackIds, trackIdsCount, motoIds, motoIdsCount) = fillMotosTracksIdsAddedToContract();

        for (uint trackIdIndex = 0; trackIdIndex < trackIdsCount; trackIdIndex++) {
            uint256 trackTokenId = trackIds[trackIdIndex];
            delete gameBidsSumPerTrack[trackTokenId];
            for (uint motoIdIndex = 0; motoIdIndex < motoIdsCount; motoIdIndex++) {
                uint256 motoTokenId = motoIds[motoIdIndex];
                if (gameSessions[trackTokenId][motoTokenId].latestUpdateTime > 0)  delete gameSessions[trackTokenId][motoTokenId];
                if (motoOwnersFeeAmount[motoTokenId] > 0) delete motoOwnersFeeAmount[motoTokenId];
            }
        }
        for (uint i = 0; i < gameBidsCount; i++) {
            delete gameBids[i];
        }
        gameBidsCount = 0;
    }

    function _syncEpochReturnMotos() private {
        uint256 [] memory motoIds;
        uint256 motoIdsCount;
        (, , motoIds, motoIdsCount) = fillMotosTracksIdsAddedToContract();
        for (uint motoIdIndex = 0; motoIdIndex < motoIdsCount; motoIdIndex++) {
            uint256 motoTokenId = motoIds[motoIdIndex];
            IERC721(nftContract).safeTransferFrom(address(this), motoOwners[motoTokenId] , motoTokenId);
            balanceOf--;
            delete motoOwners[motoTokenId];
            emit ReturnMoto(motoTokenId);
        }
    }

    function syncEpoch() public nonReentrant {
        // TODO - configure percents on contract with change possibility
        // all bids distributed around winners bidders (minus 30% to track/moto owners and minus 10% to platform)
        // all moto adding fees distributed to winner (minus 30% to track owners and minus 10% to platform)
        // motos return back to owners, track leaves
        if(IMotoDEXnft(nftContract).isGameServer(msg.sender) != true) revert MustBeGameServer();
        if(block.timestamp - latestEpochUpdate < epochMinimalInterval) revert BellowMinimalInterval();
        EpochPayment [] memory payments;
        uint256 paymentsCount;
        uint256 platformTenPercent;
        (payments, paymentsCount) = syncEpochResultsBidsFinal();
        for (uint i = 0; i < paymentsCount; i++) {
            EpochPayment memory payment = payments[i];
            if(payment.to == address(0x0000000000000000000000000000000000000000)) revert CantPayToAddressZero();

            platformTenPercent = platformTenPercent + payment.amountPlatform;
            Address.sendValue(payable(payment.to), payment.amount);
            emit EpochPayFor(payment.motoTokenId, payment.to, payment.amount, payment.receiverType);
        }

        // all moto adding fees distributed to winner and 30% to crack owners also included (minus 30% to track owners and minus 10% to platform)
        (payments, paymentsCount) = syncEpochResultsMotosFinal();
        for (uint i = 0; i < paymentsCount; i++) {
            EpochPayment memory payment = payments[i];
            if(payment.to == address(0x0000000000000000000000000000000000000000)) revert CantPayToAddressZero();
            platformTenPercent = platformTenPercent + payment.amountPlatform;
            Address.sendValue(payable(payment.to), payment.amount);
            emit EpochPayFor(payment.motoTokenId, payment.to, payment.amount, payment.receiverType);
        }

        _syncEpochDelete();
        _syncEpochReturnMotos();

        // 10% to motoDEX platform
        Address.sendValue(payable(owner()), platformTenPercent);
        latestEpochUpdate = block.timestamp;

        emit EpochPayFor(type(uint256).max, owner(), platformTenPercent, ReceiverType.PLATFORM);
    }

    event BidFor(uint256 indexed trackTokenId,uint256 indexed motoTokenId, uint256 amount, address bidder, address token);

    function bidFor(uint256 trackTokenId, uint256 motoTokenId) payable public nonReentrant {
        if (_networkId == 503129905 || _networkId == 1482601649) revert NotAvaliable();
        if (msg.value < valueInMainCoin(minimalFeeInUSD).sub(valueDecrease)) revert RequireMinimalFee();
        _checkTypeMoto(motoTokenId);
        _checkTypeTrack(trackTokenId);
        gameBids[gameBidsCount] = GameBid(msg.value, trackTokenId, motoTokenId, block.timestamp, msg.sender, address (0));
        gameBidsCount++;
        gameBidsSumPerTrack[trackTokenId] = gameBidsSumPerTrack[trackTokenId] + msg.value;
        emit BidFor(trackTokenId, motoTokenId, msg.value, msg.sender, address (0));
    }
    function bidForToken(uint256 trackTokenId, uint256 motoTokenId, address token, uint256 value)  public nonReentrant {
        if (_networkId != 1482601649) revert NotAvaliable();
        if (IMotoDEXnft(nftContract).getUSDT() != token) revert RequireUSDT();
        _checkTypeMoto(motoTokenId);
        _checkTypeTrack(trackTokenId);
        gameBids[gameBidsCount] = GameBid(value, trackTokenId, motoTokenId, block.timestamp, msg.sender, token);
        gameBidsCount++;
        gameBidsSumPerTrack[trackTokenId] = gameBidsSumPerTrack[trackTokenId] + value;
        IERC20(token).safeTransferFrom(msg.sender, address(this), minimalFeeInUSD);
        emit BidFor(trackTokenId, motoTokenId, value, msg.sender, token);
    }


    function _withdrawSuperAdmin(address token, uint256 amount, uint256 tokenId) public onlyOwner nonReentrant returns (bool) {
        if (amount > 0) {
            if (token == address(0)) {
                Address.sendValue(payable(msg.sender), amount);
                return true;
            } else {
                IERC20(token).safeTransfer(msg.sender, amount);
                return true;
            }
        } else {
            IERC721(nftContract).safeTransferFrom(address(this), msg.sender , tokenId);
        }
        return false;
    }


    /**
       * Always returns `IERC721Receiver.onERC721Received.selector`.
      */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if(_status == _ENTERED) revert ReentrantGuard();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

//    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
//        results = new bytes[](data.length);
//        for (uint256 i = 0; i < data.length; i++) {
//            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
//
//            if (!success) {
//                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
//                if (result.length < 68) revert();
//                assembly {
//                    result := add(result, 0x04)
//                }
//                revert(abi.decode(result, (string)));
//            }
//
//            results[i] = result;
//        }
//    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

//    uint256 counter;
//    function updateCounter() public {
//        counter++;
//    }
//    function updateCounterPayable() public payable {
//        counter++;
//        Address.sendValue(payable(msg.sender), msg.value);
//    }
}
