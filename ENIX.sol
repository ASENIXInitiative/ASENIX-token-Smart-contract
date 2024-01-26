// SPDX-License-Identifier: MIT



pragma solidity 0.8.19;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return(true, a - b);}}

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}


/////ASENIX.sol

contract ASENIX is IERC20, Ownable {



    using SafeMath for uint256;
    string private constant _name = 'ASENIX';
    string private constant _symbol = 'ENIX';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 500000000 * (10 ** _decimals);
    uint256 public swapTokensAtAmount = 40000 * (10**9);
  
   
    IRouter router;
    address public pair;
    bool private tradingAllowed = false;
   
    

  
    bool private swapping; 
  

      address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
   
      address public taxWallet;
     
     
      uint256 public buyTax;
      uint256 public sellTax;

      uint256 public maxTransactionAmount;
      uint256 public maxWallet;

     bool public limitsInEffect = true;
      

      mapping(address => bool) public _isExcludedMaxTransactionAmount;
      bool public tradingActive = false; 

      mapping (address => bool) private _isLiqPool;
      mapping (address => uint256) _balances;
      mapping (address => mapping (address => uint256)) private _allowances;
      mapping (address => bool) public isFeeExempt;

   

      ////antibot logic

        bool public antiBotEnabled=true;
     	mapping (address => bool) public excludedFromAntiBot;
	    mapping (address => uint256) private _lastSwapBlock;



    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        isFeeExempt[address(this)] = true;
      _isLiqPool[_pair] = true;
         
         
           uint256 _buyTax = 7;
           uint256 _sellTax = 11;
           sellTax = _sellTax;
           buyTax = _buyTax; 


         maxTransactionAmount = (totalSupply() * 2) / 100 ;          // 2% from total supply maxTransactionAmountTxn
        maxWallet = (totalSupply() * 3) / 100;                  /// 3% from total supply maxWallet


         taxWallet = address(0x87f87f2250A82122c865e6D7D00e4452c5BEA52b);


              excludeFromMaxTransaction(address(router), true);
              excludeFromMaxTransaction(address(pair), true);
              excludeFromMaxTransaction(address(taxWallet), true);
              excludeFromMaxTransaction(address(owner), true);
    



              isFeeExempt[taxWallet] = true;   
              isFeeExempt[msg.sender] = true;




        _balances[taxWallet] = _totalSupply;
        emit Transfer(address(0), taxWallet, _totalSupply);
    }

    receive() external payable {}
  function name() public pure override returns (string memory) {
    return _name;
}
function symbol() external pure override returns (string memory) {
    return _symbol;
}
    function decimals() public pure override returns (uint8) {
    return _decimals;
}

    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function isCont(address addr) internal view returns (bool) {uint size; assembly { size := extcodesize(addr) } return size > 0; }
    function setisfeeExempt(address _address, bool _enabled) external onlyOwner {isFeeExempt[_address] = _enabled;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(address(0)));}
 

    function preTxCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > uint256(0), "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        preTxCheck(sender, recipient, amount);

           if (!tradingActive) {
            require(
                isFeeExempt[sender] || isFeeExempt[recipient],
                "Trading is not active."
            );
        }

             if ( antiBotEnabled ) { 
                
                checkAntiBot(sender, recipient); 
                }

        





       if (limitsInEffect) {
            if (
                sender != owner &&
                recipient != owner &&
                recipient != address(0) &&
                recipient != address(0xdead)
            ) {
             

          

                //when buy
                if (
                    sender==pair &&
                    !_isExcludedMaxTransactionAmount[recipient]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(recipient) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    recipient==pair &&
                    !_isExcludedMaxTransactionAmount[sender]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[recipient]) {
                    require(
                        amount + balanceOf(recipient) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

  


    
         if (sender != owner && recipient != owner) {

            uint256 contractTokenBalance = balanceOf(address(this));
        
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
 
            if (canSwap && !swapping && sender != pair && !isFeeExempt[sender] && !isFeeExempt[recipient]) {
                swapping = true;
                taxSwap(contractTokenBalance);
                swapping = false;
            }
        }




        _balances[sender] = _balances[sender].sub(amount);

         bool takeFee = true;


 
        //Transfer Tokens
        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            takeFee = false;
        }
       
        
            if(takeFee) {
        	uint256 fees ;

             if (_isLiqPool[recipient] && sellTax > 0) {
                fees = amount.mul(sellTax).div(100);
               
            }
               // on buy
            else if (_isLiqPool[sender] && buyTax > 0) {
                fees = amount.mul(buyTax).div(100);
                
            }


        	

              _balances[address(this)] = _balances[address(this)].add(fees);
               emit Transfer(sender, address(this), fees);
      
              amount = amount.sub(fees);
        } 
    
        _balances[recipient] = _balances[recipient].add(amount);
    
        emit Transfer(sender, recipient, amount);


    }




    function taxSwap(uint256 tokenAmount) private {
        // generate the  pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            taxWallet,
            block.timestamp 
        );
    }





      	function checkAntiBot(address sender, address recipient) internal {
		if ( _isLiqPool[sender] && !excludedFromAntiBot[recipient] ) { //buy transactions
			require(_lastSwapBlock[recipient] < block.number, "AntiBot triggered");
			_lastSwapBlock[recipient] = block.number;
		} else if ( _isLiqPool[recipient] && !excludedFromAntiBot[sender] ) { //sell transactions
			require(_lastSwapBlock[sender] < block.number, "AntiBot triggered");
			_lastSwapBlock[sender] = block.number;
		}
	}



       function excludeFromAntiBot(address wallet, bool isExcluded) external onlyOwner {
		if (!isExcluded) 
		excludedFromAntiBot[wallet] = isExcluded;
	}


       function enableAntiBot(bool isEnabled) external onlyOwner {
	  
      
      	antiBotEnabled = isEnabled;
	     
         
         }

              // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
             
        require(!tradingActive, "Cannot re-enable trading");
        tradingActive = true;
      
    }

        // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

           function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

       function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

 
    function mint(address to, uint256 amount) public onlyOwner {
        _createInitialSupply(to, amount);
      }
   


      function updateBuyTax(
        uint256 __buytax
       
    ) external onlyOwner {
        buyTax = __buytax;
    
        require(buyTax <= 20, "Must keep fees at 20% or less");
    }

    function updateSellTax(
        uint256 __buytax
     
    ) external onlyOwner {
        sellTax = __buytax;
      
        require(sellTax <= 20, "Must keep fees at 20% or less");
    }
            function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
       require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e9,
            "Cannot set maxTxn lower than 0.5%"
        );
        maxTransactionAmount = newNum * (10**9);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
           require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e9,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**9);
        
    }

      function updateSwapTokensAtAmount(uint256 newNum) public onlyOwner{
  	    swapTokensAtAmount = newNum * (10**9);
  	}

    

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Function to withdraw tokens from the contract
    function withdrawTokens(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be the zero address");
        require(to != address(0), "Withdrawal address cannot be the zero address");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "Insufficient token balance in contract");

        bool sent = IERC20(tokenAddress).transfer(to, amount);
        require(sent, "Token transfer failed");
    }

    // Function to withdraw Ether from the contract
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance in contract");
        payable(owner).transfer(amount);
    }

}
