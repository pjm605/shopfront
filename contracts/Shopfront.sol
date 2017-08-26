pragma solidity ^0.4.6;

contract Shopfront
{
    address     public owner;
    address     public administrator;
    
    function Shopfront() {
        owner = msg.sender;
    }
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier isAdministrator() {
        require(msg.sender == administrator);
        _;
    }
    
    struct ProductStruct {
        uint    productId;
        string  productName;
        uint    productPrice;
        uint    productStock;
        uint    index;
    }
    
    mapping (address => uint) balances;
    
    
    mapping (uint => ProductStruct) private products;
    uint[] private productIndex;
    
    function registerAdministrator (address _administrator) 
        isOwner()
        public
        returns (bool)
    {
        administrator = _administrator;
        return true;
    }
    
    function isProduct (uint productId)
        public
        constant
        returns (bool)
    {
        if (productIndex.length == 0) return false;
        return (productIndex[products[productId].index] == productId);
    }
    

    function addProduct (uint _productId, string _productName, uint _productPrice, uint _productStock)
        isAdministrator()
        public
        returns (uint index)
    {

        require (!isProduct(_productId));
        products[_productId].productId = _productId;
        products[_productId].productName = _productName;
        products[_productId].productPrice = _productPrice;
        products[_productId].productStock = _productStock;
        products[_productId].index = productIndex.push(_productId)-1;
        
        return productIndex.length - 1;
    }
    
    function updateProductPrice (uint _productId, uint _productPrice)
        public
        isAdministrator()
        returns(bool)
    {
        require(isProduct(_productId));
        products[_productId].productPrice = _productPrice;
        return true;
    }
    
    function buyProduct (uint _productId, uint quantity) 
        public
        payable
        returns(bool)
    {
        require (isProduct(_productId));
        require (products[_productId].productStock > quantity);
        uint totalPrice = (products[_productId].productPrice * quantity);
        require (totalPrice <= msg.value);
        uint remaining = totalPrice - msg.value;
        
        balances[owner] += totalPrice;
        
        if (remaining > 0) {
            balances[msg.sender] += remaining;
        }
        
        return true;
            
    }
    
    function withdrawBalance () 
        public
        payable
        returns (bool)
    {
        require (balances[msg.sender] > 0);
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
        return true;
    }
    
    
}

