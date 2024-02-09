FROM messense/rust-musl-cross:aarch64-musl as cargo-build

ENV DEBIAN_FRONTEND="noninteractive"
WORKDIR /home/rust/src
COPY . .

# Build the actual project
RUN cargo build --release
RUN musl-strip target/aarch64-unknown-linux-musl/release/onetun

# Build dumb-init
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        musl-tools \
    && cd dumb-init && CC=musl-gcc make

FROM busybox:stable
COPY --from=cargo-build /home/rust/src/target/aarch64-unknown-linux-musl/release/onetun /usr/local/bin/onetun
COPY --from=cargo-build /home/rust/src/dumb-init/dumb-init /usr/local/bin/dumb-init

# Run as non-root
USER 1000

ENTRYPOINT ["dumb-init", "/usr/local/bin/onetun"]
