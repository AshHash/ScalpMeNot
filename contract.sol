// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.7.0;

contract ScalpMeNot {

    struct Bid {
        uint deposit;
        bytes32 blindedBid;
    }

    // Address payment goes to
    address payable public vendor;
    // When the bidding ends
    uint public biddingEnd;
    // When revealing bids ends
    uint public revealEnd;
    bool public ended;
    uint public totalWinners = 10;

    // Defines bids with key type address and value type Bid[].
    mapping(address => Bid[]) public bids;

    // Store highest bid info
    address[] public highestBidders;
    uint [] public highestBids;
    mapping(address => uint) highestBidsMap;
    address public lowestHighBidder;
    uint public lowestHighBid;

    // Defines pendingReturns with key of address and value of uint
    mapping(address => uint) pendingReturns;

    // Accepts payment from highest bidders. We want to allow for a variable amount of winners.
    event AuctionEnded(address winner, uint highestBid);

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
        vendor = _vendor;
        // Sets bidding end and reveal end time based on preset values.
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
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
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
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
        // Checks all of senders bids
        uint length = bids[msg.sender].length;
        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) = (_values[i], _fake[i], _secret[i]);
            if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
                // Sent something different. No refund, not actually revealed.
                continue;
            }
            refund += bidToCheck.deposit;
            // If the deposit is higher than value, adjust refund accordingly.
            if (!fake && bidToCheck.deposit >= value) {
                if ( placeBid( msg.sender, value ))
                    refund -= value;
            }
            // Overwrites bid to 0 so that deposit cannot be reclaimed more than once.
            bidToCheck.blindedBid = bytes32(0);
        }
        msg.sender.transfer(refund);
    }

    // This is an "internal" function which means that it
    // can only be called from the contract itself (or from
    // derived contracts).
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        // If no bids have been placed, the first is the highest.
        if (highestBidders.length == 0) {
            highestBidders.push(bidder);
            lowestHighBid = value;
            lowestHighBidder = bidder;
            highestBidsMap[bidder] = value;
        }
        // If there are less bids than total amount of possible winners, we accept more and adjust the lowest high bid.
        if (highestBidders.length < totalWinners) {
            highestBidders.push(bidder);
            if ( value < lowestHighBid ) {
                lowestHighBid = value;
                lowestHighBidder = bidder;
            }
            highestBidsMap[bidder] = value;
        }
        // If there are already enough potential winners, we replace the lowest of the high bids, and refund that bidder.
        if (highestBidders.length == totalWinners) {
            if ( value > lowestHighBid ) {
                lowestHighBid = value;
                for (uint i = 0; i < totalWinners; i++) {
                    if (highestBidders[i] == lowestHighBidder) {
                        pendingReturns[highestBidders[i]] += highestBidsMap[highestBidders[i]];
                        highestBidders[i] = bidder;
                    }
                    if (highestBidsMap[highestBidders[i]] < lowestHighBid) {
                        lowestHighBid = highestBidsMap[highestBidders[i]];
                    } 
                }
            }
        }
        // If the new bid is lower than the lowest of the top X bids, we don't accept it.
        if (value <= lowestHighBid) {
            return false;
        }
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // Set their pending returns to 0, and then send the previous amount.
            pendingReturns[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
        
    }

    /// End the auction and send the highest bids
    /// to the vendor
    function auctionEnd()
        public
        onlyAfter(revealEnd)
    {
        require(!ended);
        for (uint i = 0; i < totalWinners; i++) {
            emit AuctionEnded(highestBidders[i], highestBidsMap[highestBidders[i]]);
            vendor.transfer(highestBidsMap[highestBidders[i]]);
        }
        ended = true;
    }
}
