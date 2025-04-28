// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; //to interact with stablecoins like cUSD tokens properly

// Minimal IERC20 interface to interact with cUSD token
// interface IERC20 {
//     function transferFrom(address sender, address recipient, uint amount) external returns (bool);
// }

contract Splitzy {

    // Address of the cUSD token contract on Celo Mainnet or Alfajores Testnet
    address public cUSDTokenAddress;

    uint public groupCount;
    uint public billCount;

    constructor(address _cUSDTokenAddress) {
        cUSDTokenAddress = _cUSDTokenAddress;
    }

    // Struct for a group
    struct Group {
        uint id;
        string name;
        address[] members;
    }

    // Struct for a bill
    struct Bill {
        uint id;
        uint groupId;
        string title;
        uint totalAmount;
        address creator;
        address[] payees;
        mapping(address => uint) amountOwed;
        mapping(address => bool) hasPaid;
        bool isSettled;
    }

    mapping(uint => Group) public groups; // groupId => Group
    mapping(uint => Bill) public bills;   // billId => Bill

    // Mapping to keep track of user's bills
    mapping(address => uint[]) public userBills;

    // EVENTS (optional for frontend to track)
    event GroupCreated(uint groupId, string name, address creator);
    event BillCreated(uint billId, uint groupId, string title, uint totalAmount);
    event BillPaid(uint billId, address payer, uint amount);

    // ===== Core Functions ===== //

    // Create a group
    function createGroup(string memory _name, address[] memory _members) external {
        groupCount++;
        groups[groupCount] = Group(groupCount, _name, _members);

        emit GroupCreated(groupCount, _name, msg.sender);
    }

    // Create a bill inside a group
    function createBill(
        uint _groupId,
        string memory _title,
        uint _totalAmount,
        address[] memory _payees,
        uint[] memory _amounts
    ) external {
        require(groups[_groupId].id != 0, "Group does not exist.");
        require(_payees.length == _amounts.length, "Payees and amounts length mismatch.");

        billCount++;
        Bill storage bill = bills[billCount];
        bill.id = billCount;
        bill.groupId = _groupId;
        bill.title = _title;
        bill.totalAmount = _totalAmount;
        bill.creator = msg.sender;
        bill.payees = _payees;

        uint totalSplitAmount = 0;
        for (uint i = 0; i < _payees.length; i++) {
            bill.amountOwed[_payees[i]] = _amounts[i];
            bill.hasPaid[_payees[i]] = false;
            totalSplitAmount += _amounts[i];

            // Track each user's bills
            userBills[_payees[i]].push(billCount);
        }

        require(totalSplitAmount == _totalAmount, "Split amounts do not match total.");

        emit BillCreated(billCount, _groupId, _title, _totalAmount);
    }

    // Pay a bill
    function payBill(uint _billId) external {
        Bill storage bill = bills[_billId];
        require(bill.id != 0, "Bill does not exist.");
        require(bill.amountOwed[msg.sender] > 0, "You don't owe anything.");
        require(!bill.hasPaid[msg.sender], "Already paid.");

        uint amountToPay = bill.amountOwed[msg.sender];

        // Transfer cUSD from user to bill creator
        IERC20(cUSDTokenAddress).transferFrom(msg.sender, bill.creator, amountToPay);

        bill.hasPaid[msg.sender] = true;

        emit BillPaid(_billId, msg.sender, amountToPay);

        // Check if all participants have paid
        bool allPaid = true;
        for (uint i = 0; i < bill.payees.length; i++) {
            if (!bill.hasPaid[bill.payees[i]]) {
                allPaid = false;
                break;
            }
        }
        bill.isSettled = allPaid;
    }

    // Get a user's active bills
    function getMyBills() external view returns (uint[] memory) {
        return userBills[msg.sender];
    }

    // Check how much a user still owes on a bill
    function checkMyAmount(uint _billId) external view returns (uint amount, bool hasPaid) {
        Bill storage bill = bills[_billId];
        amount = bill.amountOwed[msg.sender];
        hasPaid = bill.hasPaid[msg.sender];
    }

    // Fetch basic group details
    function getGroup(uint _groupId) external view returns (string memory name, address[] memory members) {
        Group storage group = groups[_groupId];
        return (group.name, group.members);
    }
}
