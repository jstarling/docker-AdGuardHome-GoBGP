
ARG ADGUARDHOME_VERSION=0.107.18

# Temporary Stage
FROM alpine:3.16.2 AS stage1

ARG CONFD_VERSION=0.16.0
ARG CONFD_SHA256=255d2559f3824dd64df059bdc533fd6b697c070db603c76aaf8d1d5e6b0cc334
ARG GOBGP_VERSION=3.8.0
ARG GOBGP_SHA256=9669426b62db942c21c42b4201ee5fdb616d0bb833b98b265d81aaec175fab1d
ARG S6_OVERLAY_VERSION=3.1.2.1
ARG S6_NOARCH_SHA256=cee89d3eeabdfe15239b2c5c3581d9352d2197d4fd23bba3f1e64bf916ccf496
ARG S6_X86_64_SHA256=6019b6b06cfdbb1d1cd572d46b9b158a4904fd19ca59d374de4ddaaa6a3727d5

# Prerequisites
RUN apk --no-cache add curl=7.83.1-r4

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# confd binary, download
RUN curl -L -s https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 -o confd-linux-amd64 \
  && echo "${CONFD_SHA256}  confd-linux-amd64" | sha256sum -c

# GoBGP binary, download & extract
RUN curl -L -s https://github.com/osrg/gobgp/releases/download/v${GOBGP_VERSION}/gobgp_${GOBGP_VERSION}_linux_amd64.tar.gz -o gobgp_${GOBGP_VERSION}_linux_amd64.tar.gz \
  && echo "${GOBGP_SHA256}  gobgp_${GOBGP_VERSION}_linux_amd64.tar.gz" | sha256sum -c \
  && tar xf gobgp_${GOBGP_VERSION}_linux_amd64.tar.gz

# s6 overlay
RUN mkdir /s6 \
  && curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz -o s6-overlay-noarch.tar.xz \
  && echo "${S6_NOARCH_SHA256}  s6-overlay-noarch.tar.xz" | sha256sum -c \
  && tar x -C /s6 -f s6-overlay-noarch.tar.xz \
  && curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz -o s6-overlay-x86_64.tar.xz \
  && echo "${S6_X86_64_SHA256}  s6-overlay-x86_64.tar.xz" | sha256sum -c \
  && tar x -C /s6 -f s6-overlay-x86_64.tar.xz

# Final Image
FROM adguard/adguardhome:v${ADGUARDHOME_VERSION}

# add dig
RUN apk --no-cache add bind-tools=9.6.33-r0

# s6 overlay
COPY --from=stage1 /s6 /

# AdGuard
RUN mkdir /etc/s6-overlay/s6-rc.d/adguard \
  && touch /etc/s6-overlay/s6-rc.d/user/contents.d/adguard
COPY s6-rc.d-adguard/* /etc/s6-overlay/s6-rc.d/adguard/

# confd
COPY --from=stage1 /confd-linux-amd64 /usr/local/bin/confd
RUN chmod 755 /usr/local/bin/confd \
  && mkdir -p /etc/confd/conf.d \
  && mkdir -p /etc/confd/templates \
  && mkdir /etc/s6-overlay/s6-rc.d/confd \
  && touch /etc/s6-overlay/s6-rc.d/user/contents.d/confd
COPY confd-conf.d/* /etc/confd/conf.d/
COPY confd-templates/* /etc/confd/templates/
COPY s6-rc.d-confd/* /etc/s6-overlay/s6-rc.d/confd/

# GoBGP
COPY --from=stage1 /gobgp /gobgpd /usr/bin/
RUN mkdir /etc/s6-overlay/s6-rc.d/gobgpd \
  && touch /etc/s6-overlay/s6-rc.d/user/contents.d/gobgpd
COPY s6-rc.d-gobgpd/* /etc/s6-overlay/s6-rc.d/gobgpd/

# Loopback
RUN mkdir /etc/s6-overlay/s6-rc.d/loopback \
  && touch /etc/s6-overlay/s6-rc.d/user/contents.d/loopback
COPY s6-rc.d-loopback/* /etc/s6-overlay/s6-rc.d/loopback/

# Healthcheck script
COPY healthcheck.sh /

ENV S6_KEEP_ENV 1

HEALTHCHECK --interval=30s --timeout=10s CMD /healthcheck.sh

ENTRYPOINT ["/init"]
