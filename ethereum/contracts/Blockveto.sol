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
    mapping(address => bool) public investors;
    uint public investorsCount;
    uint public constant limit = 30000;
    uint public timeFrame;
    uint sumValue; //sumvalue that is requested during 24h
    mapping(address => uint) public investments;
    mapping(address => uint) public stakeOfInvestors;
    address[] public investorsAddress;
    uint public stake;
    uint public sumInvestments;
    uint public indexOfInvestor;
    uint public approvePercentage;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function Blockveto(address creator) public {
        manager = creator;
    }

    function contribute() public payable returns (uint) {
        //investor sents money to the contract
        investments[msg.sender] = msg.value;
        investorsAddress.push(msg.sender);
        sumInvestments = msg.value + sumInvestments;
        investors[msg.sender] = true;
        investorsCount++;
    }
    
    function createRequest(string description, uint value, address recipient) public restricted {
        if (value > limit) {
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
            approvePercentage = 100;
            uint arrayLength = investorsAddress.length;
            for (uint i=0; i<arrayLength; i++) {
                calculateStake(investorsAddress[i]); 
            }
        } else {
            Request memory transferRequest = Request({
                description: description,
                value: value,
                recipient: recipient,
                complete: false,
                vetoCount: 0,
                creationTime: now,
                vetoed: false
                });
                approvePercentage =100;
        }
            requests.push(transferRequest);
        
    }

    function calculateSum() public view returns (uint) {
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
    
    function calculateStake(address investor) {
        stakeOfInvestors[investor] = investments[investor] * 100 / this.balance;
        
    }

    function vetoRequest(uint index) public {
        //stake variable
        Request storage request = requests[index];

        require(investors[msg.sender]);
        //require(!request.vetos[msg.sender]);
        //msg.value *100 / this.balance 
        // stake into mapping with address
        request.vetos[msg.sender] = true;
        approvePercentage = approvePercentage - stakeOfInvestors[msg.sender];
        request.vetoCount++;
    }

    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];
        timeFrame = requests[index].creationTime;
        uint twentyFourHoursAgo = now - (86400);
        require(timeFrame < twentyFourHoursAgo);
        //require vetoed == false
        //gewichtete Mehrheit checken
        require(approvePercentage > 50);
        require(!request.complete);
        
        //vetoed == true
        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns (
        uint, uint, uint, address
    ) {
        return (
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
