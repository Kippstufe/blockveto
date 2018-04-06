pragma solidity ^0.4.17;

contract Blockveto {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint vetoCount; //how many vetos
        mapping(address => bool) vetos; //who vetod
    }

    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public investors;
    uint public investorsCount;
    uint public constant limit;
    uint public timeFrame;
    uint sumValue; //sumvalue that is requested during 24h
    string public statusOfRequest;
    uint public creationTime; //timestamp der erstellten Request

    limit = 30000;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function Blockveto(uint minimum, address creator) public {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);

        investors[msg.sender] = true;
        investorsCount++;
    }

    function createRequest(string description, uint value, address recipient) public restricted {
        Request memory newRequest = Request({
           description: description,
           value: value,
           recipient: recipient,
           complete: false,
           approvalCount: 0
        });

        requests.push(newRequest);
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(investors[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (investorsCount / 2));
        require(!request.complete);

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns (
      uint, uint, uint, uint, address
      ) {
        return (
          minimumContribution,
          this.balance,
          requests.length,
          investorsCount,
          manager
        );
    }

    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }
}
