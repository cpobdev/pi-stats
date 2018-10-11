#!/bin/bash

set -e

# Open Weather API configs
# Checkout https://openweathermap.org/api for api/key info
OPENWEATHER_API_KEY=PUT KEY HERE
ZIP_CODE=90210

# InfluxDB server configs
INFLUX_HOST=localhost
INFLUX_PORT=8086


while [ 1 ]
do

  # Temperature
  cpuTemp0=$(cat /sys/class/thermal/thermal_zone0/temp)
  cpuTemp1=$(($cpuTemp0/1000))
  cpuTemp2=$(($cpuTemp0/10))
  cpuTempM=$(($cpuTemp2 % $cpuTemp1))
  CPU_TEMP=$cpuTemp1"."$cpuTempM
  CPU_TEMP=`echo "$CPU_TEMP * 1.8 + 32" | bc`

  GPU_TEMP=$(/opt/vc/bin/vcgencmd measure_temp | tr -cd '0-9.')
  GPU_TEMP=`echo "$GPU_TEMP * 1.8 + 32" | bc`

  EXT_TEMP=`curl 'http://api.openweathermap.org/data/2.5/weather?zip=$ZIP_CODE,us&APPID=$OPENWEATHER_API_KEY&units=imperial' | jq '.main.temp'`

  # Disk operations
  DISK=`df | grep '/dev/root'`
  DISK_USED=`echo $DISK | awk {'print $3'}`
  DISK_FREE=`echo $DISK | awk {'print $4'}`

  # CPU
  CPU_FREQ=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`

  echo "Curling pi-stats (to post to influx)..."

  curl -i -XPOST 'http://$INFLUX_HOST:$INFLUX_PORT/write?db=pi_stats' --data-binary 'temperature,type=CPU value='$CPU_TEMP'
  temperature,type=GPU value='$GPU_TEMP'
  disk,type=used value='$DISK_USED'
  disk,type=free value='$DISK_FREE'
  cpu_freq frequency='$CPU_FREQ

  echo "Curling outside temp (to post to influx)..."

  curl -i -XPOST 'http://$INFLUX_HOST:$INFLUX_PORT/write?db=smartthings' --data-binary 'temperature,deviceName=Outside value='$EXT_TEMP

  sleep 3

done
