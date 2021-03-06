FROM boeboe/f5gc-build-base:v3.0.5 AS builder
FROM alpine:3.13

ARG FREE5GC_VERSION=main

LABEL component="f5gc-webui"
LABEL description="Free5GC open source 5G Core Network, Stage 3"
LABEL version=${FREE5GC_VERSION}
LABEL maintainer="Bart Van Bos <bartvanbos@gmail.com>"
LABEL source-repo="https://github.com/boeboe/free5gc-k8s"

ENV F5GC_MODULE webui
ARG DEBUG_TOOLS
ARG DEBUG_TOOL_LIST

# Install debug tools ~ 100MB (if DEBUG_TOOLS is set to true)
RUN if [ "$DEBUG_TOOLS" = "true" ] ; then apk add -U ${DEBUG_TOOL_LIST} ; fi

# Set working dir
WORKDIR /free5gc
RUN mkdir -p config/ webconsole/public

# Copy executable, frontend static files and default configuration
COPY --from=builder /free5gc/${F5GC_MODULE} ./webconsole
COPY --from=builder /free5gc/public ./webconsole/public
COPY --from=builder /root/go/bin/httpdump /usr/local/bin

# Move to the executable location
WORKDIR /free5gc/webconsole

# Config files volume
VOLUME [ "/free5gc/config" ]

ENTRYPOINT [ "./webui" ]

# WebUI uses the port 5000
EXPOSE 5000
