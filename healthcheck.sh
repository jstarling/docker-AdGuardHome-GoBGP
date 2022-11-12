#!/bin/sh

# Check AdGuardHome is running
netstat -panu netstat -panu | grep 53 | grep -q AdGuardHome \
&& ( \
  # Check Loopback
  ip a s lo | grep -q ${LOOPBACK_V4} \
  && ( \
    echo -n "Injecting ${LOOPBACK_V4}/32... " \
    && gobgp global rib add ${LOOPBACK_V4}/32 \
    && echo "DONE" \
  ) || ( \
    echo -n "Withdrawing ${LOOPBACK_V4}/32... " \
    && gobgp global rib del ${LOOPBACK_V4}/32 \
    && echo "DONE" \
  ) \
) || exit 1
