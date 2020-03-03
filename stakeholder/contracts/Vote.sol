pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Util.sol";
import "./AccessControl.sol";
import "./Proposer.sol";

contract Vote is AccessControl, Util, Proposer {

    // 议题类型
    enum proposalType {
        // 超级权限管理
        AuthorityMasternodesMangement,
        // 战略决策委员会成员变更
        SteeringCommitteeMembers,
        // 超级权益节点出块奖励管理
        AMRewardRate,
        // Gas price 管理
        GasPrice,
        // 超级权益节点VET质押数量管理
        CollateralizedVET,
        // 投票执行合约地址变更
        ExecutionContract,
        // 其他
        Other
    }

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

    // 选项个数
    struct numberOfChecked {
        uint8 min;
        uint8 max;
    }

    // 基本信息
    struct proposalInfo {
        string title;
        proposalType pType;
        numberOfChecked checked;
        address creator;
        uint64 createTime;
        uint64 cancelTime;
        string[] options;
        uint16[3] indentityRatio;
    }

    // 议题限制信息
    struct proposalCondition {
        // 投票生效限制
        uint64 votingStartTime;
        uint64 votingEndTime;
    }

    // 议题结果
    struct proposalResult {
        // voter => options
        mapping(address => uint32) voterOptions;

        // optionId => count
        uint64[] tally;
    }
    uint32 constant MAX_OPTIONS = 30;
    uint256 proposalId = 0;
    mapping(uint256 => proposalInfo) internal proposals;
    mapping(uint256 => proposalCondition) proposalConditions;
    mapping(uint256 => proposalResult) proposalResults;

    /// Events
    event NewProposal(uint256 indexed proposalId, proposalType indexed ptype, address indexed creator);
    event ProposalCanceled(uint256 indexed proposalId);

    event NewVote(uint256 indexed proposalId, address sender, address indexed endorser, uint256 indexed tokenId, uint32 options);

    modifier needProposalExist(uint256 _proposalId) {
        require(proposals[_proposalId].createTime > 0, "proposal not exist");
        _;
    }

    constructor (address _token_auction_address) public {
        tokenAuctionAddress = _token_auction_address;
    }

    /**
     * @dev 创建新议题
     * @param _title 标题
     * @param _proposalType 议题类型
     * @param _votingStartTime 投票开始时间
     * @param _votingEndTime 投票结束时间
     * @param _minChecked 投票选项最少选择数
     * @param _maxChecked 投票选项最大选择数
     * @param _options 选项描述数组
     * @param _ratio 各身份投票比率
     */
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
    returns(uint256) {
        require(_votingStartTime < _votingEndTime, "votingTime invalid");
        require(_options.length > 0 && _options.length <= MAX_OPTIONS, "options invalid");
        require(_minChecked <= _maxChecked && _maxChecked <= _options.length, "checked invalid");
        require(bytes(_options[0]).length > 0, "at least one option");
        proposalInfo memory pInfo = proposalInfo(
            _title,
            _proposalType,
            numberOfChecked(_minChecked, _maxChecked),
            msg.sender,
            uint64(now),
            0,
            _options,
            _ratio
        );
        proposalId++;
        proposals[proposalId] = pInfo;
        proposalConditions[proposalId] = proposalCondition(
            _votingStartTime,
            _votingEndTime
        );
        proposalResults[proposalId].tally = new uint64[](_options.length);
        emit NewProposal(proposalId, _proposalType, msg.sender);

        return proposalId;
    }

    /**
     * @dev 投票
     * @param _proposalId 议题ID
     * @param _options 投票选项
     * @param _master authority master node address
     */
    function cast(uint256 _proposalId, uint32 _options, address _master)
            public
            whenNotPaused
            needProposalExist(_proposalId)
    {
        proposalCondition memory p = proposalConditions[_proposalId];
        proposalInfo memory pInfo = proposals[_proposalId];

        require(msg.sender != address(0), "sender invalid");
        require(now >= p.votingStartTime && now <= p.votingEndTime, "not open voting");
        require(_options > 0 && _options < 2**MAX_OPTIONS, "invalid options");
        require(accessProposal(msg.sender, _master), "no authority");

        proposalResults[_proposalId].voterOptions[msg.sender] = _options;
        uint8 optionsCount = 0;
        for (uint i = 0; i < pInfo.options.length; i++) {
            if (_options & (2**i) > 0) {
                optionsCount++;
                proposalResults[_proposalId].tally[i]++;
            }
        }
        require(proposals[_proposalId].checked.min <= optionsCount && proposals[_proposalId].checked.max >= optionsCount,
                "options checked failed");

        emit NewVote(_proposalId, msg.sender, _master, ownerToId(msg.sender), _options);
    }

    /**
     * @dev 取消议题
     * @param _proposalId 议题 id
     */
    function cancelProposal(uint256 _proposalId)
            public
            whenNotPaused
            needProposalExist(_proposalId)
    {
        require(proposals[_proposalId].creator == msg.sender, "permission denied");
        proposals[_proposalId].cancelTime = uint64(now);
        emit ProposalCanceled(_proposalId);
    }

    /**
     * @dev 议题基本信息
     * @return 标题, 最小选择数，最大选择数，创建者，创建时间，取消时间，选项，各身份投票率
     * @param _proposalId 议题 id
     */
    function getBasicInfo(uint256 _proposalId)
        public
        view
        returns(string memory title, proposalType pType, uint8 minChecked, uint8 maxChecked, address creator, uint64 createTime, uint64 cancelTime, string[] memory options, uint16[3] memory _ratio) {
        proposalInfo memory p = proposals[_proposalId];
        return (
            p.title,
            p.pType,
            p.checked.min,
            p.checked.max,
            p.creator,
            p.createTime,
            p.cancelTime,
            p.options,
            p.indentityRatio
        );
    }

    /**
     * @dev 议题限制条件
     * @return 投票开始时间，投票结束时间
     * @param _proposalId 议题 id
     */
    function getCondition(uint256 _proposalId)
            public
            view
            returns(
                uint64 votingStartTime,
                uint64 votingEndTime) {
        proposalCondition memory p = proposalConditions[_proposalId];
        return (
            p.votingStartTime,
            p.votingEndTime
        );
    }

    /**
     * @dev 检查目标有无投票权限
     * @param _target 投票地址
     * @param _master AM节点地址
     */
    function accessProposal(address _target, address _master)
            public
            view
            returns (bool isAccess) {
        // whether thor node
        if (isToken(_target)) {
            return true;
        }

        bool listed = false;
        address endorsor;
        (listed, endorsor,,) = getMaster(_master);
        // master node and endorser equal to _target
        if (listed && _target == endorsor) {
            return true;
        }else {
            return false;
        }
    }

    /**
     * @dev 返回所投选项
     * @param _proposalId 议题 id
     * @param _voter 投票人
     */
    function getVoterOptions(uint256 _proposalId, address _voter)
            public
            view
            returns(uint32 option) {
        return proposalResults[_proposalId].voterOptions[_voter];
    }

    /**
     * @dev 返回选项投票结果
     * @param _proposalId 议题 id
     */
    function getTally(uint256 _proposalId)
            public
            view
            returns(uint64[] memory tally) {
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
