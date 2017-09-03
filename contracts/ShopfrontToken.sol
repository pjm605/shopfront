pragma solidity ^0.4.6;

import './ERC20.sol';
import './SafeMath.sol';

contract ShopfrontToken is ERC20 {
    using SafeMath for uint256;
    
    mapping (address => uint256) tokenBalances;
    mapping (address => mapping (address => uint256)) tokenAllowed;
    
    modifier isValidAddress (address _address) {
        require(_address != address(0));
        _;
    }
    
    function tokenTransfer(address _to, uint256 _value) 
        isValidAddress(_to)
        returns (bool) 
    {
        tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
        tokenBalances[_to] = tokenBalances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
  
    function tokenBalanceOf(address _owner) 
        constant 
        returns (uint256 balance) 
    {
        return tokenBalances[_owner];
    }


    function tokenTransferFrom(address _from, address _to, uint256 _value) 
        isValidAddress(_to)
        returns (bool) 
    {
        
        var _allowance = tokenAllowed[_from][msg.sender];
    
        tokenBalances[_from] = tokenBalances[_from] - _value;
        tokenBalances[_to] = tokenBalances[_to].add(_value);
        tokenAllowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function tokenApprove(address _spender, uint256 _value) 
        returns (bool) 
    {
        //To avoid double spending (race condition), 
        //we have to force users to always set allowed to 0 before setting to anoter value
        require((_value == 0) || (tokenAllowed[msg.sender][_spender] == 0));
    
        tokenAllowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
     }

    function tokenAllowance(address _owner, address _spender) 
        constant 
        returns (uint256 remaining) 
    {
        return tokenAllowed[_owner][_spender];
    }
  
    function increaseTokenApproval (address _spender, uint _addedValue) 
        returns (bool success) 
    {
        tokenAllowed[msg.sender][_spender] = tokenAllowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, tokenAllowed[msg.sender][_spender]);
        return true;
    }

    function decreaseTokenApproval (address _spender, uint _subtractedValue) 
        returns (bool success) 
    {
        uint oldValue = tokenAllowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          tokenAllowed[msg.sender][_spender] = 0;
        } else {
          tokenAllowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, tokenAllowed[msg.sender][_spender]);
        return true;
    }

}