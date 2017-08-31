pragma solidity ^0.4.6;

import "./Admin.sol";

contract Shopfront is Admin
{
    uint coBuyingId = 0;

    struct ProductStruct {
        bytes32 productName;
        uint    productPrice;
        uint    productStock;
        uint    index;
    }
    
    
    struct CoBuyingTxnStruct {
        // uint coBuyingTxnKey is unique key;
        address creator;
        uint    deadline;
        uint256 productId;
        uint    quantity;
        uint    totalPrice;
        uint    totalDeposit;
        mapping (address => uint) deposit;
        uint    coBuyingTxnIndex; 
    }
    
     
    mapping (address => uint) balances;
    mapping (uint256 => ProductStruct) public products;
    mapping (uint => CoBuyingTxnStruct) public coBuyingTxns;
    uint256[] private productIndex;
    uint[] private coBuyingTxnIndex;

    event LogNewProduct (uint256 indexed productId, uint index, bytes32 productName, uint productPrice, uint productStock);
    event LogDeleteProduct (uint256 indexed productId, uint index);
    event LogUpdateProduct (uint256 indexed productId, uint index, bytes32 productName, uint productPrice, uint productStock);
    
    event LogNewCoBuyingTxn (uint indexed coBuyingTxnKey, address creator, uint deadline, uint256 productId, uint quantity, uint totalPrice);
    event LogJoinCoBuyingTxn (uint indexed coBuyingTxnKey, address joiner, uint deposit);
    event LogProcessCoBuyingTxn (uint indexed coBuyingTxnKey, uint256 productId, uint quantity);
    event LogFailedCoBuyingTxnRefund (uint indexed coBuyingTxnKey, address refundReceiver, uint amount);

    event LogBuyProduct (address buyer, uint256 productId, uint quantity);
    event LogWithdrawn (address withdrawTo, uint amount);
    
    modifier hasEnoughStock (uint256 _productId, uint _quantity) {
        require (products[_productId].productStock > _quantity);
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
    
    function isCoBuyingTxn (uint coBuyingTxnKey) 
        public
        constant
        returns (bool)
    {
        if (coBuyingTxnIndex.length == 0) return false;
        return (coBuyingTxnIndex[coBuyingTxns[coBuyingTxnKey].coBuyingTxnIndex] == coBuyingTxnKey);
    }
    

    function addProduct (uint256 _productId, bytes32 _productName, uint _productPrice, uint _productStock)
        isAdministrator
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

    function isCoBuyingSuccess (uint coBuyingTxnKey) 
        public
        constant
        returns (bool)
    {
        return (coBuyingTxns[coBuyingTxnKey].totalDeposit >=  coBuyingTxns[coBuyingTxnKey].totalPrice);
    }

    function hasCoBuyingFailed (uint coBuyingTxnKey) 
        public
        constant
        returns (bool) 
    {
        return (coBuyingTxns[coBuyingTxnKey].totalDeposit < coBuyingTxns[coBuyingTxnKey].totalPrice && block.number > coBuyingTxns[coBuyingTxnKey].deadline);        
    }
    

    function createCoBuyingTxn (uint256 _productId, uint _quantity, uint coBuyingDuration) 
        public
        payable
        hasEnoughStock(_productId, _quantity)
        returns (bool)
    {
        require (isProduct(_productId));
        
        uint coBuyingTxnKey = coBuyingId++;
        require (!isCoBuyingTxn(coBuyingTxnKey));
        
        uint totalPrice = (products[_productId].productPrice * _quantity);
        
        coBuyingTxns[coBuyingTxnKey].creator    = msg.sender;
        coBuyingTxns[coBuyingTxnKey].deadline   = block.number + coBuyingDuration;
        coBuyingTxns[coBuyingTxnKey].productId  = _productId;
        coBuyingTxns[coBuyingTxnKey].quantity   = _quantity;
        coBuyingTxns[coBuyingTxnKey].totalPrice = totalPrice;
        coBuyingTxns[coBuyingTxnKey].coBuyingTxnIndex = coBuyingTxnIndex.push(coBuyingTxnKey)-1;
        LogNewCoBuyingTxn(coBuyingTxnKey, msg.sender, coBuyingTxns[coBuyingTxnKey].deadline, _productId, _quantity, totalPrice);
        
        return true;
    }
    
    function joinCoBuyingTxn (uint coBuyingTxnKey) 
        public
        payable
        returns (bool)
    {
        require (msg.value > 0);
        require (!hasCoBuyingFailed(coBuyingTxnKey));
        require (!isCoBuyingSuccess(coBuyingTxnKey));
    
        coBuyingTxns[coBuyingTxnKey].totalDeposit += msg.value;
        coBuyingTxns[coBuyingTxnKey].deposit[msg.sender] = msg.value;
        LogJoinCoBuyingTxn(coBuyingTxnKey, msg.sender, msg.value);

        if (coBuyingTxns[coBuyingTxnKey].totalDeposit >=  coBuyingTxns[coBuyingTxnKey].totalPrice) {
            processCoBuyingTxn(coBuyingTxnKey);
        }
    
        return true;
    }

    function processCoBuyingTxn (uint coBuyingTxnKey) 
        public
        payable
        returns (bool)
    {
        require (coBuyingTxns[coBuyingTxnKey].totalDeposit >= coBuyingTxns[coBuyingTxnKey].totalPrice);
        
        uint256 coBuyingPId = coBuyingTxns[coBuyingTxnKey].productId;
        require(products[coBuyingPId].productStock >=  coBuyingTxns[coBuyingTxnKey].quantity);
    
        balances[owner] += coBuyingTxns[coBuyingTxnKey].totalPrice;
        
        uint postSaleQuantity = (products[coBuyingPId].productStock - coBuyingTxns[coBuyingTxnKey].quantity);
        products[coBuyingPId].productStock = postSaleQuantity;
        
        LogProcessCoBuyingTxn (coBuyingTxnKey, coBuyingPId, coBuyingTxns[coBuyingTxnKey].quantity);
        LogUpdateProduct (coBuyingPId, products[coBuyingPId].index, products[coBuyingPId].productName,  products[coBuyingPId].productPrice,  products[coBuyingPId].productStock);
        return true;
    }

    function processFailedCoBuyingTxnRefund (uint coBuyingTxnKey) 
        public
        payable
        returns (bool)
    {
        require(hasCoBuyingFailed(coBuyingTxnKey));
        uint amountOwed = coBuyingTxns[coBuyingTxnKey].deposit[msg.sender];
        require(amountOwed > 0);
        coBuyingTxns[coBuyingTxnKey].deposit[msg.sender] = 0;
        msg.sender.transfer(amountOwed);
        LogFailedCoBuyingTxnRefund (coBuyingTxnKey, msg.sender, amountOwed);

        return true;
    }
    
    function buyProduct (uint256 _productId, uint quantity) 
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
    
    function getProductCount () 
        public
        constant
        returns (uint count)
    {
        return productIndex.length;
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

