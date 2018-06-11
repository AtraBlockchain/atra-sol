pragma solidity ^0.4.20;
interface IADS {
  function GetAddress(uint _id, string _name) public view returns(address addr);
  function ScheduleUpdateForRoute(bytes32 _nameHash, uint _release, address _addr) public returns(bool);
}
interface IADS_Client {
  function Update() public returns(bool);
}
interface IPricing {
  function Credits(address _sender) external view returns(uint amount);

  function Price(uint _option) external view returns(uint price);

  function Charge(address _sender, uint _option) external returns(uint cost);

  function SetPriceForOption(uint _option, uint _amount) external returns(bool success);

  function AddCredits(address _user, uint _credits) external returns(bool success);
}
contract AtraOwners {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address from, address to);

    constructor() public {
        owner = msg.sender;
    }

    modifier isOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public isOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
contract ADS_Pricing is AtraOwners {
    using SafeMath for uint;

    mapping(address => uint) public credits;
    mapping(uint => uint) public prices;
    address ads_address;

    constructor(address _ads_address) public {
        credits[msg.sender] = 2;
        ads_address = _ads_address;
    }

    function Credits(address _sender) external view returns(uint amount) {
        return credits[_sender];
    }

    function Price(uint _option) external view returns(uint price) {
        return 0;
    }

    function Charge(address _sender, uint _option) external returns(uint cost) {
        //require the sender to only be the ADS contract.
        IADS ADS = IADS(ads_address);
        require(msg.sender == ADS.GetAddress(0, 'atra.ads'));
        // use credits first
        if(credits[_sender] > 0){
          // subtract credits and return zero for the price to charge
            credits[_sender] = credits[_sender].sub(1);
            return 0;
        }

        return prices[_option];
    }

    function SetPriceForOption(uint _option, uint _amount) external isOwner returns(bool success) {
        prices[_option] = _amount;
        return true;
    }

    function AddCredits(address _user, uint _credits) external isOwner returns(bool success) {
        credits[_user] = credits[_user].add(_credits);
        return true;
    }
}
