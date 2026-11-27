// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MembershipNFT is ERC721 {
    uint256 public constant MAX_PER_WALLET = 1;
    uint256 public nextTokenId = 1;
    mapping(address account => uint256 count) public mintedBy;
    mapping(uint256 tokenId => string uri) private _tokenURIs;

    event Minted(address indexed account, uint256 indexed tokenId);

    constructor() ERC721("Membership", "MEMB") {}

    function mint() external returns (uint256 tokenId) {
        require(mintedBy[msg.sender] < MAX_PER_WALLET, "wallet limit");
        tokenId = nextTokenId++;
        _safeMint(msg.sender, tokenId);
        mintedBy[msg.sender] += 1;
        emit Minted(msg.sender, tokenId);
    }

    function setTokenURI(uint256 tokenId, string calldata uri) external {
        require(ownerOf(tokenId) == msg.sender, "not token owner");
        _tokenURIs[tokenId] = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }
}
