pragma solidity ^0.5.0;

import "./Util.sol";
import "./AccessControl.sol";

contract Vote is AccessControl, Util {

    // 状态
    enum proposalStatus {
        // 不存在的投票
        NotExist,
        // 投票已创建未开始
        Created,
        // 投票阶段
        Voting,
        // 投票结束(成功)
        Terminated,
        // 已取消的投票
        Canceled
    }

    // 限制类型
    enum proposalCheckType {
        // 无
        None,
        // 余额
        Balance,
        // 白名单
        Whitelist
    }

    // 选项个数
    struct numberOfChecked {
        uint8 min;
        uint8 max;
    }

    // 基本信息
    struct proposalInfo {
        string title;               // 标题
        proposalCheckType checkType;
        numberOfChecked checked;    // 可选项数量
        address creator;            // 创建人
        uint64 createTime;          // 创建时间
        uint64 cancelTime;          // 取消时间
        bytes32[10] options;        // 议题选项
    }

    // 议题限制信息
    struct proposalCondition {
        // 投票人余额区块限制
        uint256 checkpoint;
        uint256 checkBalance;
        mapping(address => bool) whitelist;
        // 投票生效限制
        uint64 votingStartTime;
        uint64 votingEndTime;
    }

    // 议题结果
    struct proposalResult {
        // voter => options
        mapping(address => uint16) voterOptions;

        // optionId => count
        uint64[10] tally;
    }

    uint256 proposalId = 0;
    mapping(uint256 => proposalInfo) internal proposals;
    mapping(uint256 => proposalCondition) proposalConditions;  // 议题id => 投票限制信息
    mapping(uint256 => proposalResult) proposalResults;        // 议题id => 投票结果

    /// Events
    event NewProposal(uint256 indexed proposalId, address indexed creator);
    event ProposalCanceled(uint256 indexed proposalId);

    event ProposalConditionChanged(uint256 indexed proposalId);
    event ProposalWhitelist(uint256 indexed proposalId, address indexed visitor);
    event NewVote(uint256 indexed proposalId, address indexed voter, uint16 options);

    modifier needProposalExist(uint256 _proposalId) {
        require(proposals[_proposalId].createTime > 0, "proposal not exist");
        _;
    }

    /**
     * @dev 创建新议题
     * @param _title 标题
     * @param _checkType 议题校验类型
     * @param _votingStartTime 投票开始时间
     * @param _votingEndTime 投票结束时间
     * @param _minChecked 投票选项最少选择数
     * @param _maxChecked 投票选项最大选择数
     * @param _checkpoint 余额检查
     * @param _checkBalance 余额限制数量
     * @param _whitelist 投票人白名单
     * @param _options 选项描述数组
     */
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
    ) public whenNotPaused notInBlackList returns(uint256) {
        require(_votingStartTime < _votingEndTime, "votingTime invalid");
        require(_minChecked <= _maxChecked, "checked invalid");
        require(_options[0] != bytes32(0), "at least one option");
        if (_checkType == proposalCheckType.Balance) {
            require(_checkBalance > 0, "balance invalid");
        }
        if (_checkType == proposalCheckType.Whitelist) {
            require(_whitelist[0] != address(0), "whitelist invalid");
        }
        proposalInfo memory pInfo = proposalInfo(
            _title,
            _checkType,
            numberOfChecked(_minChecked, _maxChecked),
            msg.sender,
            uint64(now),
            0,
            _options
        );
        proposalId++;
        proposals[proposalId] = pInfo;
        proposalConditions[proposalId] = proposalCondition(
            _checkpoint,
            _checkBalance,
            _votingStartTime,
            _votingEndTime
        );

        for(uint i = 0; i < _whitelist.length; i++) {
            if (_checkType == proposalCheckType.Whitelist && _whitelist[i] != address(0)) {
                proposalConditions[proposalId].whitelist[_whitelist[i]] = true;
                emit ProposalWhitelist(proposalId, _whitelist[i]);
            }
        }

        emit NewProposal(proposalId, msg.sender);

        return proposalId;
    }

    /**
     * @dev 投票
     * @param _proposalId 议题ID
     * @param _options 投票选项
     */
    function cast(uint256 _proposalId, uint16 _options)
            public
            whenNotPaused
            needProposalExist(_proposalId)
    {
        proposalCondition memory p = proposalConditions[_proposalId];
        require(msg.sender != address(0), "sender invalid");
        require(now >= p.votingStartTime && now <= p.votingEndTime,
                "not open voting");
        require(_options > 0 && _options < 1024, "invalid options");

        require(accessProposal(_proposalId, msg.sender), "no authority");

        require(proposalResults[_proposalId].voterOptions[msg.sender] == 0, "cannot cast twice");

        proposalResults[_proposalId].voterOptions[msg.sender] = _options;
        uint8 optionsCount = 0;
        for (uint i = 0; i < 10; i++) {
            if (_options & (2**i) > 0) {
                optionsCount++;
                proposalResults[_proposalId].tally[i]++;
            }
        }
        require(proposals[_proposalId].checked.min <= optionsCount && proposals[_proposalId].checked.max >= optionsCount,
                "options checked failed");

        emit NewVote(_proposalId, msg.sender, _options);
    }

    /**
     * @dev 取消议题
     * @param _proposalId 议题 id
     */
    function cancelProposal(uint256 _proposalId)
            public
            needProposalExist(_proposalId)
    {
        require(proposals[_proposalId].creator == msg.sender, "permission denied");
        proposals[_proposalId].cancelTime = uint64(now);
        emit ProposalCanceled(_proposalId);
    }

    /**
     * @return 是否已投票
     * @param _proposalId 议题 id
     * @param _voter 目标地址
     */
    function hasCast(uint256 _proposalId, address _voter) public view returns(bool isCasted) {
        return proposalResults[_proposalId].voterOptions[_voter] > 0;
    }

    /**
     * @dev 议题基本信息
     * @return 标题，限制类型，最小选择数，最大选择数，创建者，创建时间，取消时间，选项
     * @param _proposalId 议题 id
     */
    function getBasicInfo(uint256 _proposalId)
        public
        view
        returns(string memory title, proposalCheckType checkType, uint8 minChecked, uint8 maxChecked, address creator, uint64 createTime, uint64 cancelTime, bytes32[10] memory options) {
        proposalInfo memory p = proposals[_proposalId];
        return (
            p.title,
            p.checkType,
            p.checked.min,
            p.checked.max,
            p.creator,
            p.createTime,
            p.cancelTime,
            p.options
        );
    }

    /**
     * @dev 议题限制条件
     * @return 余额限制区块高度， 余额限制数，投票开始时间，投票结束时间
     * @param _proposalId 议题 id
     */
    function getCondition(uint256 _proposalId)
            public
            view
            returns(
                uint256 checkpoint,
                uint256 checkBalance,
                uint64 votingStartTime,
                uint64 votingEndTime) {
        proposalCondition memory p = proposalConditions[_proposalId];
        return (
            p.checkpoint,
            p.checkBalance,
            p.votingStartTime,
            p.votingEndTime
        );
    }

    /**
     * @dev 检查目标地址是否有权限投票
     * @param _proposalId 议题 id
     * @param _target address
     */
    function accessProposal(uint256 _proposalId, address _target)           public
             view
             returns (bool isAccess) {
        if (proposals[_proposalId].createTime == 0) {
            return false;
        }
        proposalCondition memory p = proposalConditions[_proposalId];
        proposalCheckType checkType = proposals[_proposalId].checkType;
        if (checkType == proposalCheckType.Balance) {
            return balanceAtBlock(_target, p.checkpoint) >= p.checkBalance;
        }else if (checkType == proposalCheckType.Whitelist) {
            return proposalConditions[proposalId].whitelist[_target];
        }else{
            return true;
        }
    }

    /**
     * @dev 返回所投选项
     * @param _proposalId 议题 id
     * @param _voter 投票人
     */
    function getVoterOptions(uint256 _proposalId, address _voter)          public
            view
            returns(uint16 option) {
        return proposalResults[_proposalId].voterOptions[_voter];
    }

    /**
     * @dev 返回选项投票结果
     * @param _proposalId 议题 id
     */
    function getTally(uint256 _proposalId)
            public
            view
            returns(uint64[10] memory tally) {
        return proposalResults[_proposalId].tally;
    }

    /**
     * @dev 返回议题当前状态
     * @param _proposalId 议题 id
     */
    function status(uint256 _proposalId)
            public
            view
            returns(proposalStatus currentStatus) {
        if(proposals[_proposalId].createTime == 0) {
            return proposalStatus.NotExist;
        }
        if(proposals[_proposalId].cancelTime > 0) {
            return proposalStatus.Canceled;
        }

        proposalCondition memory p = proposalConditions[_proposalId];
        if(now < p.votingStartTime) {
            return proposalStatus.Created;
        } else if(now <= p.votingEndTime) {
            return proposalStatus.Voting;
        } else {
            return proposalStatus.Terminated;
        }
    }
}
