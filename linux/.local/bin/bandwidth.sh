#!/bin/bash

# Get the network interface
INTERFACE=$(ip route show default | awk '/default/ {print $5}')

# Get the initial values
RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
sleep 1
RX2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

# Calculate the speeds in bytes per second
RXBPS=$((RX2 - RX1))
TXBPS=$((TX2 - TX1))

# Convert to megabits per second (Mbps) and round to 1 decimal place
RXMBPS=$(echo "scale=1; $RXBPS * 8 / 1024 / 1024" | bc)
TXMBPS=$(echo "scale=1; $TXBPS * 8 / 1024 / 1024" | bc)

echo "↓: ${RXMBPS} Mbps ↑: ${TXMBPS} Mbps"
