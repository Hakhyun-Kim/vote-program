use anchor_lang::prelude::*;

declare_id!("BazyiLGuNP3L6Pmex7w1ReP3gfVisRs4Krm2qwN1bRsf");

/// Solana Voting Program
/// 
/// This program implements a decentralized voting system where users can
/// create vote accounts for URLs and cast upvotes/downvotes. Each URL
/// gets its own Program Derived Address (PDA) for storing vote data.
#[program]
pub mod vote_program {
    use super::*;

    /// Initialize a new vote account for a given URL
    /// 
    /// This instruction creates a new PDA account to store voting data
    /// for the specified URL. The account is derived using the URL as
    /// a seed, ensuring deterministic address generation.
    /// 
    /// # Arguments
    /// * `ctx` - Context containing the accounts needed for initialization
    /// * `url` - The URL string to create a vote account for
    /// 
    /// # Returns
    /// * `Result<()>` - Success or error
    pub fn initialize(ctx: Context<Initialize>, url: String) -> Result<()> {
        // Validate URL is not empty
        require!(!url.is_empty(), VoteError::InvalidUrl);
        
        // Initialize the vote account
        ctx.accounts.initialize(&ctx.bumps)?;
        
        // Emit event for tracking
        emit!(VoteAccountCreated {
            url: url.clone(),
            vote_account: ctx.accounts.vote_account.key(),
            payer: ctx.accounts.payer.key(),
        });

        Ok(())
    }

    /// Cast an upvote for a given URL
    /// 
    /// Increments the vote score for the specified URL's vote account.
    /// 
    /// # Arguments
    /// * `ctx` - Context containing the vote account
    /// * `url` - The URL string to upvote
    /// 
    /// # Returns
    /// * `Result<()>` - Success or error
    pub fn upvote(ctx: Context<Vote>, url: String) -> Result<()> {
        // Validate URL is not empty
        require!(!url.is_empty(), VoteError::InvalidUrl);
        
        // Perform the upvote
        ctx.accounts.upvote()?;
        
        // Emit event for tracking
        emit!(VoteCast {
            url,
            vote_account: ctx.accounts.vote_account.key(),
            vote_type: VoteType::Upvote,
            new_score: ctx.accounts.vote_account.score,
        });

        Ok(())
    }

    /// Cast a downvote for a given URL
    /// 
    /// Decrements the vote score for the specified URL's vote account.
    /// 
    /// # Arguments
    /// * `ctx` - Context containing the vote account
    /// * `url` - The URL string to downvote
    /// 
    /// # Returns
    /// * `Result<()>` - Success or error
    pub fn downvote(ctx: Context<Vote>, url: String) -> Result<()> {
        // Validate URL is not empty
        require!(!url.is_empty(), VoteError::InvalidUrl);
        
        // Perform the downvote
        ctx.accounts.downvote()?;
        
        // Emit event for tracking
        emit!(VoteCast {
            url,
            vote_account: ctx.accounts.vote_account.key(),
            vote_type: VoteType::Downvote,
            new_score: ctx.accounts.vote_account.score,
        });

        Ok(())
    }
}

/// Context for initializing a new vote account
#[derive(Accounts)]
#[instruction(url: String)]
pub struct Initialize<'info> {
    /// The account paying for the transaction and account creation
    #[account(mut)]
    pub payer: Signer<'info>,
    
    /// The vote account to be created (PDA)
    #[account(
        init,
        payer = payer,
        seeds = [url.as_bytes().as_ref()],
        bump,
        space = VoteState::INIT_SPACE
    )]
    pub vote_account: Account<'info, VoteState>,
    
    /// The system program for account creation
    pub system_program: Program<'info, System>,
}

impl<'info> Initialize<'info> {
    /// Initialize the vote account with default values
    /// 
    /// # Arguments
    /// * `bumps` - The bump seeds for PDA derivation
    /// 
    /// # Returns
    /// * `Result<()>` - Success or error
    pub fn initialize(&mut self, bumps: &InitializeBumps) -> Result<()> {
        self.vote_account.score = 0;
        self.vote_account.bump = bumps.vote_account;
        self.vote_account.created_at = Clock::get()?.unix_timestamp;
        self.vote_account.total_votes = 0;

        Ok(())
    }
}

/// Context for casting votes (upvote/downvote)
#[derive(Accounts)]
#[instruction(url: String)]
pub struct Vote<'info> {
    /// The vote account to modify (PDA)
    #[account(
        mut,
        seeds = [url.as_bytes().as_ref()],
        bump = vote_account.bump,
    )]
    pub vote_account: Account<'info, VoteState>,
}

impl<'info> Vote<'info> {
    /// Increment the vote score
    /// 
    /// # Returns
    /// * `Result<()>` - Success or error
    pub fn upvote(&mut self) -> Result<()> {
        // Check for integer overflow
        self.vote_account.score = self.vote_account.score
            .checked_add(1)
            .ok_or(VoteError::Overflow)?;
        
        self.vote_account.total_votes = self.vote_account.total_votes
            .checked_add(1)
            .ok_or(VoteError::Overflow)?;

        Ok(())
    }

    /// Decrement the vote score
    /// 
    /// # Returns
    /// * `Result<()>` - Success or error
    pub fn downvote(&mut self) -> Result<()> {
        // Check for integer overflow
        self.vote_account.score = self.vote_account.score
            .checked_sub(1)
            .ok_or(VoteError::Overflow)?;
        
        self.vote_account.total_votes = self.vote_account.total_votes
            .checked_add(1)
            .ok_or(VoteError::Overflow)?;

        Ok(())
    }
}

/// Vote account state structure
#[account]
#[derive(InitSpace)]
pub struct VoteState {
    /// Current vote score (can be negative)
    pub score: i64,
    /// PDA bump seed
    pub bump: u8,
    /// Timestamp when the account was created
    pub created_at: i64,
    /// Total number of votes cast (upvotes + downvotes)
    pub total_votes: u64,
}

/// Custom error types for the voting program
#[error_code]
pub enum VoteError {
    #[msg("URL cannot be empty")]
    InvalidUrl,
    #[msg("Integer overflow occurred")]
    Overflow,
}

/// Vote type enumeration for events
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq)]
pub enum VoteType {
    Upvote,
    Downvote,
}

/// Event emitted when a vote account is created
#[event]
pub struct VoteAccountCreated {
    pub url: String,
    pub vote_account: Pubkey,
    pub payer: Pubkey,
}

/// Event emitted when a vote is cast
#[event]
pub struct VoteCast {
    pub url: String,
    pub vote_account: Pubkey,
    pub vote_type: VoteType,
    pub new_score: i64,
}