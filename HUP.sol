// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./util.sol";
import "./HUPController.sol";

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IHUPController {
    function uniswapPair()   external view returns(address);
    function uniswapRouter() external view returns(address);

    function swapAndLiquify(uint256 contractTokenBalance) external;
    function handleAntiWhaleDump(
        uint256 amount, 
        address sender, 
        uint256 senderBalance, 
        address recipient, 
        uint256 threshold, 
        uint256 thresholdAllowance
    ) external;

    function lastTimeSold               (address account) external view returns(uint);
    function setLastTimeSold            (address account, uint l) external;

    function setTeamAddress             (address account) external;
    function releaseTeamFunds           () external;
    function releaseLiquidityFunds      () external;

    function isExcludedFromTaxFee        (address account) external view returns(bool);
    function isExcludedFromLiquidityFee  (address account) external view returns(bool);
    function isExcludedFromCharityFee    (address account) external view returns(bool);
    function isExcludedFromBurnFee       (address account) external view returns(bool);

    function isExcludedFromTaxFees       (address a, address b) external view returns(bool);
    function isExcludedFromLiquidityFees (address a, address b) external view returns(bool);
    function isExcludedFromCharityFees   (address a, address b) external view returns(bool);
    function isExcludedFromBurnFees      (address a, address b) external view returns(bool);

    function setExcludedFromTaxFee       (address account, bool e) external;
    function setExcludedFromLiquidityFee (address account, bool e) external;
    function setExcludedFromCharityFee   (address account, bool e) external;
    function setExcludedFromBurnFee      (address account, bool e) external;
}



