pragma solidity >=0.4.0 <0.7.0;

contract ScalpMeNot {

    struct Bid {
        uint deposit;
        bytes32 secret;
    }

    // Address payment goes to
    address payable public vendor;
    // When the bidding ends
    uint public biddingEnd;
    // When revealing bids ends
    uint public revealEnd;
    bool public ended;

    // Defines bids with key type address and value type Bid[].
    mapping(address => Bid[]) public bids;

    // Store highest bid info
    address public highestBidder;
    uint public highestBid;

    // Defines pendingReturns with key of address and value of uint
    mapping(address => uint) pendingReturns;

    // Accepts payment from highest bidders. We want to allow for a variable amount of winners,
    // but each address can only win once. Set to array for now but might handle differently later.
    event AuctionEnded(address Winners[], uint HighestBids[]);

    /// Modifiers are a convenient way to validate inputs to
    /// functions. `onlyBefore` is applied to `bid` below:
    /// The new function body is the modifier's body where
    /// `_` is replaced by the old function body.
    modifier onlyBefore(uint _time) { require(now < _time); _; }
    modifier onlyAfter(uint _time) { require(now > _time); _; }

    constructor(
        uint _biddingTime,
        uint _revealTime,
        address payable _vendor
    ) public {
        
    }

    /// Place a blinded bid with `_blindedBid` =
    /// keccak256(abi.encodePacked(value, fake, secret)).
    /// The sent ether is only refunded if the bid is correctly
    /// revealed in the revealing phase. The bid is valid if the
    /// ether sent together with the bid is at least "value" and
    /// "fake" is not true. Setting "fake" to true and sending
    /// not the exact amount are ways to hide the real bid but
    /// still make the required deposit. The same address can
    /// place multiple bids.
    function bid(bytes32 _blindedBid)
        public
        payable
        onlyBefore(biddingEnd)
    {

    }

    /// Reveal your blinded bids. You will get a refund for all
    /// correctly blinded invalid bids and for all bids except for
    /// the totally highest.
    function reveal(
        uint[] memory _values,
        bool[] memory _fake,
        bytes32[] memory _secret
    )
        public
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        
    }

    // This is an "internal" function which means that it
    // can only be called from the contract itself (or from
    // derived contracts).
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        
    }

    /// End the auction and send the highest bids
    /// to the vendor
    function auctionEnd()
        public
        onlyAfter(revealEnd)
    {
        
    }
}