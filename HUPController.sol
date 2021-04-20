// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./util.sol";

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
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
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
        uint deadline
    ) external;
}



contract HUPController is Context {
    using SafeMath for uint256;

    address private _tokenContract;
    address private _tokenOwner;
    address public  _teamAddress;

    mapping (address => bool) private _isExcludedFromTaxFee;
    mapping (address => bool) private _isExcludedFromLiquidityFee;
    mapping (address => bool) private _isExcludedFromCharityFee;
    mapping (address => bool) private _isExcludedFromBurnFee;
    mapping (address => uint) public  _lastTimeSold;

    uint256 public _lastTeamFundsReleased;
    uint256 public _lastLiquidityFundsReleased;
    uint public _teamFundsReleasedCount;
    uint public _liquidityFundsReleasedCount;

    bool _inSwapAndLiquify = false;

    IUniswapV2Router02 public immutable _uniswapV2Router;
    address            public immutable _uniswapV2Pair;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);

    modifier onlyOwner() {
        require(_msgSender() == _tokenContract || _msgSender() == _tokenOwner, "Ownable: caller is not the owner");
        _;
    }

    constructor(address tokenContract, address tokenOwner) {
        _tokenContract = tokenContract;
        _tokenOwner    = tokenOwner;
        _teamAddress   = 0x295f89E0283c1bEfBE5e7cCb3594E566eEDB09A9;
        
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);

        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(tokenContract, uniswapV2Router.WETH());

        _uniswapV2Router = uniswapV2Router;

        // exclude system contracts from fees
        _isExcludedFromTaxFee[address(this)]        = true;
        _isExcludedFromLiquidityFee[address(this)]  = true;
        _isExcludedFromCharityFee[address(this)]    = true;
        _isExcludedFromBurnFee[address(this)]       = true;

        _isExcludedFromTaxFee[_tokenContract]       = true;
        _isExcludedFromLiquidityFee[_tokenContract] = true;
        _isExcludedFromCharityFee[_tokenContract]   = true;
        _isExcludedFromBurnFee[_tokenContract]      = true;
    }

    receive() external payable {}

    // UNISWAP
    function uniswapPair() public view returns(address) {
        return address(_uniswapV2Pair);
    }
    function uniswapRouter() public view returns(address) {
        return address(_uniswapV2Router);
    }

    // AUTO LIQUIDITY
    function swapAndLiquify(uint256 contractTokenBalance) external onlyOwner {
        if (_inSwapAndLiquify) { return; }
        _inSwapAndLiquify = true;

        // split contract balance into halves
        uint256 half      = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        /*
            capture the contract's current BNB balance.
            this is so that we can capture exactly the amount of BNB that
            the swap creates, and not make the liquidity event include any BNB
            that has been manually sent to the contract.
        */
        uint256 initialBalance = address(this).balance;

        // approve to cover all possible scenario
        IBEP20 HUPToken = IBEP20(_tokenContract);
        HUPToken.approve(address(_uniswapV2Router), contractTokenBalance);

        // swap tokens for BNB
        swapTokensForBnb(half);

        // this is the amount of BNB that we just swapped into
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        _inSwapAndLiquify = false;
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = _tokenContract;
        path[1] = _uniswapV2Router.WETH();

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            _tokenContract,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    // ANTI WHALE DUMP
    function handleAntiWhaleDump(uint256 amount, address sender, uint256 senderBalance, address recipient, uint256 threshold, uint256 thresholdAllowance) external onlyOwner {
        if (recipient == address(_uniswapV2Router) || recipient == address(_uniswapV2Pair)) {
            if (senderBalance > threshold) {
                require(amount < senderBalance.div(thresholdAllowance), "Sell amount is too high");
                require(block.timestamp.sub(_lastTimeSold[sender]) > 1 days, "You can only sell once per day");
            }
            _lastTimeSold[sender] = block.timestamp;
        }
    }
    function lastTimeSold(address account) public view returns(uint) {
        return _lastTimeSold[account];
    }
    function setLastTimeSold(address account, uint l) external onlyOwner {
        _lastTimeSold[account] = l;
    }

    // VESTING
    function setTeamAddress(address account) external onlyOwner {
        _teamAddress = account;
    }
    function releaseTeamFunds() external onlyOwner {
        require(_teamAddress != address(0), "Team address is not set");
        require(_teamFundsReleasedCount < 12, "Can't release any more team funds");
        require(block.timestamp - _lastTeamFundsReleased > 30 days, "Not enough time has passed to release team funds");

        IBEP20 HUPToken = IBEP20(_tokenContract);
        HUPToken.transferFrom(_tokenContract, _teamAddress, 3500000000000000000000);
        _lastTeamFundsReleased = block.timestamp;
        _teamFundsReleasedCount++;
    }
    function releaseLiquidityFunds() external onlyOwner {
        require(_liquidityFundsReleasedCount < 12, "Can't release any more liquidity funds");
        require(block.timestamp - _lastLiquidityFundsReleased > 1 weeks, "Not enough time has passed to release team funds");

        IBEP20 HUPToken = IBEP20(_tokenContract);
        HUPToken.transferFrom(_tokenContract, address(this), 8750000000000000000000);
        _lastLiquidityFundsReleased = block.timestamp;
        _liquidityFundsReleasedCount++;
    }

    // TAX FEE
    function isExcludedFromTaxFee(address account) public view returns(bool) {
        return _isExcludedFromTaxFee[account];
    }
    function isExcludedFromTaxFees(address a, address b) public view returns(bool) {
        return _isExcludedFromTaxFee[a] || _isExcludedFromTaxFee[b];
    }
    function setExcludedFromTaxFee(address account, bool e) external onlyOwner {
        _isExcludedFromTaxFee[account] = e;
    }

    // LIQUIDITY FEE
    function isExcludedFromLiquidityFee(address account) public view returns(bool) {
        return _isExcludedFromLiquidityFee[account];
    }
    function isExcludedFromLiquidityFees(address a, address b) public view returns(bool) {
        return _isExcludedFromLiquidityFee[a] || _isExcludedFromLiquidityFee[b];
    }
    function setExcludedFromLiquidityFee(address account, bool e) external onlyOwner {
        _isExcludedFromLiquidityFee[account] = e;
    }

    // CHARITY FEE
    function isExcludedFromCharityFee(address account) public view returns(bool) {
        return _isExcludedFromCharityFee[account];
    }
    function isExcludedFromCharityFees(address a, address b) public view returns(bool) {
        return _isExcludedFromCharityFee[a] || _isExcludedFromCharityFee[b];
    }
    function setExcludedFromCharityFee(address account, bool e) external onlyOwner {
        _isExcludedFromCharityFee[account] = e;
    }

    // BURN FEE
    function isExcludedFromBurnFee(address account) public view returns(bool) {
        return _isExcludedFromBurnFee[account];
    }
    function isExcludedFromBurnFees(address a, address b) public view returns(bool) {
        return _isExcludedFromBurnFee[a] || _isExcludedFromBurnFee[b];
    }
    function setExcludedFromBurnFee(address account, bool e) external onlyOwner {
        _isExcludedFromBurnFee[account] = e;
    }

}


