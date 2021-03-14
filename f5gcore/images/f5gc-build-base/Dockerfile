FROM golang:1.16.2-buster AS builder

ARG FREE5GC_VERSION=main

LABEL component="f5gc-build-base"
LABEL description="Free5GC open source 5G Core Network, Stage 3"
LABEL version=${FREE5GC_VERSION}
LABEL maintainer="Bart Van Bos <bartvanbos@gmail.com>"
LABEL source-repo="https://github.com/boeboe/free5gc-k8s"

RUN apt-get update
RUN apt-get -y install gcc cmake autoconf libtool pkg-config libmnl-dev libyaml-dev apt-transport-https ca-certificates libpcap-dev tree
RUN apt-get clean

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && apt-get install -y nodejs

RUN apt remove cmdtest yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq
RUN apt-get install -y yarn

# Get Free5GC
RUN cd $GOPATH/src \
    && git clone --recursive -j 33 -b ${FREE5GC_VERSION} https://github.com/free5gc/free5gc.git \
    && cd free5gc

COPY Makefile $GOPATH/src/free5gc/Makefile

# Patch Free5GC v3.0.4 (TODO: Separate it as Script files)
# 20201104_nasConvert: Temporary Fix to correspond for Mapped NSSAI which is have not been implemented in current free5gc
#   Ref: .
# 20201110_nrf_smf_selection_by_slice: SMF Selection by S-NSSAI in AMF have not been implemented in current free5gc
#   Ref: https://github.com/free5gc/free5gc/issues/103
# 20210314_adminPassword: Change the default webui password from free5gc to admin 
COPY patches/ $GOPATH/src/free5gc/patches/
RUN cd $GOPATH/src/free5gc && \
    cp patches/nrf/20201110_nrf_smf_selection_by_slice.patch NFs/nrf && \
    cp patches/webui/20210314_adminPassword.patch webconsole && \
    cd $GOPATH/src/free5gc/NFs/nrf && \
    git apply --ignore-whitespace 20201110_nrf_smf_selection_by_slice.patch && \
    cd $GOPATH/src/free5gc/webconsole && \
    git apply --ignore-whitespace 20210314_adminPassword.patch

# Build NFs (AMF, AUSF, N3IWF, NRF, NSSF, PCF, SMF, UDM, UDR, UPF)
RUN cd $GOPATH/src/free5gc \
    && make all

# Build WebUI
RUN cd $GOPATH/src/free5gc/webconsole \
    && CGO_ENABLED=0 go build -a -installsuffix nocgo -o webui -x server.go

# Get Httpdump
RUN go get github.com/hsiafan/httpdump

# Alpine is used for debug purpose. You can use scratch for a smaller footprint.
FROM alpine:3.13

ARG FREE5GC_VERSION=main

LABEL component="f5gc-build-base"
LABEL description="Free5GC open source 5G Core Network, Stage 3"
LABEL version=${FREE5GC_VERSION}
LABEL maintainer="Bart Van Bos <bartvanbos@gmail.com>"
LABEL source-repo="https://github.com/boeboe/free5gc-k8s"

WORKDIR /free5gc
RUN mkdir -p config/ support/TLS/ public && \
    apk add git go libpcap-dev && \
    go get github.com/hsiafan/httpdump

# Copy executables
COPY --from=builder /go/src/free5gc/bin/* ./
COPY --from=builder /go/src/free5gc/NFs/upf/build/bin/* ./
COPY --from=builder /go/src/free5gc/webconsole/webui ./

# Copy static files (webui frontend)
COPY --from=builder /go/src/free5gc/webconsole/public ./public

# Copy linked libs
COPY --from=builder /go/src/free5gc/NFs/upf/build/updk/src/third_party/libgtp5gnl/lib/libgtp5gnl.so.0 ./
COPY --from=builder /go/src/free5gc/NFs/upf/build/utlt_logger/liblogger.so ./

# Copy configuration files (not used for now)
COPY --from=builder /go/src/free5gc/config/* ./config/
COPY --from=builder /go/src/free5gc/NFs/upf/build/config/* ./config/

# Copy default certificates (not used for now)
COPY --from=builder /go/src/free5gc/support/TLS/* ./support/TLS/