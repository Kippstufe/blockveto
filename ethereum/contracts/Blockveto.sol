pragma solidity ^0.4.17;

contract Blockveto {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint vetoCount; //how many vetos
        mapping(address => bool) vetos; //who vetod
        uint creationTime; //timestamp der erstellten Request
        bool vetoed;
    }

    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public investors;
    uint public investorsCount;
    uint public constant limit = 30000;
    uint public timeFrame;
    uint sumValue; //sumvalue that is requested during 24h

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
            vetoCount: 0,
            creationTime: now,
            vetoed: false
            });

        requests.push(newRequest);
    }

    function calculateSum() public returns (uint) {
        uint twentyFourHoursAgo = now - (86400);
        uint sum = 0;

        uint arrayLength = requests.length;
        for (uint i=0; i<arrayLength; i++) {
            if (requests[i].creationTime > twentyFourHoursAgo) {
                sum = sum + requests[i].value;
            }
        }
        return sum;
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(investors[msg.sender]);
        require(!request.vetos[msg.sender]);

        request.vetos[msg.sender] = true;
        request.vetoCount++;
    }

    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(request.vetoCount > (investorsCount / 2));
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
