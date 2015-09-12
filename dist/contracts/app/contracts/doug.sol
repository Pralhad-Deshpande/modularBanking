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


contract ContractProvider {
    function contracts(bytes32 name) constant returns (address addr) {}
}

contract FundManagerEnabled is DougEnabled {

    // Makes it easier to check that fundmanager is the caller.
    function isFundManager() returns (bool) {
        if(DOUG != 0x0){
            address fm = ContractProvider(DOUG).contracts("fundmanager");
            return msg.sender == fm;
        }
        return false;
    }
}

contract PermissionsDb is DougEnabled {

    mapping (address => uint8) public perms;

    // Set the permissions of an account.
    function setPermission(address addr, uint8 perm) returns (bool res) {
        if(DOUG != 0x0){
            address permC = ContractProvider(DOUG).contracts("perms");
            if (msg.sender == permC ){
                perms[addr] = perm;
                return true;
            }
            return false;
        } else {
            return false;
        }
    }

}


contract Permissions is FundManagerEnabled {

    // Set the permissions of an account.
    function setPermission(address addr, uint8 perm) returns (bool res) {
        if (!isFundManager()){
            return false;
        }
        address permdb = ContractProvider(DOUG).contracts("permsdb");
        if ( permdb == 0x0 ) {
            return false;
        }
        return PermissionsDb(permdb).setPermission(addr, perm);
    }

}

contract BankDb is DougEnabled {

    mapping (address => uint) public balances;

    function deposit(address addr) returns (bool res) {
        if(DOUG != 0x0){
            address bank = ContractProvider(DOUG).contracts("bank");
            if (msg.sender == bank ){
                balances[addr] += msg.value;
                return true;
            }
        }
        // Return if deposit cannot be made.
        msg.sender.send(msg.value);
        return false;
    }

    function withdraw(address addr, uint amount) returns (bool res) {
        if(DOUG != 0x0){
            address bank = ContractProvider(DOUG).contracts("bank");
            if (msg.sender == bank ){
                uint oldBalance = balances[addr];
                if(oldBalance >= amount){
                    msg.sender.send(amount);
                    balances[addr] = oldBalance - amount;
                    return true;
                }
            }
        }
        return false;
    }

}

// The bank
contract Bank is FundManagerEnabled {


    // Attempt to withdraw the given 'amount' of Ether from the account.
    function deposit(address userAddr) returns (bool res) {
        if (!isFundManager()){
            return false;
        }
        address bankdb = ContractProvider(DOUG).contracts("bankdb");
        if ( bankdb == 0x0 ) {
            // If the user sent money, we should return it if we can't deposit.
            msg.sender.send(msg.value);
            return false;
        }

       // Use the interface to call on the bank contract. We pass msg.value along as well.
        bool success = BankDb(bankdb).deposit.value(msg.value)(userAddr);

        // If the transaction failed, return the Ether to the caller.
        if (!success) {
            msg.sender.send(msg.value);
        }
        return success;
        return true;
    }

    // Attempt to withdraw the given 'amount' of Ether from the account.
    function withdraw(address userAddr, uint amount) returns (bool res) {
        if (!isFundManager()){
            return false;
        }
        address bankdb = ContractProvider(DOUG).contracts("bankdb");
        if ( bankdb == 0x0 ) {
            return false;
        }

        // Use the interface to call on the bank contract.
        bool success = BankDb(bankdb).withdraw(userAddr, amount);

        // If the transaction succeeded, pass the Ether on to the caller.
        if (success) {
            userAddr.send(amount);
        }
        return success;
	return true;
    }

}


// The fund manager
contract FundManager is DougEnabled {

    // We still want an owner.
    address owner;

    // Constructor
    function FundManager(){
        owner = msg.sender;
    }

    // Attempt to withdraw the given 'amount' of Ether from the account.
    function deposit() constant returns (bool res) {
        if (msg.value == 0){
            return false;
        }
        address bank = ContractProvider(DOUG).contracts("bank");
        address permsdb = ContractProvider(DOUG).contracts("permsdb");
        if ( bank == 0x0 || permsdb == 0x0 || PermissionsDb(permsdb).perms(msg.sender) < 1) {
            // If the user sent money, we should return it if we can't deposit.
            msg.sender.send(msg.value);
            return false;
        }

        // Use the interface to call on the bank contract. We pass msg.value along as well.
        bool success = Bank(bank).deposit.value(msg.value)(msg.sender);

        // If the transaction failed, return the Ether to the caller.
        if (!success) {
            msg.sender.send(msg.value);
        }
        return success;
    }

    // Attempt to withdraw the given 'amount' of Ether from the account.
    function withdraw(uint amount) constant returns (bool res) {
        if (amount == 0){
            return false;
        }
        address bank = ContractProvider(DOUG).contracts("bank");
        address permsdb = ContractProvider(DOUG).contracts("permsdb");
        if ( bank == 0x0 || permsdb == 0x0 || PermissionsDb(permsdb).perms(msg.sender) < 1) {
            // If the user sent money, we should return it if we can't deposit.
            msg.sender.send(msg.value);
            return false;
        }

        // Use the interface to call on the bank contract.
        bool success = Bank(bank).withdraw(msg.sender, amount);

        // If the transaction succeeded, pass the Ether on to the caller.
        if (success) {
            msg.sender.send(amount);
        }
        return success;
    }

    // Set the permissions for a given address.
    function setPermission(address addr, uint8 permLvl) constant returns (bool res) {
        if (msg.sender != owner){
            return false;
        }
	//return true;

        address perms = ContractProvider(DOUG).contracts("perms");
        if ( perms == 0x0 ) {
            return false;
        }
	return true;
        //return Permissions(perms).setPermission(addr,permLvl);
    }

}


