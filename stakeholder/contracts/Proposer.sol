pragma solidity ^0.5.0;

import "./Pausable.sol";

contract Proposer is Pausable {

    mapping(address => bool) public proposerList;

    event ProposerList(address indexed _proposer);
    event RemoveFromProposerList(address indexed _proposer);

    /**
     * @dev Modifier to make a function callable only when sender in proposer list.
     */
    modifier isProposer {
        require(proposerList[msg.sender], "operation blocked");
        _;
    }

    /**
     * @param _proposer Add proposer to proposer list
     */
    function addToProposerList(address _proposer) external whenNotPaused onlyOwner {
        proposerList[_proposer] = true;
        emit ProposerList(_proposer);
    }

    /**
     * @param _proposer Remove proposer from proposer list
     */
    function removeFromWhitelist(address _proposer) external whenNotPaused onlyOwner {
        proposerList[_proposer] = false;
        emit RemoveFromProposerList(_proposer);
    }
}