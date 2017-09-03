pragma solidity ^0.4.6;

import "./Admin.sol";
import "./Shopfront.sol";

contract CoBuying 
{
    Shopfront shopFront;
    
    address public creator;
    uint    public deadline;
    uint256 public productId;
    uint    public quantity;
    uint    public totalPrice;
    uint    public totalDeposit;
    mapping (address => uint) public deposit;

    
    
    function CoBuying (address shopFrontAddress, address _creator, uint256 _productId, uint _quantity, uint coBuyingDuration) 
    {

        shopFront = Shopfront(shopFrontAddress);
        uint _totalPrice = shopFront.getProductPrice(_productId, _quantity);
        
        creator    = _creator;
        deadline   = block.number + coBuyingDuration;
        productId  = _productId;
        quantity   = _quantity;
        totalPrice = _totalPrice;
        
    }
    

    event LogJoinCoBuying(address joiner, uint _deposit);
    event LogProcessCoBuying (uint256 _productId, uint _quantity);
    event LogFailedCoBuyingRefund (address refundReceiver, uint amount);


    
    function isCoBuyingSuccess () 
        public
        constant
        returns (bool)
    {
        return (totalDeposit >= totalPrice);
    }

    function hasCoBuyingFailed () 
        public
        constant
        returns (bool) 
    {
        return (totalDeposit < totalPrice && block.number > deadline);        
    }
    
    
    function joinCoBuying () 
        public
        payable
        returns (bool)
    {
        require (msg.value > 0);
        require (!hasCoBuyingFailed());
        require (!isCoBuyingSuccess());
    
        totalDeposit += msg.value;
        deposit[msg.sender] = msg.value;
        LogJoinCoBuying(msg.sender, msg.value);

        if (totalDeposit >=  totalPrice) {
            processCoBuying();
        }
    
        return true;
    }

    function processCoBuying () 
        public
        payable
        returns (bool)
    {
        require (totalDeposit >= totalPrice);
        
    
        shopFront.buyProduct.value(totalDeposit)(productId, quantity);
        LogProcessCoBuying (productId, quantity);
        
        return true;
    }

    function processFailedCoBuyingRefund () 
        public
        payable
        returns (bool)
    {
        require(hasCoBuyingFailed());
        uint amountOwed = deposit[msg.sender];
        require(amountOwed > 0);
        deposit[msg.sender] = 0;
        msg.sender.transfer(amountOwed);
        LogFailedCoBuyingRefund (msg.sender, amountOwed);

        return true;
    }
}