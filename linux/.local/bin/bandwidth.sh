#!/bin/bash

# Get the network interface
INTERFACE=$(ip route show default | awk '/default/ {print $5}')

# Get the initial values
RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
sleep 1
RX2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

# Calculate the speeds
RXBPS=$((RX2 - RX1))
TXBPS=$((TX2 - TX1))

# Convert to human-readable format
RXKBPS=$(echo "scale=2; $RXBPS / 1024" | bc)
TXKBPS=$(echo "scale=2; $TXBPS / 1024" | bc)

echo " D: ${RXKBPS}KB/s U: ${TXKBPS}KB/s"
