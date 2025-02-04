#!/bin/bash

# IP address of balkony solar meter (Shelly Plug S)
meter="http://192.168.178.XX"
# IP address of heating switch (Shelly Plug S)
switch="http://192.168.178.YY"
hyst_time=60 # 60s, a minute
status=/etc/.heating-status

# represent current status in file heating-off/heating-on
if [ -e $status/key-on ]; then
value=`curl -s $meter'/meter/0' | jq -r '.power'`
echo $value
if [ `echo $value '> 620'|bc` = 1 ] && [ `date +"%H"` -ge 10 ]; then
  if [ ! -e $status/heating-on ]; then
  touch $status/heating-on
  rm -f $status/heating-off
  fi 
fi
if [ `echo $value '< 580'|bc` = 1 ]; then
  if [ ! -e $status/heating-off ]; then
  touch $status/heating-off
  rm -f $status/heating-on
  fi
fi
fi

# hysteresis switching
currSeconds=$(date --utc +%s)
if [ -e $status/heating-on ]; then
lastOnSeconds=$(date --utc -r $status/heating-on +%s)
echo on $((currSeconds-lastOnSeconds))
if ((currSeconds-lastOnSeconds > $hyst_time)); then
  echo on
  curl -s "$switch/relay/0?turn=on" >/dev/null
fi
fi
if [ -e $status/heating-off ]; then
lastOffSeconds=$(date --utc -r $status/heating-off +%s)
echo off $((currSeconds-lastOffSeconds))
if ((currSeconds-lastOffSeconds > $hyst_time)); then 
  echo off
  curl -s "$switch/relay/0?turn=off" >/dev/null
fi
fi
# sensor data transfer for vzlogger
curl -s $meter'/meter/0' | jq -r '["power", .power] | join (" ")'
