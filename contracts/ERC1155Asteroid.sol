// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Asteroid.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC1155Asteroid is IERC1155Asteroid, ERC1155, Ownable, AccessControl {
    using Strings for string;
    using Math for uint256;
    // Only available through launchpad
    bytes32 public constant PURCHASED_ROLE = keccak256("PURCHASED_ROLE");
    // Optional base URI
    string private _baseURI = "";
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenRaisedAmounts;
    mapping(uint256 => uint256) public tokenMinAmounts;
    mapping(uint256 => uint256) public tokenMaxAmounts;
    mapping(uint256 => address) public tokenFundsWallet;
    mapping(uint256 => address) public tokenOwners;
    mapping(uint256 => uint256) public tokenSoldAmounts;

    mapping(uint256 => MetaAsteroid) public metaAsteroidMap;

    struct MetaAsteroid {
        uint256 id;
        uint256 tokenRaisedAmounts;
        uint256 totalSupply;
        uint256 minAmount;
        uint256 maxAmount;
        address initOwner;
        uint256 soldAmount;
        uint256 timestamp;
        uint256 lastUpdatedTimestamp;
    }

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    event MetaAsteroidCreated(
        address contractAddress,
        uint256 tokenId,
        uint256 totalSupply,
        uint256 totalAmounts,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 timestamp
    );

    event BuyRecord(
        address userAddress,
        uint256 id,
        uint256 amount,
        uint256 quantity,
        uint256 timestamp
    );

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Asteroid).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Require _msgSender() to be the creator of the token id
     */
    modifier creatorOnly(uint256 _id) {
        require(
            creators[_id] == _msgSender(),
            "ERC1155Asteroid#creatorOnly: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    /**
     * @dev Require _msgSender() to own more than 0 of the token id
     */
    modifier ownersOnly(uint256 _id) {
        require(
            balanceOf(_msgSender(), _id) > 0,
            "ERC1155Asteroid#ownersOnly: ONLY_OWNERS_ALLOWED"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) Ownable(_msgSender()) {
        name = _name;
        symbol = _symbol;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via string.concat).
        return
            bytes(tokenURI).length > 0
                ? string.concat(_baseURI, tokenURI)
                : super.uri(tokenId);
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Sets `_tokenURI` as the _tokenURI of `_tokenId`.
     */
    function setURI(uint256 _tokenId, string memory _tokenURI)
        public
        creatorOnly(_tokenId)
    {
        _tokenURIs[_tokenId] = _tokenURI;
        emit URI(uri(_tokenId), _tokenId);
    }

    /**
     * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURI = baseURI;
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * NOTE: remove onlyOwner if you want third parties to create new tokens on
     *       your contract (which may change your IDs)
     * NOTE: The token id must be passed. This allows lazy creation of tokens or
     *       creating NFTs by setting the id's high bits with the method
     *       described in ERC1155 or to use ids representing values other than
     *       successive small integers. If you wish to create ids as successive
     *       small integers you can either subclass this class to count onchain
     *       or maintain the offchain cache of identifiers recommended in
     *       ERC1155 and calculate successive ids from that.
     * @param _initialOwner address of the first owner of the token
     * @param _id The id of the token to create (must not currenty exist).
     * @param _initialSupply amount to supply the first owner
     * @param _initialRaisedAmounts The total amount of money the mine needs to raise
     * @param _uri Optional URI for this token type
     * @param _data Data to pass if receiver is contract
     * @return The newly created token ID
     */
    function create(
        address _initialOwner,
        uint256 _id,
        uint256 _initialSupply,
        uint256 _initialRaisedAmounts,
        uint256 _initialMinAmount,
        uint256 _initialMaxAmount,
        address _initialFundsWallet,
        string memory _uri,
        bytes memory _data
    ) public onlyOwner returns (uint256) {
        // check parameters
        validateParameters(
            _id,
            _initialSupply,
            _initialRaisedAmounts,
            _initialMinAmount,
            _initialMaxAmount,
            _initialFundsWallet
        );

        creators[_id] = _msgSender();

        if (bytes(_uri).length > 0) {
            _tokenURIs[_id] = _uri;
            emit URI(_uri, _id);
        }

        _mint(_initialOwner, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        tokenRaisedAmounts[_id] = _initialRaisedAmounts;
        tokenMinAmounts[_id] = _initialMinAmount;
        tokenMaxAmounts[_id] = _initialMaxAmount;
        tokenFundsWallet[_id] = _initialFundsWallet;
        tokenOwners[_id] = _initialOwner;

        setMetaAsteroidRecord(
            _id,
            _initialRaisedAmounts,
            _initialSupply,
            _initialMinAmount,
            _initialMaxAmount,
            _initialOwner
        );

        emit MetaAsteroidCreated(
            address(this),
            _id,
            _initialSupply,
            _initialRaisedAmounts,
            _initialMinAmount,
            _initialMaxAmount,
            block.timestamp
        );
        return _id;
    }

    function validateParameters(
        uint256 _id,
        uint256 _initialSupply,
        uint256 _initialRaisedAmounts,
        uint256 _initialMinAmount,
        uint256 _initialMaxAmount,
        address _initialFundsWallet
    ) internal view {
        require(!_exists(_id), "token _id already exists");
        require(
            _initialFundsWallet != address(0),
            "Invalid initialFunds Wallet"
        );
        require(
            _initialSupply > 0 &&
                _initialRaisedAmounts > 0 &&
                _initialMinAmount > 0 &&
                _initialMaxAmount >= _initialMinAmount,
            "Invalid amount"
        );
        require(
            _initialRaisedAmounts >= _initialSupply,
            "Invalid funds and shares raised"
        );
        uint256 perShares = perShareValue(
            _initialRaisedAmounts,
            _initialSupply
        );
        require(_initialMinAmount >= perShares, "Invalid shares");
    }

    function setMetaAsteroidRecord(
        uint256 _id,
        uint256 _initialRaisedAmounts,
        uint256 _initialSupply,
        uint256 _initialMinAmount,
        uint256 _initialMaxAmount,
        address _initialOwner
    ) internal {
        MetaAsteroid memory metaAsteroidRecord = MetaAsteroid({
            id: _id,
            tokenRaisedAmounts: _initialRaisedAmounts,
            totalSupply: _initialSupply,
            minAmount: _initialMinAmount,
            maxAmount: _initialMaxAmount,
            initOwner: _initialOwner,
            soldAmount: 0,
            timestamp: block.timestamp,
            lastUpdatedTimestamp: block.timestamp
        });
        metaAsteroidMap[_id] = metaAsteroidRecord;
    }

    function buy(
        address userAddress,
        uint256 id,
        uint256 amount
    ) external onlyRole(PURCHASED_ROLE) returns (bool success) {
        require(_exists(id), "ERC1155Asteroid#buy: Token id not exists");
        require(
            amount >= tokenMinAmounts[id] && amount <= tokenMaxAmounts[id],
            "ERC1155Asteroid#buy: Invalid amount"
        );
        address from = tokenOwners[id];
        require(
            from != userAddress,
            "ERC1155Asteroid#buy: Can't buy your own assets"
        );
        uint256 quantity = calculQuantities(id, amount);
        require(quantity > 0, "ERC1155Asteroid#buy: Invalid quantity");
        if (!isApprovedForAll(from, _msgSender())) {
            _setApprovalForAll(from, _msgSender(), true);
        }
        safeTransferFrom(from, userAddress, id, quantity, "");
        tokenSoldAmounts[id] = tokenSoldAmounts[id] + amount;

        emit BuyRecord(userAddress, id, amount, quantity, block.timestamp);

        return true;
    }

    function calculQuantities(uint256 id, uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 totalAmounts = tokenRaisedAmounts[id];
        uint256 supply = tokenSupply[id];
        uint256 perSV = totalAmounts / supply;
        require(amount % perSV == 0, "ERC1155Asteroid#buy: Invalid quantity");

        return (amount * supply) / totalAmounts;
    }

    /**
     * @dev Mints some amount of tokens to an address
     * @param _to          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     * @param _data        Data to pass if receiver is contract
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public creatorOnly(_id) {
        _mint(_to, _id, _quantity, _data);
        (, uint256 total) = Math.tryAdd(tokenSupply[_id], _quantity);
        tokenSupply[_id] = total;
    }

    /**
     * @dev Mint tokens for each id in _ids
     * @param _to          The address to mint tokens to
     * @param _ids         Array of ids to mint
     * @param _amounts  Array of amounts of tokens to mint per id
     * @param _data        Data to pass if receiver is contract
     */
    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            require(
                creators[_id] == _msgSender(),
                "ERC1155Asteroid#batchMint: ONLY_CREATOR_ALLOWED"
            );
            uint256 quantity = _amounts[i];
            (, uint256 total) = Math.tryAdd(tokenSupply[_id], quantity);
            tokenSupply[_id] = total;
        }
        _mintBatch(_to, _ids, _amounts, _data);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual onlyOwner {
        if (
            account != _msgSender() && !isApprovedForAll(account, _msgSender())
        ) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual onlyOwner {
        if (
            account != _msgSender() && !isApprovedForAll(account, _msgSender())
        ) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }
        _burnBatch(account, ids, values);
    }

    /**
     * @dev Change the creator address for given tokens
     * @param _to   Address of the new creator
     * @param _ids  Array of Token IDs to change creator
     */
    function setCreator(address _to, uint256[] memory _ids) public {
        require(
            _to != address(0),
            "ERC1155Asteroid#setCreator: INVALID_ADDRESS."
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            _setCreator(id, _to);
        }
    }

    /**
     * @dev Change the creator address for given token
     * @param _to   Address of the new creator
     * @param _id  Token IDs to change creator of
     */
    function _setCreator(uint256 _id, address _to) internal creatorOnly(_id) {
        creators[_id] = _to;
    }

    function setPurchaseRule(
        uint256 _id,
        uint256 _minAmount,
        uint256 _maxAmount
    ) public creatorOnly(_id) {
        require(
            _exists(_id),
            "ERC1155Asteroid#setPurchaseRule: token not exists"
        );
        require(
            _minAmount > 0 && _maxAmount > 0 && _minAmount <= _maxAmount,
            "ERC1155Asteroid#setPurchaseRule: invalid amount"
        );
        uint256 perShares = perShareValue(
            tokenRaisedAmounts[_id],
            tokenSupply[_id]
        );
        require(_minAmount >= perShares, "Invalid shares");
        tokenMinAmounts[_id] = _minAmount;
        tokenMaxAmounts[_id] = _maxAmount;
        MetaAsteroid storage metaChange = metaAsteroidMap[_id];
        metaChange.minAmount = _minAmount;
        metaChange.maxAmount = _maxAmount;
        metaChange.lastUpdatedTimestamp = block.timestamp;
    }

    function perShareValue(uint256 totalAmount, uint256 supply)
        internal
        pure
        returns (uint256)
    {
        require(totalAmount % supply == 0, "Invalid perShareValue");
        return totalAmount / supply;
    }

    function perShareValue(uint256 _id) external view returns (uint256) {
        return tokenRaisedAmounts[_id] / tokenSupply[_id];
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function exists(uint256 _id) external view returns (bool) {
        return _exists(_id);
    }

    function fundsWallet(uint256 _id) external view returns (address) {
        return tokenFundsWallet[_id];
    }

    function metaAsteroid(uint256 _id)
        external
        view
        returns (MetaAsteroid memory)
    {
        MetaAsteroid memory updateMeta = metaAsteroidMap[_id];
        updateMeta.soldAmount = tokenSoldAmounts[_id];

        return updateMeta;
    }
}