contract HUP is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool)    private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;

    address[] private _excluded;
    address   public  _charityAddress;
    address   public  _controllerAddress;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 420000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tTaxFeeTotal;

    string private constant _name     = "HUP.LIFE";
    string private constant _symbol   = "HUP";
    uint8  private constant _decimals = 9;
    
    uint256 public  _taxFee       = 2; // 2% of every transaction is redistributed to holders
    uint256 public  _liquidityFee = 2; // 2% of every transaction is kept for liquidity
    uint256 public  _charityFee   = 2; // 2% of every transaction is kept for charity pool
    uint256 public  _burnFee      = 2; // 2% of every transaction is burned

    uint256 public  _maxTxAmount            = 210000000000000 * 10**9;
    uint256 public  _minBalanceForLiquidity = 210000000000 * 10**9;
    
    bool private _inSwapAndLiquify;
    bool public  _autoLiquidityEnabled = false;
    bool public  _isAntiWhaleEnabled   = false;

    event MinTokensBeforeSwapUpdated  (uint256 minTokensBeforeSwap);
    event AutoLiquidityEnabledUpdated (bool enabled);
    
    constructor (address cOwner) Ownable(cOwner) {
        _charityAddress = 0x395Fb03C5408c6e53aD6C06Ac7262FFebdb904E8;
        
        // ------------------------ Distribute initial supply ------------------------

        // 5% -> NFTs for Early Adopters
        _rOwned[0xeD79D546cF099Ca5E55234FD7964C58fd8486391] = 5789604461865809771178549250434395392663499233282028196000000000000000000000;

        // 5% -> Other Liquidity
        _rOwned[0xF53b3cA87AE0CA181359A4fffCD50778D48a3F10] = 5789604461865809771178549250434395392663499233282028196000000000000000000000;

        // 5% -> Legal Fees
        _rOwned[0x5c5b150D9A88a9E716719a0876093c54835AeB1A] = 5789604461865809771178549250434395392663499233282028196000000000000000000000;

        // 10% -> NFT Authenticator Awards
        _rOwned[0xDFef0466d155392c3d914E7ba573B18cA7d2da87] = 11579208923731619542357098500868790785326998466564056392000000000000000000000;

        // 10% -> Airdrops & Bounties
        _rOwned[0xA51630f5185A0adD62a44cC388Fe15a553AEd4d7] = 11579208923731619542357098500868790785326998466564056392000000000000000000000;

        // 15% -> Marketing / Misc / Admin
        _rOwned[0x0d1640B6c2900aC57CDc1Ca13320C3AD114dCEa1] = 17368813385597429313535647751303186177990497699846084588000000000000000000000;

        // 15% -> Research / Dev / Tech
        _rOwned[0x721dD99F28b4B98Db437222959910Af5DDF8b1cE] = 17368813385597429313535647751303186177990497699846084588000000000000000000000;

        // 35% -> Locked in contract for Pancakeswap Liquidity & Team Funds
        _rOwned[address(this)] = 40527231233060668398249844753040767748644494632974197372000000000000000000000;
        _tOwned[address(this)] = 147000000000000000000000;

        // ------------------------------------------------------------------------

        // deploy controller
        HUPController controllerContract = new HUPController(address(this), cOwner);
        _controllerAddress = address(controllerContract);
        
        // exclude system contracts from tax fee
        _isExcluded[address(this)]      = true;
        _isExcluded[_controllerAddress] = true;
        _isExcluded[_charityAddress]    = true;

        _excluded.push(address(this));
        _excluded.push(_controllerAddress);
        _excluded.push(_charityAddress);

        // approve controller for vesting
        _approve(address(this), _controllerAddress, 210000000000000000000000);
    }

    receive() external payable {}

    // BEP20
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    // STATE
    function totalTaxFees() public view returns (uint256) {
        return _tTaxFeeTotal;
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function setCharityAddress(address account) external onlyOwner {
        includeInReward(_charityAddress);
        excludeFromReward(account);
        _charityAddress = account;
    }
    function setControllerAddress(address account) external onlyOwner {
        _controllerAddress = account;
    }
    function setMaxTxPercent(uint256 p) external onlyOwner {
        _maxTxAmount = _tTotal.mul(p).div(100);
    }
    function setMinLiquidityPercent(uint256 p) external onlyOwner {
        _minBalanceForLiquidity = _tTotal.mul(p).div(100);
    }
    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }
    function setCharityFeePercent(uint256 charityFee) external onlyOwner {
        _charityFee = charityFee;
    }
    function setBurnFeePercent(uint256 burnFee) external onlyOwner {
        _burnFee = burnFee;
    }
    function setAntiWhaleEnabled(bool enabled) external onlyOwner {
        _isAntiWhaleEnabled = enabled;
    }
    function setAutoLiquidityEnabled(bool enabled) external onlyOwner {
        _autoLiquidityEnabled = enabled;
        emit AutoLiquidityEnabledUpdated(enabled);
    }

    // REFLECTION
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");

        (, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, tCharity, tBurn, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal         = _rTotal.sub(rAmount);
        _tTaxFeeTotal   = _tTaxFeeTotal.add(tAmount);
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {
            (, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getTValues(tAmount);
            uint256 currentRate = _getRate();
            (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, tCharity, tBurn, currentRate);

            return rAmount;

        } else {
            (, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getTValues(tAmount);
            uint256 currentRate = _getRate();
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tLiquidity, tCharity, tBurn, currentRate);

            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) public onlyOwner {
        require(_isExcluded[account], "Account is already excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    // TRANSFER
    function _transfer(address from, address to, uint256 amount ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        IHUPController hupController = IHUPController(_controllerAddress);

        /*
            - if sender holds more than 0.25% of total supply,
            they can only send max 10% of their balance per day.
        */
        if (_isAntiWhaleEnabled && !_isExcluded[from]) {
            hupController.handleAntiWhaleDump(
                amount, 
                from, 
                balanceOf(from), 
                to, 
                (totalSupply()).mul(25).div(10000), 
                10
            );
        }

        /*
            - swapAndLiquify will be initiated when token balance of controller contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */
        if (_autoLiquidityEnabled && from != address(this)) {
            uint256 controllerBalance = balanceOf(_controllerAddress);
            
            if (controllerBalance >= _maxTxAmount) {
                controllerBalance = _maxTxAmount;
            }
            
            bool isOverMinTokenBalance = controllerBalance >= _minBalanceForLiquidity;
            if (isOverMinTokenBalance && !_inSwapAndLiquify && from != hupController.uniswapPair()) {
                _inSwapAndLiquify = true;
                hupController.swapAndLiquify(_minBalanceForLiquidity);
                _inSwapAndLiquify = false;
            }
        }
        

        // ------ SET FEES
        uint256 _previousTaxFee       = _taxFee;
        uint256 _previousLiquidityFee = _liquidityFee;
        uint256 _previousCharityFee   = _charityFee;
        uint256 _previousBurnFee      = _burnFee;
        
        if (hupController.isExcludedFromTaxFee(from) || hupController.isExcludedFromTaxFee(to)) {
            _taxFee = 0;
        }
        if (hupController.isExcludedFromLiquidityFee(from) || hupController.isExcludedFromLiquidityFee(to)) {
            _liquidityFee = 0;
        }
        if (hupController.isExcludedFromCharityFee(from) || hupController.isExcludedFromCharityFee(to)) {
            _charityFee = 0;
        }
        if (hupController.isExcludedFromBurnFee(from) || hupController.isExcludedFromBurnFee(to)) {
            _burnFee = 0;
        }

        // ------ TRANSFER
        if (_isExcluded[from] && !_isExcluded[to]) {
            _transferFromExcluded(from, to, amount);

        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, amount);

        } else if (!_isExcluded[from] && !_isExcluded[to]) {
            _transferStandard(from, to, amount);

        } else if (_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, amount);

        } else {
            _transferStandard(from, to, amount);
        }

        // ------ RESTORE FEES
        _taxFee       = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee   = _previousCharityFee;
        _burnFee      = _previousBurnFee;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tCharity, tBurn, currentRate);

        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidityFee(tLiquidity, currentRate);
        _takeCharityFee(tCharity, currentRate);
        _reflectFee(rFee, tBurn.mul(currentRate), tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tCharity, tBurn, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidityFee(tLiquidity, currentRate);
        _takeCharityFee(tCharity, currentRate);
        _reflectFee(rFee, tBurn.mul(currentRate), tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tCharity, tBurn, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidityFee(tLiquidity, currentRate);
        _takeCharityFee(tCharity, currentRate);
        _reflectFee(rFee, tBurn.mul(currentRate), tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tCharity, tBurn, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidityFee(tLiquidity, currentRate);
        _takeCharityFee(tCharity, currentRate);
        _reflectFee(rFee, tBurn.mul(currentRate), tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 rBurn, uint256 tFee, uint256 tBurn) private {
        _rTotal       = _rTotal.sub(rFee).sub(rBurn);
        _tTaxFeeTotal = _tTaxFeeTotal.add(tFee);
        _tTotal       = _tTotal.sub(tBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tFee       = tAmount.mul(_taxFee).div(100);
        uint256 tLiquidity = tAmount.mul(_liquidityFee).div(100);
        uint256 tCharity   = tAmount.mul(_charityFee).div(100);
        uint256 tBurn      = tAmount.mul(_burnFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        tTransferAmount = tTransferAmount.sub(tCharity);
        tTransferAmount = tTransferAmount.sub(tBurn);
        return (tTransferAmount, tFee, tLiquidity, tCharity, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tCharity, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount     = tAmount.mul(currentRate);
        uint256 rFee        = tFee.mul(currentRate);
        uint256 rLiquidity  = tLiquidity.mul(currentRate);
        uint256 rCharity    = tCharity.mul(currentRate);
        uint256 rBurn       = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
        rTransferAmount = rTransferAmount.sub(rCharity);
        rTransferAmount = rTransferAmount.sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidityFee(uint256 tLiquidity, uint256 currentRate) private {
        if (tLiquidity <= 0) { return; }

        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[_controllerAddress] = _rOwned[_controllerAddress].add(rLiquidity);
        if (_isExcluded[_controllerAddress]) {
            _tOwned[_controllerAddress] = _tOwned[_controllerAddress].add(tLiquidity);
        }
    }

    function _takeCharityFee(uint256 tCharity, uint256 currentRate) private {
        if (tCharity <= 0) { return; }

        uint256 rCharity = tCharity.mul(currentRate);
        _rOwned[address(_charityAddress)] = _rOwned[address(_charityAddress)].add(rCharity);
        if (_isExcluded[address(_charityAddress)]) {
            _tOwned[address(_charityAddress)] = _tOwned[address(_charityAddress)].add(tCharity);
        }
    }

}


