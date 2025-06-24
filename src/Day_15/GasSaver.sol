// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GasSaver {
    error GasSaver_UnAuthorized();
    error GasSaver_ZeroValue();
    error GasSaver_ProposalDoesNotExist();
    error GasSaver_Voted();
    error GasSaver_UnEqualData();
    error GasSaver_ProposalExpired();
    error GasSaver_InvalidDuration();

    // ✅ Optimized struct: 2 storage slots instead of 6
    struct Proposal {
        bytes32 title;           // 32 bytes - exact slot fit
        address creator;         // 20 bytes } 
        uint64 deadline;         // 8 bytes  } Slot 1 (28 bytes used)
        uint32 _padding;         // 4 bytes  } (explicit padding for clarity)
        uint128 votesFor;        // 16 bytes } Slot 2
        uint128 votesAgainst;    // 16 bytes }
    }

    uint256 public proposalCount;
    address private immutable owner; // ✅ Immutable saves gas

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    event ProposalAdded(uint256 indexed proposalId, bytes32 indexed title, uint64 deadline);
    event Voted(address indexed voter, uint256 indexed proposalId, bool support);

    modifier onlyOwner() {
        if (msg.sender != owner) revert GasSaver_UnAuthorized();
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        if (_proposalId >= proposalCount) revert GasSaver_ProposalDoesNotExist();
        _;
    }

    modifier notExpired(uint256 _proposalId) {
        if (block.timestamp > proposals[_proposalId].deadline) revert GasSaver_ProposalExpired();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Create a new proposal with deadline
     * @param _title Title as bytes32 for gas efficiency
     * @param _duration Duration in seconds from now
     * @return proposalId The ID of the created proposal
     */
    function addProposal(bytes32 _title, uint256 _duration) public returns (uint256) {
        if (_title == bytes32(0)) revert GasSaver_ZeroValue();
        if (_duration == 0 || _duration > 365 days) revert GasSaver_InvalidDuration();

        uint256 proposalId = proposalCount;
        unchecked {
            ++proposalCount; // ✅ Unchecked increment saves gas
        }

        // ✅ Direct storage assignment - more gas efficient
        Proposal storage proposal = proposals[proposalId];
        proposal.title = _title;
        proposal.creator = msg.sender;
        proposal.deadline = uint64(block.timestamp + _duration);
        // votesFor and votesAgainst default to 0

        emit ProposalAdded(proposalId, _title, proposal.deadline);
        return proposalId;
    }

    /**
     * @dev Create proposal with string title (converts to bytes32)
     * @param _title String title (will be truncated to 32 bytes if longer)
     * @param _duration Duration in seconds from now
     */
    function addProposalString(string calldata _title, uint256 _duration) external returns (uint256) {
        bytes32 titleBytes32 = stringToBytes32(_title);
        return addProposal(titleBytes32, _duration);
    }

    /**
     * @dev Vote on a proposal
     * @param _proposalId ID of the proposal
     * @param support True for yes, false for no
     */
    function vote(uint256 _proposalId, bool support) 
        public 
        validProposalId(_proposalId) 
        notExpired(_proposalId) 
    {
        if (hasVoted[msg.sender][_proposalId]) revert GasSaver_Voted();
        _registerVote(_proposalId, msg.sender, support);
    }

    /**
     * @dev Vote on multiple proposals in one transaction
     * @param _proposalIds Array of proposal IDs
     * @param _support Array of vote choices
     */
    function bulkVote(uint256[] calldata _proposalIds, bool[] calldata _support) external {
        uint256 length = _proposalIds.length;
        if (_support.length != length) revert GasSaver_UnEqualData();
        
        // ✅ Unchecked loop for gas savings
        for (uint256 i; i < length;) {
            vote(_proposalIds[i], _support[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev Check if an address has voted on a proposal
     * @param _proposalId ID of the proposal
     * @param voter Address to check
     * @return True if voter has voted
     */
    function ifVoted(uint256 _proposalId, address voter) 
        external 
        view 
        validProposalId(_proposalId) 
        returns (bool) 
    {
        return hasVoted[voter][_proposalId];
    }

    /**
     * @dev Get proposal results
     * @param _proposalId ID of the proposal
     * @return title Proposal title
     * @return votesFor Number of yes votes
     * @return votesAgainst Number of no votes
     * @return totalVotes Total votes cast
     * @return deadline Proposal deadline
     * @return isActive Whether proposal is still active
     */
    function getProposalResult(uint256 _proposalId) 
        public 
        view 
        validProposalId(_proposalId) 
        returns (
            bytes32 title,
            uint128 votesFor,
            uint128 votesAgainst,
            uint256 totalVotes,
            uint64 deadline,
            bool isActive
        ) 
    {
        Proposal storage proposal = proposals[_proposalId]; // ✅ Use storage for gas efficiency
        return (
            proposal.title,
            proposal.votesFor,
            proposal.votesAgainst,
            uint256(proposal.votesFor) + uint256(proposal.votesAgainst), // ✅ Calculate total
            proposal.deadline,
            block.timestamp <= proposal.deadline
        );
    }

    /**
     * @dev Get proposal results as string title
     * @param _proposalId ID of the proposal
     */
    function getProposalResultString(uint256 _proposalId)
        external
        view
        validProposalId(_proposalId)
        returns (
            string memory title,
            uint128 votesFor,
            uint128 votesAgainst,
            uint256 totalVotes,
            uint64 deadline,
            bool isActive
        )
    {
        (bytes32 titleBytes, uint128 vFor, uint128 vAgainst, uint256 total, uint64 dl, bool active) = 
            getProposalResult(_proposalId);
        
        return (
            bytes32ToString(titleBytes),
            vFor,
            vAgainst,
            total,
            dl,
            active
        );
    }

    /**
     * @dev Get total votes for a proposal
     * @param _proposalId ID of the proposal
     * @return Total number of votes
     */
    function getTotalVotes(uint256 _proposalId) external view validProposalId(_proposalId) returns (uint256) {
        Proposal storage proposal = proposals[_proposalId];
        return uint256(proposal.votesFor) + uint256(proposal.votesAgainst);
    }

    /**
     * @dev Get all active proposals
     * @return activeProposals Array of active proposal IDs
     */
    function getActiveProposals() external view returns (uint256[] memory activeProposals) {
        uint256 activeCount;
        uint256 currentTime = block.timestamp;
        
        // ✅ First pass: count active proposals
        for (uint256 i; i < proposalCount;) {
            if (currentTime <= proposals[i].deadline) {
                unchecked { ++activeCount; }
            }
            unchecked { ++i; }
        }
        
        // ✅ Allocate exact size array
        activeProposals = new uint256[](activeCount);
        uint256 index;
        
        // ✅ Second pass: populate array
        for (uint256 i; i < proposalCount;) {
            if (currentTime <= proposals[i].deadline) {
                activeProposals[index] = i;
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
    }

    /**
     * @dev Get proposals by creator
     * @param _creator Address of the creator
     * @return creatorProposals Array of proposal IDs created by the address
     */
    function getProposalsByCreator(address _creator) external view returns (uint256[] memory creatorProposals) {
        uint256 count;
        
        // ✅ First pass: count creator's proposals
        for (uint256 i; i < proposalCount;) {
            if (proposals[i].creator == _creator) {
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }
        
        // ✅ Allocate exact size array
        creatorProposals = new uint256[](count);
        uint256 index;
        
        // ✅ Second pass: populate array
        for (uint256 i; i < proposalCount;) {
            if (proposals[i].creator == _creator) {
                creatorProposals[index] = i;
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
    }

    /**
     * @dev Check if proposal has expired
     * @param _proposalId ID of the proposal
     * @return True if expired
     */
    function isExpired(uint256 _proposalId) external view validProposalId(_proposalId) returns (bool) {
        return block.timestamp > proposals[_proposalId].deadline;
    }

    // ===================
    // HELPER FUNCTIONS
    // ===================

    /**
     * @dev Register a vote internally
     * @param _proposalId ID of the proposal
     * @param _voter Address of the voter
     * @param support Vote choice
     */
    function _registerVote(uint256 _proposalId, address _voter, bool support) internal {
        Proposal storage proposal = proposals[_proposalId];
        
        if (support) {
            unchecked { ++proposal.votesFor; } // ✅ Unchecked increment
        } else {
            unchecked { ++proposal.votesAgainst; }
        }
        
        hasVoted[_voter][_proposalId] = true;
        emit Voted(_voter, _proposalId, support);
    }

    /**
     * @dev Convert string to bytes32
     * @param source String to convert
     * @return result bytes32 representation
     */
    function stringToBytes32(string calldata source) public pure returns (bytes32 result) {
        bytes memory temp = bytes(source);
        if (temp.length == 0) return 0x0;
        
        assembly {
            result := mload(add(temp, 32))
        }
    }

    /**
     * @dev Convert bytes32 to string
     * @param _bytes32 bytes32 to convert
     * @return String representation
     */
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            unchecked { ++i; }
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0;) {
            bytesArray[i] = _bytes32[i];
            unchecked { ++i; }
        }
        return string(bytesArray);
    }
}