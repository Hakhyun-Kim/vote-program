FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    libudev-dev \
    libusb-1.0-0-dev \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# Install Solana CLI
RUN sh -c "$(curl -sSfL https://release.solana.com/v1.17.0/install)"
ENV PATH="/root/.local/share/solana/install/active_release/bin:$PATH"

# Install Anchor CLI using cargo (more reliable)
RUN cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
RUN avm install latest
RUN avm use latest
ENV PATH="/root/.cargo/bin:$PATH"

# Verify installations (will be done in startup script)

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Install Node.js dependencies
RUN npm install

# Build the program (will be done in startup script)

# Expose port for Solana validator
EXPOSE 8899

# Copy and set up startup script
COPY setup-docker.sh /app/setup-docker.sh
RUN chmod +x /app/setup-docker.sh

# Create directory for wallet
RUN mkdir -p /root/.config/solana

# Default command
CMD ["/app/setup-docker.sh"] 