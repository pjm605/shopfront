pragma solidity ^0.4.6;

contract Shopfront
{
    address     public owner;
    address     public administrator;
    
    function Shopfront() {
        owner = msg.sender;
        //initially administrator is owner;
        administrator = msg.sender;
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
        bytes32 productName;
        uint    productPrice;
        uint    productStock;
        uint    index;
    }
    
    mapping (address => uint) balances;
    mapping (bytes32 => ProductStruct) public products;
    bytes32[] private productIndex;

    event LogNewProduct (bytes32 indexed productId, uint index, bytes32 productName, uint productPrice, uint productStock);
    event LogDeleteProduct (bytes32 indexed productId, uint index);
    event LogUpdateProduct (bytes32 indexed productId, uint index, bytes32 productName, uint productPrice, uint productStock);
    event LogBuyProduct (address buyer, bytes32 productId, uint quantity);
    event LogWithdrawn (address withdrawTo, uint amount);

    function registerAdministrator (address _administrator) 
        isOwner()
        public
        returns (bool)
    {
        administrator = _administrator;
        return true;
    }
    
    function isProduct (bytes32 productId)
        public
        constant
        returns (bool)
    {
        if (productIndex.length == 0) return false;
        return (productIndex[products[productId].index] == productId);
    }
    

    function addProduct (bytes32 _productId, bytes32 _productName, uint _productPrice, uint _productStock)
        isAdministrator()
        public
        returns (uint index)
    {

        require (!isProduct(_productId));

        products[_productId].productName = _productName;
        products[_productId].productPrice = _productPrice;
        products[_productId].productStock = _productStock;
        products[_productId].index = productIndex.push(_productId)-1;
        LogNewProduct (_productId, products[_productId].index, _productName, _productPrice, _productStock);
        
        return productIndex.length - 1;
    }

    function deleteProduct (bytes32 _productId) 
        isAdministrator()
        public
        returns (uint index)
    {
        require (isProduct(_productId));
        uint targetProductIndex = products[_productId].index;
        bytes32 keyToMove = productIndex[productIndex.length-1];
        
        productIndex[targetProductIndex] = keyToMove;
        products[keyToMove].index = targetProductIndex;
        productIndex.length--;
        
        LogDeleteProduct (_productId, targetProductIndex);
        LogUpdateProduct (keyToMove, targetProductIndex, products[keyToMove].productName, products[keyToMove].productPrice, products[keyToMove].productStock);
        
        return targetProductIndex;

    }
    
    // function updateProductPrice (bytes32 _productId, uint newProductPrice)
    //     public
    //     isAdministrator()
    //     returns(bool)
    // {
    //     require(isProduct(_productId));
    //     products[_productId].productPrice = newProductPrice;
    //     LogUpdateProductPrice(_productId, products[_productId].index, products[_productId].productName, products[_productId].productStock, products[_productId].productStock);
    //     return true;
    // }

    
    function buyProduct (bytes32 _productId, uint quantity) 
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
        
        uint postSaleQuantity = (products[_productId].productStock - quantity);
        products[_productId].productStock = postSaleQuantity;
        
        LogBuyProduct(msg.sender,  _productId,  quantity);
        LogUpdateProduct (_productId, products[_productId].index, products[_productId].productName,  products[_productId].productPrice,  products[_productId].productStock);
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
        LogWithdrawn(msg.sender, amount);

        return true;
    }
    
    
}

