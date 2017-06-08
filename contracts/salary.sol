pragma solidity ^0.4.11;

contract Owned {
    address public owner;
    function Owned(){
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Pausable is Owned {
    bool public paused;    
    function togglePaused() onlyOwner returns (bool) {
        if(paused == true){
            paused = false;
        }
        else {
            paused = true;
        }
        return paused;
    }

    modifier notPaused() {
        require(paused == false);
        _;
    }
}

contract SalarySplitAgreement is Owned, Pausable {
    event SalaryProposed(address indexed employee, uint proposalBlockNumber);
    event SalaryAgreeded(address indexed employee, uint agreementBlockNumber);
    event SalaryPayed(address indexed employee, uint agreementBlockNumber, uint usdAmountPayable);
    event SalaryFinished(address indexed employee, uint agreementBlockNumber);
    struct SalaryAgreement {
        uint etherDailySalary;
        uint dollarDailySalary;
        uint antDailySalary;
        uint block;
        bool ended;
        bool active;
        uint lastPaid;
    }
    struct SalaryProposal {
        uint etherDailySalary;
        uint dollarDailySalary;
        uint antDailySalary;
        uint block;
    }
    address public antToken;
    mapping (address => SalaryAgreement) public agreements;
    mapping (address => SalaryProposal) public proposals;
    // @constructor
    function SalarySplitAgreement(address _antToken){
        antToken = _antToken;
        // msg.sender is the company
    }

    function proposeSalary(
        address _employee,
        uint _etherDailySalary,
        uint _dollarDailySalary,
        uint _antDailySalary
    ) onlyOwner returns (bool) {
        SalaryProposal memory proposal = SalaryProposal({
            etherDailySalary: _etherDailySalary,
            dollarDailySalary: _dollarDailySalary,
            antDailySalary: _antDailySalary,
            block: block.number
        });
        proposals[_employee] = proposal;
        SalaryProposed(_employee, block.number);
        return true;
    }

    function acceptSalary(uint _proposalBlockNumber) notPaused returns (bool) {
        SalaryProposal proposal = proposals[msg.sender];
        if(proposal.block == _proposalBlockNumber){
            SalaryAgreement memory agreement = SalaryAgreement({
                etherDailySalary: proposal.etherDailySalary,
                dollarDailySalary: proposal.dollarDailySalary,
                antDailySalary: proposal.antDailySalary,
                block: block.number,
                ended: false,
                active: true,
                lastPaid: block.timestamp
            });
            agreements[msg.sender] = agreement;
            SalaryAgreeded(msg.sender, block.number);
            return true;
        }
        else {
            return false;
        }
    }

    function terminateContract(address _employee, uint _agreementBlockNumber) onlyOwner returns (bool) {
        if(agreements[_employee].block == _agreementBlockNumber){
            agreements[_employee].ended = true;
        }
        else {
            return false;
        }
    }

    function quit(uint _agreementBlockNumber) notPaused returns (bool) {
        if(agreements[msg.sender].block == _agreementBlockNumber){
            agreements[msg.sender].ended = true;
        }
        else {
            return false;
        }
    }
    function balancePayableANT(address _employee) constant returns (uint) {
        SalaryAgreement agreement = agreements[_employee];
        if(agreement.active == false){
            return 0;
        }
        uint payablePeriod = block.timestamp - agreement.lastPaid;
        uint payableDays = payablePeriod / 1 days; // will truncate
        uint payableAmount = payableDays * agreement.antDailySalary;
        return payableAmount;
    }
    function balancePayableETH(address _employee) constant returns (uint) {
        SalaryAgreement agreement = agreements[_employee];
        if(agreement.active == false){
            return 0;
        }
        uint payablePeriod = block.timestamp - agreement.lastPaid;
        uint payableDays = payablePeriod / 1 days; // will truncate
        uint payableAmount = payableDays * agreement.etherDailySalary;
        return payableAmount;
    }
    function balancePayableUSD(address _employee) constant returns (uint) {
        SalaryAgreement agreement = agreements[_employee];
        if(agreement.active == false){
            return 0;
        }
        uint payablePeriod = block.timestamp - agreement.lastPaid;
        uint payableDays = payablePeriod / 1 days; // will truncate
        uint payableAmount = payableDays * agreement.dollarDailySalary;
        return payableAmount;
    }
    function triggerPayment(address _employee) onlyOwner returns (bool) {
        SalaryAgreement agreement = agreements[_employee];
        if(agreement.active == false){
            return false;
        }

        uint amountPayableANT = balancePayableANT(_employee);
        uint amountPayableETH = balancePayableETH(_employee);
        uint amountPayableUSD = balancePayableUSD(_employee);

        TransferableERCToken antTokenContract = TransferableERCToken(antToken);
        //make sure eth and ant balances are sufficent
        if(antTokenContract.balanceOf(address(this)) >= amountPayableANT && address(this).balance >= amountPayableETH){
            //transfer ant
            antTokenContract.transfer(_employee, amountPayableANT);
            //transfer eth
            _employee.transfer(amountPayableETH);

            agreements[_employee].lastPaid = block.timestamp;
            //record the amount payable in USD in the event log
            SalaryPayed(_employee, agreement.block, amountPayableUSD);

            if(agreement.ended){
                agreements[_employee].active = false;
                SalaryFinished(_employee, agreement.block);
            }
            return true;
        }
        else {
            return false;
        }
    }

    function () payable { // accepts Ethereum directly
    }

}

contract TransferableERCToken {
   function transferFrom(address _from, address _to, uint _amount);
   function balanceOf(address _account) constant public returns(uint);
   function transfer(address _to, uint256 _amount) returns (bool);
   function approve(address _for, uint _amount) returns (bool);
   function allowance(address _owner, address _spender) constant returns (uint256);
}