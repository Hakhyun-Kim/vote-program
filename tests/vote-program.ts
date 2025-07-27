import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { VoteProgram } from "../target/types/vote_program";
import { expect } from "chai";

describe("vote-program", () => {
  // Configure the client to use the local cluster
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.VoteProgram as Program<VoteProgram>;

  // Test data
  const testUrl = "https://example.com";
  const testUrl2 = "https://another-example.com";

  // Helper function to get vote account PDA
  const getVoteAccount = (url: string) => {
    return anchor.web3.PublicKey.findProgramAddressSync([
      Buffer.from(url)
    ], program.programId)[0];
  };

  describe("Program Initialization", () => {
    it("Should initialize a new vote account", async () => {
      const voteAccount = getVoteAccount(testUrl);

      // Initialize the vote account
      const tx = await program.methods
        .initialize(testUrl)
        .accounts({
          payer: provider.wallet.publicKey,
          voteAccount,
          systemProgram: anchor.web3.SystemProgram.programId,
        })
        .rpc();

      console.log("Transaction signature:", tx);

      // Fetch and verify the vote account state
      const voteState = await program.account.voteState.fetch(voteAccount);
      
      expect(voteState.score).to.equal(0);
      expect(voteState.totalVotes).to.equal(0);
      expect(voteState.createdAt).to.be.greaterThan(0);
      expect(voteState.bump).to.be.a("number");

      console.log("Vote account initialized successfully");
      console.log("Score:", voteState.score.toString());
      console.log("Total votes:", voteState.totalVotes.toString());
      console.log("Created at:", new Date(voteState.createdAt * 1000).toISOString());
    });

    it("Should fail to initialize with empty URL", async () => {
      const voteAccount = getVoteAccount("");

      try {
        await program.methods
          .initialize("")
          .accounts({
            payer: provider.wallet.publicKey,
            voteAccount,
            systemProgram: anchor.web3.SystemProgram.programId,
          })
          .rpc();
        
        expect.fail("Should have thrown an error for empty URL");
      } catch (error) {
        expect(error.toString()).to.include("InvalidUrl");
      }
    });
  });

  describe("Voting Functionality", () => {
    let voteAccount: anchor.web3.PublicKey;

    beforeEach(async () => {
      // Initialize a fresh vote account for each test
      voteAccount = getVoteAccount(testUrl2);
      
      await program.methods
        .initialize(testUrl2)
        .accounts({
          payer: provider.wallet.publicKey,
          voteAccount,
          systemProgram: anchor.web3.SystemProgram.programId,
        })
        .rpc();
    });

    it("Should allow upvoting", async () => {
      // Cast an upvote
      const tx = await program.methods
        .upvote(testUrl2)
        .accounts({
          voteAccount,
        })
        .rpc();

      console.log("Upvote transaction signature:", tx);

      // Verify the vote state
      const voteState = await program.account.voteState.fetch(voteAccount);
      expect(voteState.score).to.equal(1);
      expect(voteState.totalVotes).to.equal(1);

      console.log("Upvote successful. New score:", voteState.score.toString());
    });

    it("Should allow downvoting", async () => {
      // Cast a downvote
      const tx = await program.methods
        .downvote(testUrl2)
        .accounts({
          voteAccount,
        })
        .rpc();

      console.log("Downvote transaction signature:", tx);

      // Verify the vote state
      const voteState = await program.account.voteState.fetch(voteAccount);
      expect(voteState.score).to.equal(-1);
      expect(voteState.totalVotes).to.equal(1);

      console.log("Downvote successful. New score:", voteState.score.toString());
    });

    it("Should handle multiple votes correctly", async () => {
      // Cast multiple votes
      await program.methods
        .upvote(testUrl2)
        .accounts({ voteAccount })
        .rpc();

      await program.methods
        .upvote(testUrl2)
        .accounts({ voteAccount })
        .rpc();

      await program.methods
        .downvote(testUrl2)
        .accounts({ voteAccount })
        .rpc();

      // Verify final state
      const voteState = await program.account.voteState.fetch(voteAccount);
      expect(voteState.score).to.equal(1); // 2 upvotes - 1 downvote
      expect(voteState.totalVotes).to.equal(3);

      console.log("Multiple votes successful. Final score:", voteState.score.toString());
    });

    it("Should fail to vote with empty URL", async () => {
      try {
        await program.methods
          .upvote("")
          .accounts({ voteAccount })
          .rpc();
        
        expect.fail("Should have thrown an error for empty URL");
      } catch (error) {
        expect(error.toString()).to.include("InvalidUrl");
      }
    });
  });

  describe("Account Management", () => {
    it("Should create separate vote accounts for different URLs", async () => {
      const url1 = "https://site1.com";
      const url2 = "https://site2.com";

      const voteAccount1 = getVoteAccount(url1);
      const voteAccount2 = getVoteAccount(url2);

      // Initialize both accounts
      await program.methods
        .initialize(url1)
        .accounts({
          payer: provider.wallet.publicKey,
          voteAccount: voteAccount1,
          systemProgram: anchor.web3.SystemProgram.programId,
        })
        .rpc();

      await program.methods
        .initialize(url2)
        .accounts({
          payer: provider.wallet.publicKey,
          voteAccount: voteAccount2,
          systemProgram: anchor.web3.SystemProgram.programId,
        })
        .rpc();

      // Verify they are different accounts
      expect(voteAccount1.toString()).to.not.equal(voteAccount2.toString());

      // Vote on both accounts
      await program.methods
        .upvote(url1)
        .accounts({ voteAccount: voteAccount1 })
        .rpc();

      await program.methods
        .downvote(url2)
        .accounts({ voteAccount: voteAccount2 })
        .rpc();

      // Verify independent state
      const state1 = await program.account.voteState.fetch(voteAccount1);
      const state2 = await program.account.voteState.fetch(voteAccount2);

      expect(state1.score).to.equal(1);
      expect(state2.score).to.equal(-1);

      console.log("Independent vote accounts working correctly");
    });
  });

  describe("Error Handling", () => {
    it("Should handle voting on non-existent account", async () => {
      const nonExistentAccount = anchor.web3.Keypair.generate();

      try {
        await program.methods
          .upvote("https://non-existent.com")
          .accounts({ voteAccount: nonExistentAccount.publicKey })
          .rpc();
        
        expect.fail("Should have thrown an error for non-existent account");
      } catch (error) {
        expect(error.toString()).to.include("Account does not exist");
      }
    });
  });
});
