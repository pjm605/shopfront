pragma solidity ^0.4.6;

contract Admin {
	address public owner;
	address public administrator;

	function Admin () {
		owner = msg.sender;
		//initially administrator is owner;
		administrator = msg.sender;
	}

	modifier isOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier isAdministrator {
        require(msg.sender == administrator);
        _;
    }

    function registerAdministrator (address _administrator) 
        isOwner
        public
        returns (bool)
    {
        require (_administrator != 0);
        administrator = _administrator;
        return true;
    }

}