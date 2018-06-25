pragma solidity^0.4.20;
/*
    Company: Atra Blockchain Services LLC
    Website: atra.io
    Author: Dillon Vincent
    Title: Address Delegate Service (ADS)
    Documentation: atra.readthedocs.io
    Date: 4/4/18
*/
interface IAtraNetworkManager {
    function Create(string _name, address _currentAddress, string _currentAbiLocation) external returns(uint newNetworkId);

    function ScheduleUpdate(uint _id, string _name, uint _release, address _addr, string _abiUrl) external returns(bool success);

    function Get(uint _id, string _name) public view returns(string name, address addr, string abiUrl, uint released, uint version, uint update, address updateAddr, string updateAbiUrl, uint active, uint created);

    function GetAddress(uint _id, string _name) external view returns(address addr);

    function GetAddressAndAbi(uint _id, string _name) external view returns(address addr, string abiUrl);

    function NetworksLength() external view returns(uint length);

    function NameTaken(string _name) external view returns(bool taken);
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
}

contract AtraNetworkManager is IAtraNetworkManager, AtraOwners {
    using SafeMath for uint;

    struct NetworkData {
        string abiLocation; // url pointing to the abi json
        address contractAddress; // address pointing to an ethereum contract
    }

    struct Network {
        string name; //this will never change, used as a key
        uint updateRelease; // the epoch time when the updated contract data is released
        NetworkData current; // current contract data
        NetworkData update; // scheduled update contract data
        uint created; //time created
        uint version; // auto increment
        uint released; //when the last release was
    }

    // Declare Storage
    Network[] public Networks;
    mapping(bytes32 => uint) public NetworkNamesToNetworks; // (keccak256('Network Name') => networkId)

    //Events
    event NetworkCreated(string name, address owner);
    event UpdateScheduled(string name, address owner);

    //Constructor
    constructor() public {
        // Create padding in Networks array to be able to check for unique name in list by returning 0 for no match
        _Create('',address(this),'');
    }

    function Get(uint _id, string _name) public view returns(
            string name,
            address addr,
            string abiUrl,
            uint released,
            uint version,
            uint update,
            address updateAddr,
            string updateAbiUrl,
            uint active,
            uint created
        ) {
        Network memory network;
        if(bytes(_name).length > 0){
            network = Networks[NetworkNamesToNetworks[keccak256(_name)]];
        }else{
            network = Networks[_id];
        }
        return (
            network.name, //name
            network.current.contractAddress, //addr
            network.current.abiLocation, //abi
            // if update is active the released date is when it went live, else it's the release date
            network.updateRelease < now ? network.updateRelease : network.released, //released
            //check is next contract is active, if so it's a different version add 1, else return normal version
            network.updateRelease < now ? network.version.add(1) : network.version, //version
            // active position  will be used to determine what address to use by the client 0=current 1=next
            network.updateRelease, //update
            network.update.contractAddress, //updateAddr
            network.update.abiLocation, //updateAbi
            network.updateRelease < now ? 1 : 0, //active
            network.created //created
            );
    }

    function GetAddress(uint _id, string _name) external view returns(address addr) {
      return _GetAddress(_id,_name);
    }
    function _GetAddress(uint _id, string _name) private view returns(address addr) {
      Network memory network;
      if(bytes(_name).length > 0){
          network = Networks[NetworkNamesToNetworks[keccak256(_name)]];
      }else{
          network = Networks[_id];
      }
      return network.updateRelease < now ? network.update.contractAddress : network.current.contractAddress;
    }

    function GetAddressAndAbi(uint _id, string _name) external view returns(address addr, string abiUrl) {
      Network memory network;
      if(bytes(_name).length > 0){
          network = Networks[NetworkNamesToNetworks[keccak256(_name)]];
      }else{
          network = Networks[_id];
      }
      return network.updateRelease < now ? (network.update.contractAddress, network.update.abiLocation) : (network.current.contractAddress, network.current.abiLocation);
    }

    function NetworksLength() external view returns(uint length){
        return Networks.length;
    }

    function NameTaken(string _name) external view returns(bool) {
        require(bytes(_name).length > 0 && bytes(_name).length <= 100);
        if(NetworkNamesToNetworks[keccak256(_name)] == 0){
            return false;//name is not taken
        }else{
            return true;
        }
    }
    function Create(string _name, address _addr, string _abiUrl) external isOwner returns(uint id) {
      // validate inputs
      require(bytes(_name).length > 0 && bytes(_name).length <= 100 && bytes(_abiUrl).length <= 256);
      return _Create(_name, _addr, _abiUrl);
    }
    function _Create(string _name, address _addr, string _abiUrl) private returns(uint id) {
        // ** Below is where the padding route object comes into play. ** //
        // ** A mapping will return 0 if there is a hit and the array index is 0 AND if there is nothing found ** //
        // ** To pervent this we add padding to the routes list by creating a blank record and requiring _name to have a length > 0 ** //
        // ** The state below now will only return 0 if there isn't a route found ** //
        require(NetworkNamesToNetworks[keccak256(_name)] == 0);
        uint networkId = Networks.push(Network(_name, now, NetworkData(_abiUrl, _addr), NetworkData(_abiUrl, _addr),now, 0, now)) -1;
        emit NetworkCreated(_name, msg.sender);
        return NetworkNamesToNetworks[keccak256(_name)] = networkId;
    }

    function ScheduleUpdate(uint _id, string _name, uint _release, address _addr, string _abiUrl) external isOwner returns(bool success) {
        //dont require name validation since we aren't storing it
        require(bytes(_abiUrl).length <= 256);
        Network storage network;
        if(bytes(_name).length > 0){
            network = Networks[NetworkNamesToNetworks[keccak256(_name)]];
        }else{
            network = Networks[_id];
        }

        //if Next Contract Data is active do not overwrite Next data, move it to Current and increment the version
        if(network.updateRelease < now){
            network.current = network.update;
            network.released = network.updateRelease;
            network.version = network.version.add(1);
        }

        network.updateRelease = now.add(_release);// if updateRelease is zero update will be live now
        network.update.contractAddress = _addr; // update next address
        network.update.abiLocation = _abiUrl; // update next abi location
        emit UpdateScheduled(network.name, msg.sender);
        return true; // return success
    }

}
