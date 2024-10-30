# STX Vesting NFT Smart Contract

A programmable vesting NFT contract written in Clarity for the Stacks blockchain. This contract allows users to mint NFTs with customizable vesting periods and integrates STX payments for minting and level upgrades. The contract includes safety checks, enhanced validation, and utility settings for different NFT levels.

## Features

### Minting NFTs with Vesting Periods
- Users can mint NFTs with custom vesting periods.
- Minting requires a predefined STX payment.

### Token Level Up with STX Payments
- Token levels increase as blocks pass, based on the vesting period.
- Users can pay STX to manually upgrade levels when eligible.

### Utility Assignment by Level
- Each token level can have a custom utility string assigned.

### Ownership Transfers
- NFTs can be transferred between users securely.

### Contract Administration Functions
- Mint and level-up prices are adjustable by the contract owner.
- STX withdrawal functionality is provided to transfer STX out of the contract.
- Enhanced error handling ensures safe operation.

## Prerequisites
- Stacks CLI installed ([guide](https://docs.stacks.co/understand-stacks/cli)).
- A local or testnet Stacks node running.
- STX wallet for interacting with the blockchain.

## Contract Structure
- **NFT Minting**: Users mint tokens with vesting periods. STX transfer is required.
- **Level Up Logic**: Token levels increase automatically over time or via STX payments.
- **Utility Assignment**: Contract owner can set utilities for different token levels.
- **STX Management**: Allows contract owner to withdraw funds and adjust mint/level-up prices.

## Deployment Instructions

### Clone the Repository:
```bash
git clone <repository-url>
cd stx-vesting-nft
```

### Compile the Contract:
```bash
clarity-cli check ./stx-vesting-nft.clar
```

### Deploy the Contract:
Make sure you have a Stacks wallet address with sufficient STX balance.
```bash
clarity-cli launch <contract-name> ./stx-vesting-nft.clar <deployer-address> <network>
```

Example:
```bash
clarity-cli launch stx-vesting-nft ./stx-vesting-nft.clar SP3FBR2AGK... testnet
```

## Functions and Usage

### 1. Minting a Token
Mint a token by paying the mint price (100 STX by default) and setting a vesting period.
```clarity
(define-public (mint (vesting-period uint)))
```
**Parameters:**
- `vesting-period`: Number of blocks required for full vesting.

**Errors:**
- `err-invalid-params`: Vesting period must be greater than 0.
- `err-insufficient-funds`: Insufficient STX to cover mint price.

### 2. Update Token Level
Increase the token level based on the number of blocks passed since creation. Users must pay a level-up fee (default 50 STX).
```clarity
(define-public (update-token-level (token-id uint)))
```
**Parameters:**
- `token-id`: ID of the NFT to update.

**Errors:**
- `err-not-token-owner`: Only the owner can update the token.
- `err-insufficient-funds`: Insufficient STX for level-up.

### 3. Set Level Utility
Allows the contract owner to set a utility string for a specific token level.
```clarity
(define-public (set-level-utility (token-id uint) (level uint) (utility (string-ascii 256))))
```
**Parameters:**
- `token-id`: The NFT’s ID.
- `level`: Token level to set utility for.
- `utility`: Utility description as a string (ASCII, max 256 chars).

**Errors:**
- `err-owner-only`: Only the contract owner can set utilities.

### 4. Transfer Token Ownership
Transfer ownership of a token to another user.
```clarity
(define-public (transfer (token-id uint) (sender principal) (recipient principal)))
```
**Parameters:**
- `token-id`: ID of the NFT to transfer.
- `sender`: Current owner.
- `recipient`: New owner.

### 5. Set Mint and Level-Up Prices
The contract owner can change the mint and level-up prices.
```clarity
(define-public (set-mint-price (new-price uint)))
(define-public (set-level-up-price (new-price uint)))
```

### 6. Withdraw STX from Contract
Allows the contract owner to withdraw STX from the contract balance.
```clarity
(define-public (withdraw-stx (amount uint)))
```

### 7. Read-Only Functions
- **Get Last Token ID:**
```clarity
(define-read-only (get-last-token-id))
```
- **Get Token Owner:**
```clarity
(define-read-only (get-owner (token-id uint)))
```
- **Get Token URI:**
```clarity
(define-read-only (get-token-uri (token-id uint)))
```

## Error Codes
| Error Code | Description |
|------------|-------------|
| `u100`     | Only the contract owner can perform this operation. |
| `u101`     | User is not the owner of the token. |
| `u102`     | Invalid token ID. |
| `u103`     | Insufficient funds for operation. |
| `u104`     | Invalid parameters provided. |
| `u105`     | Amount provided is zero. |
| `u106`     | Unauthorized action. |

## Example Workflow

### Mint a Token:
1. Call the mint function with a vesting-period of 1000 blocks.
2. Pay 100 STX to the contract.

### Update Token Level:
1. After 500 blocks, call update-token-level to increase the token’s level.

### Assign Utility:
1. As the contract owner, assign utilities to different levels using set-level-utility.

### Transfer Ownership:
1. Transfer the NFT to another user with the transfer function.

## Security Features
- **Ownership Checks**: Ensures only the owner can update or transfer tokens.
- **STX Handling**: All STX transfers are validated to prevent loss of funds.
- **Overflow Protection**: Prevents unexpected behavior during level updates.
- **Role-Based Access**: Only the contract owner can adjust prices or withdraw funds.

## Testing

### Run Tests Locally:
```bash
clarity-cli test ./tests/stx-vesting-nft-test.clar
```

### Use Stacks Explorer:
Track transactions and contract interactions on the Stacks Explorer.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Conclusion
The STX Vesting NFT smart contract offers a flexible and secure way to manage token vesting with STX payments. It provides enhanced safety checks, custom utilities, and programmable logic to fit various use cases.