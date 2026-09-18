FROM ubuntu:24.04

# metadata
ARG VCS_REF
ARG BUILD_DATE
ARG IMAGE_NAME

# TODO: add io.aventus.image.source
LABEL io.aventus.image.authors="devops@aventus.io" \
	io.aventus.image.vendor="Aventus DAO Ltd" \
	io.aventus.image.title="${IMAGE_NAME}" \
	io.aventus.image.description="AvN parachain" \
	io.aventus.image.revision="${VCS_REF}" \
	io.aventus.image.created="${BUILD_DATE}" \
	io.aventus.image.documentation="https://github.com/Aventus-Network-Services/avn-node-parachain"

# NOTE: RUST_BACKTRACE was intentionally removed. Full backtraces can leak
# absolute paths, environment internals, and stack memory layouts in the
# production image. Operators who need one should set RUST_BACKTRACE at
# container runtime instead.
#
# Hardening recommendation (requires a one-time resolution): pin the base image
# to an immutable digest, e.g.
#   FROM ubuntu:24.04@sha256:<digest>
# instead of the floating `ubuntu:24.04` tag, so a new tag push can never
# silently change the base OS of a release.

# install tools and dependencies
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y \
	ca-certificates \
	curl \
	jq && \
	# apt cleanup
	apt-get autoremove -y && \
	apt-get clean && \
	find /var/lib/apt/lists/ -type f -not -name lock -delete; \
	# add user and link ~/.local/share/avn-parachain-collator to /data
	useradd --system --no-create-home --shell /usr/sbin/nologin -U avn-node && \
	mkdir -p /data /avn-node/.local/share && \
	chown -R avn-node:avn-node /data && \
	ln -s /data /avn-node/.local/share/avn-parachain-collator && \
	mkdir -p /specs

# add avn-node binary to the docker image
COPY target/release/avn-parachain-collator /usr/local/bin/
COPY target/release/wbuild/avn-parachain-runtime/avn_parachain_*.wasm /avn/wbuild/

USER avn-node

# check if executable works in this container
RUN /usr/local/bin/avn-parachain-collator --version

EXPOSE 30333 30334 9933 9944 9615
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/avn-parachain-collator"]
