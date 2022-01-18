pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) balances; // The amount that each address has staked.
    uint256 public constant threshold = 1 ether;
    uint256 public immutable deadline = block.timestamp + 45 seconds;
    bool private openForWithdraw = false;
    event Stake(address _sender, uint256 _amount);

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    modifier beforeDeadline() {
        require(block.timestamp <= deadline, "Deadline has reached");
        _;
    }

    modifier afterDeadline() {
        require(block.timestamp > deadline, "Deadline not reached");
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() external payable beforeDeadline {
        require(msg.value > 0, "Stake value cannot be zero");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() external afterDeadline {
        if (address(this).balance > threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    // Add a `withdraw(address payable)` function lets users withdraw their balance
    function withdraw(address payable to) external payable afterDeadline {
        require(openForWithdraw == true, "Withdrawing is not allowed yet");
        require(balances[to] > 0, "Address must have staked some value");

        // Setting balances to 0 to prevent re-entrancy attacks.
        // https://quantstamp.com/blog/what-is-a-re-entrancy-attack
        uint256 transferValue = balances[to];
        balances[to] = 0;
        to.transfer(transferValue);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        return deadline >= block.timestamp ? deadline - block.timestamp : 0;
    }

    // Add the `receive()` special function that receives eth and calls stake()
}
