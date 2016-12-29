#!/bin/bash

count=15

for i in $(seq 0 $count); do
  touch /tmp/timing"$i"
done

for i in $(seq 0 $count); do
  cf push dora"$i" &
  pids[${i}]=$!
done

for pid in ${pids[*]}; do
  wait $pid;
done

for i in $(seq 0 $count); do
  cf stop dora"$i" &
  pids[${i}]=$!
done

for pid in ${pids[*]}; do
  wait $pid;
done

echo "$(date) Starting" > /tmp/timestamp

for i in $(seq 0 $count); do
  { time cf start dora"$i"; } 2> /tmp/timing"$i" &
  pids[${i}]=$!
done

for pid in ${pids[*]}; do
  wait $pid;
done

echo "$(date) Done" >> /tmp/timestamp

for i in $(seq 0 $count); do
  cf delete dora"$i" -f
done

tail /tmp/timing* | grep real >> /tmp/timestamp
