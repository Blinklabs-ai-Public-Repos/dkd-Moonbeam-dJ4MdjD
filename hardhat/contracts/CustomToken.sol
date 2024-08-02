// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";

/**
 * @title CustomToken
 * @dev This contract implements an ERC20 token with vesting capabilities.
 */
contract CustomToken is ERC20, ERC20Burnable, Pausable, Ownable {
    uint256 private immutable _maxSupply;
    mapping(address => VestingWallet) private _vestingWallets;

    /**
     * @dev Constructor that sets the token name, symbol, and maximum supply.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param maxSupply_ The maximum supply of the token.
     */
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) ERC20(name_, symbol_) {
        require(maxSupply_ > 0, "Max supply must be greater than zero");
        _maxSupply = maxSupply_;
    }

    /**
     * @dev Returns the maximum supply of the token.
     * @return The maximum supply.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Pauses all token transfers.
     * @notice Can only be called by the contract owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     * @notice Can only be called by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Mints new tokens.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @notice Can only be called by the contract owner.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= _maxSupply, "Minting would exceed max supply");
        _mint(to, amount);
    }

    /**
     * @dev Creates a vesting schedule for a beneficiary.
     * @param beneficiary The address of the beneficiary.
     * @param amount The amount of tokens to be vested.
     * @param startTimestamp The start time of the vesting period.
     * @param durationSeconds The duration of the vesting period in seconds.
     * @notice Can only be called by the contract owner.
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) public onlyOwner {
        require(_vestingWallets[beneficiary] == VestingWallet(payable(address(0))), "Vesting schedule already exists for beneficiary");
        require(amount > 0, "Vesting amount must be greater than zero");
        require(durationSeconds > 0, "Vesting duration must be greater than zero");

        VestingWallet newVestingWallet = new VestingWallet(
            beneficiary,
            startTimestamp,
            durationSeconds
        );

        _vestingWallets[beneficiary] = newVestingWallet;
        _mint(address(newVestingWallet), amount);
    }

    /**
     * @dev Releases vested tokens for a beneficiary.
     * @param beneficiary The address of the beneficiary.
     */
    function releaseVestedTokens(address beneficiary) public {
        VestingWallet vestingWallet = _vestingWallets[beneficiary];
        require(address(vestingWallet) != address(0), "No vesting schedule found for beneficiary");

        uint256 releasable = vestingWallet.releasable(address(this));
        if (releasable > 0) {
            vestingWallet.release(address(this));
        }
    }

    /**
     * @dev Returns the vesting wallet address for a beneficiary.
     * @param beneficiary The address of the beneficiary.
     * @return The address of the vesting wallet.
     */
    function getVestingWallet(address beneficiary) public view returns (address) {
        return address(_vestingWallets[beneficiary]);
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     * @param from The address tokens are transferred from.
     * @param to The address tokens are transferred to.
     * @param amount The amount of tokens to be transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}