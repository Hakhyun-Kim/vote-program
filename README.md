# Solana Voting Program

A decentralized voting system built on Solana where users can create vote accounts for URLs and cast upvotes/downvotes.

## Features

- **URL-based voting**: Each URL gets its own Program Derived Address (PDA) for storing vote data
- **Upvote/Downvote functionality**: Users can cast positive or negative votes
- **Vote tracking**: Maintains total votes and creation timestamps
- **Deterministic addressing**: Uses URL as seed for PDA generation

## Quick Start

### Option 1: Docker (Recommended)

The easiest way to run this program is using Docker:

1. **Install Docker Desktop** from [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

2. **Run the program**:
   ```bash
   # Windows
   setup.bat
   
   # Or manually
   docker-compose up --build
   ```

This will automatically:
- Install all required tools (Rust, Solana CLI, Anchor CLI, Node.js)
- Build the program
- Start a local Solana validator
- Run all tests

### Option 2: Manual Setup

If you prefer to install tools locally:

1. **Install required tools**:
   - [Node.js](https://nodejs.org/)
   - [Rust](https://rustup.rs/)
   - [Solana CLI](https://docs.solana.com/cli/install-solana-cli-tools)
   - [Anchor CLI](https://book.anchor-lang.com/getting_started/installation.html)

2. **Run the program**:
   ```bash
   # Windows
   run-without-docker.bat
   
   # Or manually
   npm install
   anchor build
   solana-test-validator &
   anchor test --skip-local-validator
   ```

## Program Instructions

### Initialize Vote Account
Creates a new PDA account for storing voting data for a specific URL.

```typescript
await program.methods
  .initialize("https://example.com")
  .accounts({
    payer: wallet.publicKey,
    voteAccount: voteAccountPDA,
    systemProgram: SystemProgram.programId,
  })
  .rpc();
```

### Cast Upvote
Increments the vote score for a URL.

```typescript
await program.methods
  .upvote("https://example.com")
  .accounts({
    voteAccount: voteAccountPDA,
  })
  .rpc();
```

### Cast Downvote
Decrements the vote score for a URL.

```typescript
await program.methods
  .downvote("https://example.com")
  .accounts({
    voteAccount: voteAccountPDA,
  })
  .rpc();
```

## Testing

The program includes comprehensive tests that demonstrate:
- Creating vote accounts for different URLs
- Upvoting and downvoting functionality
- Error handling for invalid inputs
- Independent vote tracking for different URLs

Run tests with:
```bash
anchor test
```

## Architecture

- **VoteState**: Account structure storing vote score, bump seed, creation timestamp, and total votes
- **PDA Derivation**: Uses URL bytes as seeds for deterministic address generation
- **Error Handling**: Custom error types for invalid URLs and integer overflow
- **Events**: Emits events for vote account creation and vote casting

## Development

### Prerequisites
- Rust 1.70+
- Solana CLI 1.17+
- Anchor CLI 0.30+
- Node.js 18+

### Building
```bash
anchor build
```

### Deploying
```bash
anchor deploy
```

## License

This project is licensed under the MIT License. 