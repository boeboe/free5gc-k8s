FROM golang:1.14.4-stretch AS builder

ARG FREE5GC_VERSION=main

LABEL component="f5gc-gnbsim"
LABEL description="Free5GC open source 5G Core Network, Stage 3"
LABEL version=${FREE5GC_VERSION}
LABEL maintainer="Bart Van Bos <bartvanbos@gmail.com>"
LABEL source-repo="https://github.com/boeboe/free5gc-k8s"

RUN apt-get update && \
    apt-get install -y gcc cmake autoconf libtool pkg-config libmnl-dev libyaml-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Get and Build GNBSIM
RUN cd $GOPATH/src && \
    git clone https://github.com/boeboe/gnbsim && \
    cd gnbsim && \
    make -j`nproc`

FROM bitnami/minideb:stretch

ARG FREE5GC_VERSION=main

LABEL component="f5gc-gnbsim"
LABEL description="Free5GC open source 5G Core Network, Stage 3"
LABEL version=${FREE5GC_VERSION}
LABEL maintainer="Bart Van Bos <bartvanbos@gmail.com>"
LABEL source-repo="https://github.com/boeboe/free5gc-k8s"

WORKDIR /gnbsim

# Copy executables
COPY --from=builder /go/src/gnbsim/example/example example
# COPY config/example.json example.json

ARG DEBUG_TOOLS
ENV DEBUG_TOOL_LIST "vim strace net-tools curl netcat bash tree tcpdump wget httpie dnsutils iproute2 iputils-ping"

RUN apt-get update -y && apt-get install -y iproute2 

# Install debug tools ~ 100MB (if DEBUG_TOOLS is set to true)
RUN if [ "$DEBUG_TOOLS" = "true" ] ; then apt-get update -y && apt-get install -y ${DEBUG_TOOL_LIST} ; fi


ENTRYPOINT ["./example"]
