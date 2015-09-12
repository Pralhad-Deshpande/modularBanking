contract DougEnabled {
    address DOUG;

    function setDougAddress(address dougAddr) returns (bool result){
        // Once the doug address is set, don't allow it to be set again, except by the
        // doug contract itself.
        if(DOUG != 0x0 && dougAddr != DOUG){
            return false;
        }
        DOUG = dougAddr;
        return true;
    }

    // Makes it so that Doug is the only contract that may kill it.
    function remove(){
        if(msg.sender == DOUG){
            suicide(DOUG);
        }
    }

}

contract Doug{
    address owner;

    mapping (bytes32 => address) public contracts;

    function Doug(){
	owner = msg.sender;
    }

    function getOwner() constant returns (address addr){
	return owner;
    }

    function addContract(bytes32 name, address addr) returns (bool result) {
        if(msg.sender != owner){
            return false;
        }
        DougEnabled de = DougEnabled(addr);
        // Don't add the contract if this does not work.
        if(!de.setDougAddress(address(this))) {
            return false;
        }
        contracts[name] = addr;
        return true;
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

            // Remove everything.
            //if(fm != 0x0){ DougEnabled(fm).remove(); }
            //if(perms != 0x0){ DougEnabled(perms).remove(); }
            //if(permsdb != 0x0){ DougEnabled(permsdb).remove(); }
            //if(bank != 0x0){ DougEnabled(bank).remove(); }
            //if(bankdb != 0x0){ DougEnabled(bankdb).remove(); }

            // Finally, remove doug. Doug will now have all the funds of the other contracts,
            // and when suiciding it will all go to the owner.
            suicide(owner);
        }
    }

}

