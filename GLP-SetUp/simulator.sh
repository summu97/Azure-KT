#!/bin/bash

# Configuration: Adjust CPU and Memory load
CPU_LOAD=50        # percentage
MEMORY_MB=1024     # memory to consume in MB (~50% of 2GB RAM for example)

echo "🔧 Simulating ${CPU_LOAD}% CPU and allocating ${MEMORY_MB}MB memory..."

# Function to simulate CPU load
simulate_cpu_load() {
  CORES=$(nproc)
  LOAD_CORES=$(( CORES * CPU_LOAD / 100 ))
  echo "🧠 Using $LOAD_CORES core(s) out of $CORES to simulate ~${CPU_LOAD}% CPU load."

  for i in $(seq 1 $LOAD_CORES); do
    while :; do :; done &
  done
}

# Function to simulate memory usage
simulate_memory_load() {
  MEM_BYTES=$(( MEMORY_MB * 1024 * 1024 ))
  echo "💾 Allocating $MEMORY_MB MB RAM..."
  python3 -c "x = bytearray($MEM_BYTES); input('Press Enter to release memory...')" &
}

# Run the load functions
simulate_cpu_load
simulate_memory_load

echo "✅ Load started. Press Ctrl+C to stop."
wait



# chmod +x simulate_load.sh
# ./simulate_load.sh
# Use Ctrl+C in the terminal to stop the load.
# To kill the process: pkill -f simulate_load.sh; pkill -f "while :"; pkill -f python3

