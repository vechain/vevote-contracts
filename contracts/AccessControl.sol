pragma solidity ^0.5.0;

import "./Pausable.sol";

contract AccessControl is Pausable {

    mapping(address => bool) public blackList;

    event BlockList(address indexed _badGuy);
    event RemoveFromBlockList(address indexed _innocent);

    /**
     * @dev Modifier to make a function callable only when sender in blacklist.
     */
    modifier inBlackList {
        require(blackList[msg.sender], "operation blocked");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when sender not in blacklist.
     */
    modifier notInBlackList {
        require(!blackList[msg.sender], "operation blocked");
        _;
    }

    /**
     * @param _badGuy Add bad guy to blacklist
     */
    function addToBlackList(address _badGuy) external whenNotPaused onlyOwner {
        blackList[_badGuy] = true;
        emit BlockList(_badGuy);
    }

    /**
     * @param _innocent Remove innocent from blacklist
     */
    function removeFromBlackList(address _innocent) external whenNotPaused onlyOwner {
        blackList[_innocent] = false;
        emit RemoveFromBlockList(_innocent);
    }
}