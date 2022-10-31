# AdGuardHome with GoBGP

To support anycasted DNS this adds GoBGP to AdGuardHome, using s6-overlay to supervise multiple processes in a single container. Utilised with MacVLAN to support real (non host) networking.

## Environment Variables

Environment Variable | Description
-------------------- | -------------
LOCAL_ADDRESS        | Address of interface inside the container
LOCAL_AS             | Autonomous System used by GoBGP inside the container
LOOPBACK_V4          | Loopback address*
REMOTE_AS            | Autonomous System used by the peer
REMOTE_ADDRESS       | Address of the peer

\* for the healthcheck defined in the Dockerfile to work this must be 10.255.53.*n*

```yaml
network:
  macvlan:
    exernal: true

services:
  resolver:
    cap_add:
      - NET_ADMIN
    container_name: resolver
    environment:
      - LOCAL_ADDRESS=10.53.0.2
      - LOCAL_AS=64512
      - LOOPBACK_V4=10.255.53.1
      - REMOTE_ADDRESS=10.53.0.1
      - REMOTE_AS=64512
      - TZ=Etc/UTC
    hostname: resolver
    image: adguard-gobgp:v0.107.16-v3.7.0-r1
    networks:
      macvlan:
        ipv4_address: 10.53.0.2
        ipv6_address: 2001:DB8:53::2
    restart: unless-stopped
    volumes:
      -
        source: resolver-conf
        target: /opt/adguardhome/conf
        type: volume
      -
        source: resolver-work
        target: /opt/adguardhome/work
        type: volume
        
version: "3.9"

volumes:
   resolver_conf:
   resolver_work:
```
