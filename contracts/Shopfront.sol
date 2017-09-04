pragma solidity ^0.4.6;

import "./Admin.sol";
import "./CoBuying.sol";
import "./ShopfrontToken.sol";

contract Shopfront is Admin
{
    address[] public coBuyings;
    mapping (address => bool) coBuyingExists;
    
    struct ProductStruct {
        bytes32 productName;
        uint    productPrice;
        uint    productStock;
        uint    productPriceInTokens;
        uint    index;
    }

    mapping (address => uint) public balances;
    mapping (uint256 => ProductStruct) public products;
    uint256[] private productIndex;

    event LogNewProduct (uint256 indexed productId, uint index, bytes32 productName, uint productPrice, uint productStock);
    event LogDeleteProduct (uint256 indexed productId, uint index);
    event LogUpdateProduct (uint256 indexed productId, uint index, bytes32 productName, uint productPrice, uint productStock);
    
    event LogNewCoBuying (address newCoBuyingAddr, address creator, uint coBuyingDuration, uint256 productId, uint quantity);

    event LogBuyProduct (address buyer, uint256 productId, uint quantity);
    event LogBuyProductWithToken (address buyer, uint256 productId, uint quantity);
    event LogWithdrawn (address withdrawTo, uint amount);
    
    modifier hasEnoughStock (uint256 _productId, uint _quantity) {
        require (products[_productId].productStock >= _quantity);
        _;
    }
    
    modifier isCoBuyingExist (address coBuyingAddr) {
        require (coBuyingExists[coBuyingAddr] == true);
        _;
    }
    
    
    function isProduct (uint256 productId)
        public
        constant
        returns (bool)
    {
        if (productIndex.length == 0) return false;
        return (productIndex[products[productId].index] == productId);
    }
    

    function addProduct (uint256 _productId, bytes32 _productName, uint _productPrice, uint _productStock, uint _productPriceInTokens)
        isAdministrator
        public
        returns (uint index)
    {

        require (!isProduct(_productId));

        products[_productId].productName = _productName;
        products[_productId].productPrice = _productPrice;
        products[_productId].productStock = _productStock;
        products[_productId].productPriceInTokens = _productPriceInTokens;
        products[_productId].index = productIndex.push(_productId)-1;
        LogNewProduct (_productId, products[_productId].index, _productName, _productPrice, _productStock);
        
        return productIndex.length - 1;
    }
    
    function deleteProduct (uint256 _productId) 
        isAdministrator
        public
        returns (uint index)
    {
        require (isProduct(_productId));
        uint targetProductIndex = products[_productId].index;
        uint256 keyToMove = productIndex[productIndex.length-1];
        
        productIndex[targetProductIndex] = keyToMove;
        products[keyToMove].index = targetProductIndex;
        productIndex.length--;
        
        LogUpdateProduct (keyToMove, targetProductIndex, products[keyToMove].productName, products[keyToMove].productPrice, products[keyToMove].productStock);
        LogDeleteProduct (_productId, targetProductIndex);

        return targetProductIndex;

    }

    
    function buyProduct (uint256 _productId, uint quantity) 
        public
        payable
        hasEnoughStock(_productId, quantity)
        returns(bool)
    {
        require (isProduct(_productId));
        
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
    
    function buyProductWithToken (uint256 _productId, uint quantity, address tokenAddress) 
        public
        payable
        hasEnoughStock(_productId, quantity)
        returns(bool)
    {
        require (isProduct(_productId));
        
        ShopfrontToken token = ShopfrontToken(tokenAddress);
        
        uint totalPriceInTokens = (products[_productId].productPriceInTokens * quantity);
        require(totalPriceInTokens <= token.tokenAllowance(owner, msg.sender));
        
        token.tokenTransferFrom(msg.sender, owner, totalPriceInTokens);

        uint postSaleQuantity = (products[_productId].productStock - quantity);
        products[_productId].productStock = postSaleQuantity;
        
        LogBuyProductWithToken(msg.sender,  _productId,  quantity);
        LogUpdateProduct (_productId, products[_productId].index, products[_productId].productName,  products[_productId].productPrice,  products[_productId].productStock);
        return true;
    }
    
    function getProductCount () 
        public
        constant
        returns (uint count)
    {
        return productIndex.length;
    }
    
    function getProductPrice (uint256 _productId, uint quantity) 
        public
        constant
        returns (uint productPrice)
    {
        return (products[_productId].productPrice * quantity);
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
    
    function createNewCoBuying (uint256 _productId, uint _quantity, uint coBuyingDuration) 
        public
        returns (address coBuyingContract)
    {
        require (isProduct(_productId));

        CoBuying trustedCoBuying = new CoBuying(this, msg.sender, _productId, _quantity, coBuyingDuration);
        coBuyings.push(trustedCoBuying);
        coBuyingExists[trustedCoBuying] = true;

        LogNewCoBuying(trustedCoBuying, msg.sender, coBuyingDuration, _productId, _quantity);
        return trustedCoBuying;
    } 
    
}

