# Start from a Rust image
FROM rust:1.56 as builder

RUN USER=root cargo new --bin dexter
WORKDIR /dexter

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl && chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# Create a new empty shell project
# Copy manifests
COPY ./Cargo.toml ./Cargo.toml

# Build only the dependencies to cache them
RUN cargo build --release
RUN rm src/*.rs

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
CMD ["./dexter"]
