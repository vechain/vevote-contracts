pragma solidity ^0.5.0;

interface TokenAuction {
    function isToken(address _target) external view returns(bool);
    function ownerToId(address _target) external view returns(uint256);
    function getMetadata(uint256 _tokenId) external view returns(address, uint8, bool, bool, uint64, uint64, uint64);
}

interface AuthorityInterface {
    function get(address _nodeMaster) external view returns(bool listed, address endorsor, bytes32 identity, bool active);
}

contract Util {
    address public tokenAuctionAddress;

    /**
     * @dev whether normal node or x node
     */
    function isToken(address _target) public view returns(bool) {
        return TokenAuction(tokenAuctionAddress).isToken(_target);
    }

    /**
    * @dev owner to token id
    */
    function ownerToId(address _owner) public view returns(uint256) {
        return TokenAuction(tokenAuctionAddress).ownerToId(_owner);
    }

    /**
     * @dev get token auction info
     */
    function getMetadata(uint256 _tokenId) external view returns(address, uint8, bool, bool, uint64, uint64, uint64) {
        return TokenAuction(tokenAuctionAddress).getMetadata(_tokenId);
    }

    /**
     @dev get authority master node data
     */
    function getMaster(address _target) public view returns(bool listed, address endorsor, bytes32 identity, bool active) {
        return AuthorityInterface(0x0000000000000000000000417574686f72697479).get(_target);
    }

    /**
     @dev whether authority master node
     */
    function isMaster(address _target) public view returns(bool) {
        bool listed = false;
        (listed,,,) = getMaster(_target);
        return listed;
    }
}
