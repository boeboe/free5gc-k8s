FROM boeboe/f5gc-build-base:v3.0.5 AS builder
FROM bitnami/minideb:stretch

ARG FREE5GC_VERSION=main

LABEL component="f5gc-upf"
LABEL description="Free5GC open source 5G Core Network, Stage 3"
LABEL version=${FREE5GC_VERSION}
LABEL maintainer="Bart Van Bos <bartvanbos@gmail.com>"
LABEL source-repo="https://github.com/boeboe/free5gc-k8s"

ENV F5GC_MODULE free5gc-upfd
ENV DEBIAN_FRONTEND noninteractive
ARG DEBUG_TOOLS
ENV DEBUG_TOOL_LIST "vim strace net-tools curl netcat bash tree tcpdump wget httpie dnsutils iproute2 iputils-ping"

# Install debug tools ~ 100MB (if DEBUG_TOOLS is set to true)
RUN if [ "$DEBUG_TOOLS" = "true" ] ; then apt-get update -y && apt-get install -y ${DEBUG_TOOL_LIST} ; fi

# Install UPF dependencies
RUN apt-get update \
    && apt-get install -y libmnl0 libyaml-0-2 iproute2 \
    && apt-get clean

# Set working dir
WORKDIR /free5gc
RUN mkdir -p ${F5GC_MODULE}/config/

# Copy executable and default configuration
COPY --from=builder /free5gc/${F5GC_MODULE} ./${F5GC_MODULE}/
COPY --from=builder /root/go/bin/httpdump /usr/local/bin

# Copy linked libs
COPY --from=builder /free5gc/libgtp5gnl.so.0 /usr/local/lib
COPY --from=builder /free5gc/liblogger.so /usr/local/lib

# Move to the executable location
WORKDIR /free5gc/${F5GC_MODULE}

# Update links
RUN ldconfig

ENTRYPOINT ["./free5gc-upfd" ]
CMD [ "-f", "../config/upfcfg.yaml" ]

# Exposed ports
EXPOSE 8805/udp
