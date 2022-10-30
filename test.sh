#!/bin/bash

docker run \
  --cap-add NET_ADMIN \
  --env LOCAL_ADDRESS="10.64.64.55" \
  --env LOCAL_AS=64512 \
  --env LOOPBACK_V4="10.255.53.3" \
  --env REMOTE_ADDRESS="10.64.64.1" \
  --env REMOTE_AS=64512 \
  --env TZ="Etc/UTC" \
  --hostname resolver3 \
  --interactive \
  --ip 10.64.64.55 \
  --ip6 2a02:8012:5b3:64::55 \
  --name resolver3 \
  --network services_macvlan \
  --rm \
  --tty \
  adguard-gobgp:v0.107.16-v3.7.0-b8
