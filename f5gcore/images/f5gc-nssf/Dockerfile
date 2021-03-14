FROM boeboe/f5gc-build-base:v3.0.5 AS builder
FROM alpine:3.13

ARG FREE5GC_VERSION=main

LABEL component="f5gc-nssf"
LABEL description="Free5GC open source 5G Core Network, Stage 3"
LABEL version=${FREE5GC_VERSION}
LABEL maintainer="Bart Van Bos <bartvanbos@gmail.com>"
LABEL source-repo="https://github.com/boeboe/free5gc-k8s"

ENV F5GC_MODULE nssf
ARG DEBUG_TOOLS
ARG DEBUG_TOOL_LIST

# Install debug tools ~ 100MB (if DEBUG_TOOLS is set to true)
RUN if [ "$DEBUG_TOOLS" = "true" ] ; then apk add -U ${DEBUG_TOOL_LIST} ; fi

# Set working dir
WORKDIR /free5gc
RUN mkdir -p config/ log/ support/TLS/ ${F5GC_MODULE}/

# Copy executable and default certs
COPY --from=builder /free5gc/${F5GC_MODULE} ./${F5GC_MODULE}
COPY --from=builder /free5gc/support/TLS/${F5GC_MODULE}.pem ./support/TLS/
COPY --from=builder /free5gc/support/TLS/${F5GC_MODULE}.key ./support/TLS/
COPY --from=builder /root/go/bin/httpdump /usr/local/bin

# Move to the binary path
WORKDIR /free5gc/${F5GC_MODULE}

# Config files volume
VOLUME [ "/free5gc/config" ]

# Certificates (if not using default) volume
VOLUME [ "/free5gc/support/TLS" ]

ENTRYPOINT [ "./nssf" ]
CMD [ "-nssfcfg", "../config/nssfcfg.conf" ]

# Exposed ports
EXPOSE 29531
