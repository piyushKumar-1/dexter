# Start from a Rust image

FROM ubuntu:16.04 as builder

# Update default packages
WORKDIR /dexter
RUN apt-get update

# Get Ubuntu packages
RUN apt-get install -y \
    build-essential \
    curl

# Update new packages
RUN apt-get update

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl && chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# Build only the dependencies to cache them
COPY ./Cargo.toml ./Cargo.toml

# Copy the source and build the application
COPY ./src ./src
RUN touch src/main.rs
RUN cargo build --release

# Final stage: use the binary from the previous stage
FROM debian:buster-slim
COPY --from=builder /dexter/target/release/dexter .
COPY --from=builder /usr/local/bin/kubectl /bin
RUN chmod +x /bin/kubectl
ENV RUST_BACKTRACE=full
EXPOSE 8080
CMD ["./dexter"]
