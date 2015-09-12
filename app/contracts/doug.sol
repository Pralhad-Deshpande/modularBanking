contract DougEnabled {
    address DOUG;

    function setDougAddress(address dougAddr) constant returns (bool result){
        if(DOUG != 0x0 && dougAddr != DOUG){
            return false;
        }
        DOUG = dougAddr;
        return true;
    }

    function remove(){
        if(msg.sender == DOUG){
            suicide(DOUG);
        }
    }

}

contract Doug {

    address owner;

    mapping (bytes32 => address) public contracts;

    function Doug(){
        owner = msg.sender;
    }

    function getOwner() constant returns (address addr){
	return owner;
    }

    function addContract(bytes32 name, address addr) constant returns (bool result) {
        if(msg.sender != owner){
            return false;
        }
        DougEnabled de = DougEnabled(addr);
        
        if(!de.setDougAddress(address(this))) {
            return false;
        }
        contracts[name] = addr;
        return true;
    }

    function getContract(bytes32 name) constant returns (address addr){
	return contracts[name];
    }

    function removeContract(bytes32 name) returns (bool result) {
        if (contracts[name] == 0x0){
            return false;
        }
        if(msg.sender != owner){
            return;
        }
        contracts[name] = 0x0;
        return true;
    }

    function remove(){

        if(msg.sender == owner){

            //address fm = contracts["fundmanager"];
            //address perms = contracts["perms"];
            //address permsdb = contracts["permsdb"];
            //address bank = contracts["bank"];
            //address bankdb = contracts["bankdb"];

            //if(fm != 0x0){ DougEnabled(fm).remove(); }
            //if(perms != 0x0){ DougEnabled(perms).remove(); }
            //if(permsdb != 0x0){ DougEnabled(permsdb).remove(); }
            //if(bank != 0x0){ DougEnabled(bank).remove(); }
            //if(bankdb != 0x0){ DougEnabled(bankdb).remove(); }

            suicide(owner);
        }
    }

}


