// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.2/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";
import "@openzeppelin/contracts@5.0.2/utils/ReentrancyGuard.sol";

contract TixkenTickets is ERC721, Ownable, ReentrancyGuard {
    enum ReclaimMode { Burn, Credit }

    struct EventInfo {
        string name;
        uint256 maxTickets;
        uint256 minted;
        uint64 endsAt;
        ReclaimMode mode;
        uint256 faceValue;
        uint16 capPercent;
        bool exists;
    }

    uint256 public eventCount;
    uint256 private _nextTicketId = 1;
    address public agent;
    bool private _inSale;

    mapping(uint256 => EventInfo) public eventInfo;
    mapping(uint256 => uint256) public ticketEvent;
    mapping(uint256 => uint256) public listingPrice;
    mapping(address => uint256) public attended;
    mapping(address => uint256) public credits;

    event EventCreated(uint256 indexed eventId, string name, uint64 endsAt, ReclaimMode mode);
    event TicketMinted(uint256 indexed ticketId, uint256 indexed eventId, address indexed to);
    event TicketScanned(uint256 indexed ticketId, address indexed holder);
    event TicketListed(uint256 indexed ticketId, uint256 price);
    event TicketSold(uint256 indexed ticketId, address indexed from, address indexed to, uint256 price);
    event TicketReclaimed(uint256 indexed ticketId, address indexed holder, ReclaimMode mode);
    event AgentSet(address indexed agent);

    constructor() ERC721("Tixken Ticket", "TIXK") Ownable(msg.sender) {}

    function setAgent(address newAgent) external onlyOwner {
        agent = newAgent;
        emit AgentSet(newAgent);
    }

    function createEvent(
        string calldata eventName,
        uint256 maxTickets,
        uint64 endsAt,
        ReclaimMode mode,
        uint256 faceValue,
        uint16 capPercent
    ) external onlyOwner returns (uint256 eventId) {
        require(maxTickets > 0, "maxTickets is zero");
        require(faceValue > 0, "faceValue is zero");
        require(endsAt > block.timestamp, "endsAt must be in the future");
        eventId = ++eventCount;
        eventInfo[eventId] = EventInfo(eventName, maxTickets, 0, endsAt, mode, faceValue, capPercent, true);
        emit EventCreated(eventId, eventName, endsAt, mode);
    }

    function mintTicket(uint256 eventId, address to) external onlyOwner returns (uint256) {
        return _issue(eventId, to);
    }

    function redeemCredit(uint256 eventId) external returns (uint256) {
        require(credits[msg.sender] > 0, "no credits");
        credits[msg.sender] -= 1;
        return _issue(eventId, msg.sender);
    }

    function scan(uint256 ticketId) external {
        address holder = ownerOf(ticketId);
        require(msg.sender == holder || msg.sender == owner(), "not holder or organizer");
        require(block.timestamp < eventInfo[ticketEvent[ticketId]].endsAt, "event ended");
        delete listingPrice[ticketId];
        attended[holder] += 1;
        _burn(ticketId);
        emit TicketScanned(ticketId, holder);
    }

    function maxResalePrice(uint256 ticketId) public view returns (uint256) {
        EventInfo storage e = eventInfo[ticketEvent[ticketId]];
        return e.faceValue + (e.faceValue * e.capPercent) / 100;
    }

    function listForResale(uint256 ticketId, uint256 price) external {
        require(ownerOf(ticketId) == msg.sender, "not the holder");
        require(price > 0, "price is zero");
        require(price <= maxResalePrice(ticketId), "price above resale cap");
        listingPrice[ticketId] = price;
        emit TicketListed(ticketId, price);
    }

    function cancelListing(uint256 ticketId) external {
        require(ownerOf(ticketId) == msg.sender, "not the holder");
        delete listingPrice[ticketId];
    }

    function buy(uint256 ticketId) external payable nonReentrant {
        uint256 price = listingPrice[ticketId];
        require(price > 0, "not listed");
        require(msg.value == price, "send the exact price");
        address seller = ownerOf(ticketId);
        require(seller != msg.sender, "cannot buy your own ticket");
        require(block.timestamp < eventInfo[ticketEvent[ticketId]].endsAt, "event ended");
        delete listingPrice[ticketId];
        _inSale = true;
        _transfer(seller, msg.sender, ticketId);
        _inSale = false;
        (bool ok, ) = payable(seller).call{value: price}("");
        require(ok, "payment to seller failed");
        emit TicketSold(ticketId, seller, msg.sender, price);
    }

    // The agent can only touch tickets that were never scanned (scanned ones
    // are already burned) and only after the event has ended.
    function reclaim(uint256 ticketId) external {
        require(msg.sender == agent, "only the agent");
        address holder = ownerOf(ticketId);
        EventInfo storage e = eventInfo[ticketEvent[ticketId]];
        require(block.timestamp >= e.endsAt, "event not over");
        delete listingPrice[ticketId];
        if (e.mode == ReclaimMode.Credit) {
            credits[holder] += 1;
        }
        _burn(ticketId);
        emit TicketReclaimed(ticketId, holder, e.mode);
    }

    function _issue(uint256 eventId, address to) internal returns (uint256 ticketId) {
        EventInfo storage e = eventInfo[eventId];
        require(e.exists, "unknown event");
        require(block.timestamp < e.endsAt, "event ended");
        require(e.minted < e.maxTickets, "sold out");
        e.minted += 1;
        ticketId = _nextTicketId++;
        ticketEvent[ticketId] = eventId;
        _mint(to, ticketId);
        emit TicketMinted(ticketId, eventId, to);
    }

    // Direct transfers are blocked so the resale cap cannot be bypassed.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            require(_inSale, "transfers only through buy");
        }
        return super._update(to, tokenId, auth);
    }
}
