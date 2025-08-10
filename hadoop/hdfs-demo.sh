#!/usr/bin/env bash
set -euo pipefail

echo "[hdfs-demo] Starting simple HDFS demo"

# Ensure home dir exists
if ! hdfs dfs -test -d /user/root; then
  echo "[hdfs-demo] Creating /user/root"
  hdfs dfs -mkdir -p /user/root || true
fi

# Create a temp local file
TMP_FILE=/tmp/hdfs-demo-$$.txt
echo "Sample content at $(date)" > "$TMP_FILE"

# Put file into HDFS
hdfs dfs -put -f "$TMP_FILE" /user/root/demo.txt

echo "[hdfs-demo] Listing /user/root"
hdfs dfs -ls /user/root || true

echo "[hdfs-demo] DFS report"
hdfs dfsadmin -report || true

rm -f "$TMP_FILE"
echo "[hdfs-demo] Done"
