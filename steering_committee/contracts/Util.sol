pragma solidity ^0.5.0;

interface ProtoInterface {
    function balance(address _self, uint _blockNumber) external view returns(uint256);
}

contract Util {
    ProtoInterface Prototype = ProtoInterface(0x000000000000000000000050726f746F74797065);

    /**
     * @dev 返回目标区块余额
     * @param _target 目标地址
     * @param _blockNumber 目标区块
     */
    function balanceAtBlock(address _target, uint256 _blockNumber) public view returns(uint256) {
        return Prototype.balance(_target, _blockNumber);
    }
}