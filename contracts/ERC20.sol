pragma solidity ^0.4.6;

/**
      @notice Base Token contract according to ERC20
      https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 {
    
  uint256 public totalSupply;
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}