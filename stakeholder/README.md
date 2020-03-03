# Smart Contract for All Stakeholders Voting

## 合约地址
None 

## Table Of Contents
- [APIs](#APIs)
- [Utils](#Utils) 

## APIs
### newProposal
创建议题
```solidity
function newProposal(
        string memory _title,
        proposalType _proposalType,
        uint64 _votingStartTime,
        uint64 _votingEndTime,
        uint8 _minChecked,
        uint8 _maxChecked,
        string[] memory _options,
        uint16[3] memory _ratio
    ) public
    whenNotPaused
    notInBlackList
    isProposer
    returns(uint256)
```

#### Params
- `_title` 议题标题  
- `_proposalType` 议题类型
- `_votingStartTime` 投票开始时间  
- `_votingEndTime` 投票结束时间  
- `_minChecked` 投票选项最少选择数  
- `_maxChecked` 投票选项最大选择数
- `_options` 投票选项设置
- `_ratio` 各身份投票比率

### Returns
- `proposalId`  议题ID  

### cast
投票  
```solidity
function cast(
        uint256 _proposalId, 
        uint32 _options, 
        address _master
        )public
        whenNotPaused
        needProposalExist(_proposalId)
```
#### Params  
- `_proposalId` 议题ID  
- `_options` 投票选项. 即用二进制位代表每个选项，例如选项个数 `10`，若全选，则二进制表示`1111111111`则 options = `1023`  
- `_master` AM(authority master node)节点地址 


### cancelProposal  
取消议题  
```solidity
function cancelProposal(uint256 _proposalId)
        public
        whenNotPaused
        needProposalExist(_proposalId)
```  
#### Params 
- `_proposalId` 议题ID  
#### Returns 
- `_proposalId` 议题ID  


### getBasicInfo  
获取议题基本信息 
```
function getBasicInfo(uint256 _proposalId) 
        public 
        view
        returns(
            string memory title, 
            proposalType pType, 
            uint8 minChecked, 
            uint8 maxChecked, 
            address creator, 
            uint64 createTime, 
            uint64 cancelTime, 
            string[] memory options, 
            uint16[3] memory _ratio)
```  
#### Params 
- `_proposalId` 议题ID  
#### Returns 
- `title` 议题标题  
- `pType` 议题类型
- `minChecked` 投票选项最少选择数  
- `maxChecked` 投票选项最大选择数
- `creator` 议题创建者
- `createTime` 议题创建时间  
- `cancelTime` 议题取消时间
- `options` 投票选项  
- `_ratio` 各身份投票比率

### getCondition  
获取议题限制信息  
```
function getCondition(uint256 _proposalId)
        public
        view
        returns(
            uint64 votingStartTime,
            uint64 votingEndTime
        )
```  
#### Params 
- `_proposalId` 议题ID  
#### Returns 
- `votingStartTime` 投票开始时间  
- `votingEndTime` 投票结束时间  

### accessProposal  
检查目标地址是否有权限投票  
```
function accessProposal(address _target, address _master)  
      public
      view
      returns (bool isAccess)
```
#### Params  
- `_target` 待检查地址  
- `_master` AM(authority master node)节点地址
####  Returns 
- `isAccess` 是否有投票权限  
 
### getVoterOptions  
获取已投票选项值
```
function getVoterOptions(uint256 _proposalId, address _voter)
        public
        view
        returns(uint16 option)
```
#### Params  
- `_proposalId` 议题ID  
- `_voter` 待检查地址  
####  Returns 
- `option` 已投选项的十进制值  

### getTally  
返回投票结果  
```
function getTally(uint256 _proposalId)
        public
        view
        returns(uint64[] memory tally)
```  
#### Params 
- `_proposalId` 议题ID  
#### Returns 
- `tally` 议题各选项所投票数数组  

### status  
返回当前议题状态
```
function status(uint256 _proposalId)
        public
        view
        returns(proposalStatus currentStatus)
```  
#### Params 
- `_proposalId` 议题ID  
#### Returns 
- `currentStatus` 当前议题状态 （0：不存在，1：已创建，2：投票阶段，3：投票结束，4：投票已取消）  

## Utils 

### 检查是否ThorNode
```
function isToken(
        address _target
        ) public 
        view 
        returns(bool)
```
#### Params  
- `_target: string | required` 待检查地址  
#### Returns 
True or False   

### 检查是否AM节点
```
function isMaster(
        address _target
        ) public 
        view 
        returns(bool)
```
#### Params  
- `_target: string | required` 待检查地址  
#### Returns 
True or False 

### VIP181 Token Id   
```
function ownerToId(
        address _owner
        ) public 
        view 
        returns(uint256)
```
#### Params  
- `_target: string | required` address of owner  
#### Returns 
- `uint256` token id  

### Token auction info  
```
function getMetadata(
        uint256 _tokenId
        ) external 
        view 
        returns(
        address, 
        uint8, 
        bool, 
        bool, 
        uint64, 
        uint64, 
        uint64)
```
#### Params  
- `_tokenId: int | required` token id  
#### Returns 
- `address` owner of token  
- `uint8` node level(0-7)
- `bool` whether on upgrade 
- `bool` whether on auction 
- `uint64` last transfer time
- `uint64` created time
- `uint64` update time

### Authority master node info  
```
function getMaster(
        address _target
        ) public 
        view 
        returns(
        bool listed, 
        address endorsor, 
        bytes32 identity, 
        bool active)
```
#### Params  
- `_target` address of authority master node
#### Returns  
- `bool` whether listed  
- `address` endorsor address
- `bytes32` identity
- `bool` whether active 
