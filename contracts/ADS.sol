pragma solidity^0.4.20;
/*
    Company: Atra Blockchain Services LLC
    Website: atra.io
    Author: Dillon Vincent
    Title: Address Delegate Service (ADS)
    Documentation: atra.readthedocs.io
    Date: 4/4/18
*/
interface IADS {
    function Create(string name, address currentAddress) external payable returns(uint newRouteId);

    function ScheduleUpdate(uint _id, string _name, uint _release, address _addr) external payable returns(bool success);

    function Get(uint _id, string _name) public view returns(string name, address addr, uint released, uint version, uint update, address updateAddr, uint active, address owner, uint created);

    function GetRouteIdsForOwner(address _owner) external view returns(uint[] routeIds);

    function GetAddress(uint _id, string _name) external view returns(address addr);

    function RoutesLength() external view returns(uint length);

    function NameTaken(string _name) external view returns(bool taken);

    function GetPendingRouteTransfer(uint _id, string _name) external view returns(address addr);

    function GetPendingTransfersForSender() external view returns(uint[] routeIds);

    function TransferRouteOwnership(uint _id, string _name, address _owner) external payable returns(bool success);

    function AcceptRouteOwnership(uint _id, string _name) external payable returns(bool success);
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

contract ADS is IADS, AtraOwners {
    using SafeMath for uint;

    struct RouteData {
        address contractAddress; // address pointing to an ethereum contract
    }

    struct Route {
        string name; //this will never change, used as a key
        uint updateRelease; // the epoch time when the updated contract data is released
        address owner; // address that owns/created and can modify route
        address newOwner; // used to transfer ownership
        RouteData current; // current contract data
        RouteData update; // scheduled update contract data
        uint created; //time created
        uint version; // auto increment
        uint released; //when the last release was
    }

    // Declare Storage
    Route[] public Routes;
    mapping(bytes32 => uint) public ContractNamesToRoutes; // (keccak256('Route Name') => routeId)
    mapping(address => uint[]) public OwnersToRoutes;
    mapping(address => uint[]) public OwnersToPendingTransfersByRouteId;

    //Events
    event RouteCreated(string name, address owner);
    event UpdateScheduled(string name, address owner);
    event TransferOwnership(string name, address owner, address newOwner);
    event AcceptOwnership(string name, address newOwner);

    //Constructor
    constructor() public {
        // Create padding in Routes array to be able to check for unique name in list by returning 0 for no match
        _Create('',address(this));
        _Create('atra.ads',address(this));
        _Create('atra.ads.pricing',address(this));
    }

    function Get(uint _id, string _name) public view returns(
            string name,
            address addr,
            uint released,
            uint version,
            uint update,
            address updateAddr,
            uint active,
            address owner,
            uint created
        ) {
        Route memory route;
        if(bytes(_name).length > 0){
            route = Routes[ContractNamesToRoutes[keccak256(_name)]];
        }else{
            route = Routes[_id];
        }
        return (
            route.name, //name
            route.current.contractAddress, //addr
            // if update is active the released date is when it went live, else it's the release date
            route.updateRelease < now ? route.updateRelease : route.released, //released
            //check is next contract is active, if so it's a different version add 1, else return normal version
            route.updateRelease < now ? route.version.add(1) : route.version, //version
            // active position  will be used to determine what address to use by the client 0=current 1=next
            route.updateRelease, //update
            route.update.contractAddress, //updateAddr
            route.updateRelease < now ? 1 : 0, //active
            route.owner, //owner
            route.created //created
            );
    }

    function GetRouteIdsForOwner(address _owner) external view returns(uint[] routeIds) {
        return OwnersToRoutes[_owner];
    }
    function GetAddress(uint _id, string _name) external view returns(address addr) {
      return _GetAddress(_id,_name);
    }
    function _GetAddress(uint _id, string _name) private view returns(address addr) {
        Route memory route;
        if(bytes(_name).length > 0){
            route = Routes[ContractNamesToRoutes[keccak256(_name)]];
        }else{
            route = Routes[_id];
        }
        return route.updateRelease < now ? route.update.contractAddress : route.current.contractAddress;
    }

    function RoutesLength() external view returns(uint length){
        return Routes.length;
    }

    function NameTaken(string _name) external view returns(bool) {
        require(bytes(_name).length > 0 && bytes(_name).length <= 100);
        if(ContractNamesToRoutes[keccak256(_name)] == 0){
            return false;//name is not taken
        }else{
            return true;
        }
    }
    function Create(string _name, address _addr) external payable returns(uint id) {
      require(msg.sender == owner);
      // validate inputs
      require(bytes(_name).length > 0 && bytes(_name).length <= 100);
      return _Create(_name, _addr);
    }
    function _Create(string _name, address _addr) private returns(uint id) {
        // ** Below is where the padding route object comes into play. ** //
        // ** A mapping will return 0 if there is a hit and the array index is 0 AND if there is nothing found ** //
        // ** To pervent this we add padding to the routes list by creating a blank record and requiring _name to have a length > 0 ** //
        // ** The state below now will only return 0 if there isn't a route found ** //
        require(ContractNamesToRoutes[keccak256(_name)] == 0);
        uint routeId = Routes.push(Route(_name, now, msg.sender, msg.sender, RouteData(_addr), RouteData(_addr),now, 0, now)) -1;
        OwnersToRoutes[msg.sender].push(routeId);
        emit RouteCreated(_name, msg.sender);
        return ContractNamesToRoutes[keccak256(_name)] = routeId;
    }

    function ScheduleUpdate(uint _id, string _name, uint _release, address _addr) external payable returns(bool success) {
        require(msg.sender == owner);
        Route storage route;
        if(bytes(_name).length > 0){
            route = Routes[ContractNamesToRoutes[keccak256(_name)]];
        }else{
            route = Routes[_id];
        }

        require(route.owner == msg.sender); //require sender to be owner to update

        //if Next Contract Data is active do not overwrite Next data, move it to Current and increment the version
        if(route.updateRelease < now){
            route.current = route.update;
            route.released = route.updateRelease;
            route.version = route.version.add(1);
        }

        route.updateRelease = now.add(_release);// if updateRelease is zero update will be live now
        route.update.contractAddress = _addr; // update next address
        emit UpdateScheduled(route.name, msg.sender);
        return true; // return success
    }

    function GetPendingRouteTransfer(uint _id, string _name) external view returns(address addr) {
        Route storage route;
        if(bytes(_name).length > 0){
            route = Routes[ContractNamesToRoutes[keccak256(_name)]];
        }else{
            route = Routes[_id];
        }
        return route.newOwner != route.owner ? route.newOwner : address(0);
    }

    function GetPendingTransfersForSender() external view returns(uint[] routeIds) {
        return OwnersToPendingTransfersByRouteId[msg.sender];
    }

    function TransferRouteOwnership(uint _id, string _name, address _owner) external payable returns(bool success) {
        require(msg.sender == owner);
        Route storage route;
        uint id = _id;
        if(bytes(_name).length > 0){
            id = ContractNamesToRoutes[keccak256(_name)];
            route = Routes[ContractNamesToRoutes[keccak256(_name)]];
        }else{
            route = Routes[id];
        }
        require(route.owner == msg.sender); //require sender to be owner to transfer ownership
        route.newOwner = _owner; // set new owner
        OwnersToPendingTransfersByRouteId[route.newOwner].push(_id);
        emit TransferOwnership(route.name, msg.sender, route.newOwner);
        return true; // return success
    }

    function AcceptRouteOwnership(uint _id, string _name) external payable returns(bool success) {
        require(msg.sender == owner);
        Route storage route;
        uint id = _id;
        if(bytes(_name).length > 0){
            id = ContractNamesToRoutes[keccak256(_name)];
            route = Routes[ContractNamesToRoutes[keccak256(_name)]];
        }else{
            route = Routes[id];
        }
        require(route.newOwner == msg.sender); //require sender to be newOwner to accecpt ownership

        //delete route lookup for pervious owner
        //get last routeid in array
        uint keepRouteId = OwnersToRoutes[route.owner][OwnersToRoutes[route.owner].length - 1];
        //replace routeId marked for delete
        for(uint x = 0; x < OwnersToRoutes[route.owner].length; x++){
            if(OwnersToRoutes[route.owner][x] == _id){
                OwnersToRoutes[route.owner][x] = keepRouteId;
            }
        }
        //delete last position
        delete OwnersToRoutes[route.owner][OwnersToRoutes[route.owner].length - 1];
        //adjust array length
        OwnersToRoutes[route.owner].length--;

         // Add route to new owner
        route.owner = route.newOwner; // transfer ownership
        OwnersToRoutes[route.owner].push(_id); // add lookup


        // remove route id from PendingRouteOwnershipTransfer for the new owner
        uint keepPendingRouteId = OwnersToPendingTransfersByRouteId[route.owner][OwnersToPendingTransfersByRouteId[route.owner].length - 1];
        //replace routeId marked for delete
        for(uint y = 0; y < OwnersToPendingTransfersByRouteId[route.owner].length; y++){
            if(OwnersToPendingTransfersByRouteId[route.owner][y] == _id){
                OwnersToPendingTransfersByRouteId[route.owner][y] = keepPendingRouteId;
            }
        }
        //delete last position
        delete OwnersToPendingTransfersByRouteId[route.owner][OwnersToPendingTransfersByRouteId[route.owner].length - 1];
        //adjust array length
        OwnersToPendingTransfersByRouteId[route.owner].length--;


        emit AcceptOwnership(route.name, route.owner);
        return true; // return success
    }

    function Widthdraw(uint _amount) public isOwner returns(bool success) {
        // if amount is zero take the whole balance else use amount
        owner.transfer(_amount == 0 ? address(this).balance : _amount);
        return true;
    }

    function Balance() public view isOwner returns(uint balance) {
        return address(this).balance;
    }

}
