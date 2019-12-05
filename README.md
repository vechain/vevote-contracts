# 战略决策委员会投票合约

## 合约地址
- `vote`:  0xDBAeC4165A6cff07901C41D3561EEFdCFbc20CB6

## APIs
### newProposal
创建议题
```
function newProposal(
        string memory _title,
        proposalCheckType _checkType,
        uint64 _votingStartTime,
        uint64 _votingEndTime,
        uint8 _minChecked,
        uint8 _maxChecked,
        uint256 _checkpoint,
        uint256 _checkBalance,
        address[10] memory _whitelist,
        bytes32[10] memory _options
    ) public whenNotPaused notInBlackList returns(uint256)
```

#### Params
- `_title` 议题标题  
- `_checkType` 议题投票限制类型 (0：无投票限制，1：余额限制， 2： 白名单限制)  
- `_votingStartTime` 投票开始时间  
- `_votingEndTime` 投票结束时间  
- `_minChecked` 投票选项最少选择数  
- `_maxChecked` 投票选项最大选择数
- `_checkpoint` 余额限制区块高度  
- `_checkBalance` 余额限制数量  
- `_whitelist` 白名单列表，长度限制 10。如果 `_checkType = 2`，则 whitelist 必须设置。默认设置为全 0 地址 `0x0000000000000000000000000000000000000000`  
- `_options` 投票选项设置。长度 10  

### Returns
- `proposalId`  议题ID  

### cast
投票  
```
function cast(uint256 _proposalId, uint16 _options)
        public
        whenNotPaused
        needProposalExist(_proposalId)
```
#### Params  
- `_proposalId` 议题ID  
- `_options` 投票选项. 即用二进制位代表每个选项，例如全选的话，二进制表示`1111111111`则 options = 1023  

### cancelProposal  
取消议题  
```
function cancelProposal(uint256 _proposalId)
        public
        needProposalExist(_proposalId)
```  
#### Params 
- `_proposalId` 议题ID  
#### Returns 
- `_proposalId` 议题ID  

### hasCast  
检查是否已投票 
#### Params 
- `_proposalId` 议题ID  
- `_voter` 投票地址   
#### Returns 
- `isCasted` 是否已投票  

### getBasicInfo  
获取议题基本信息 
```
function getBasicInfo(uint256 _proposalId) 
        public 
        view
        returns(
            string memory title, 
            proposalCheckType checkType, 
            uint8 checkedMin, 
            uint8 checkedMax, 
            address creator, 
            uint64 createTime, 
            uint64 cancelTime, 
            bytes32[10] memory options
        )
```  
#### Params 
- `_proposalId` 议题ID  
#### Returns 
- `title` 议题标题  
- `checkType` 议题投票限制类型 (0：无投票限制，1：余额限制， 2： 白名单限制)
- `minChecked` 投票选项最少选择数  
- `maxChecked` 投票选项最大选择数
- `creator` 议题创建者
- `createTime` 议题创建时间  
- `cancelTime` 议题取消时间
- `options` 投票选项  

### getCondition  
获取议题限制信息  
```
function getCondition(uint256 _proposalId)
        public
        view
        returns(
            uint256 checkpoint,
            uint256 checkBalance,
            uint64 votingStartTime,
            uint64 votingEndTime
        )
```  
#### Params 
- `_proposalId` 议题ID  
#### Returns 
- `votingStartTime` 投票开始时间  
- `votingEndTime` 投票结束时间  
- `checkpoint` 余额限制区块高度  
- `checkBalance` 余额限制数量  

### accessProposal  
检查目标地址是否有权限投票  
```
function accessProposal(uint256 _proposalId, address _target)  
      public
      view
      returns (bool isAccess)
```
#### Params  
- `_proposalId` 议题ID  
- `_target` 待检查地址  
####  Returns 
- `isAccess` 是否有权限  
 
### getVoterOptions  
获取已投票选项值
```
function getVoterOptions(uint256 _proposalId, address _voter)              public
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
        returns(uint64[10] memory tally)
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
