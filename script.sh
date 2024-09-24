#!/bin/bash
#set fan mode to "full"
ipmitool raw 0x30 0x45 0x01 0x01
##set fans in "system" zone
#ipmitool raw 0x30 0x70 0x66 0x01 0x00
##set fans in "peripheral" zone
#ipmitool raw 0x30 0x70 0x66 0x01 0x01

# Set the minimum and maximum fan speeds (in hexadecimal)
# 64 = 100% | 16 = 25% | 6 ~= 10%
min_fan_speed=4
#min_fan_speed=$1
max_fan_speed=32
#max_fan_speed=$2

# Set the initial fan speed (in hexadecimal)
ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x$min_fan_speed
ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x$min_fan_speed
fan_speed=$min_fan_speed

# Set the fan speed increment (in hexadecimal)
fan_speed_inc=4

# Set how often to check and update (in seconds)
ramp_up_frequency=5
ramp_down_frequency=15


# Set the desired CPU temperature (in degrees Celsius)
desired_temp=60
#desired_temp=$3

#Adds a few-degree buffer to when the fans start ramping down
temp_buffer=5

while ((1)) ; do
        #Get CPU temperature readout
        cpu_temp=$(sensors | grep "Package id" | awk '{sum += $4} END {print int(sum/2)}')
        #Check if cpu temp > desired temp
        if [[ $cpu_temp -gt $desired_temp ]]; then
                #Check if value will go over max fan speed
                if [[ $(($fan_speed + $fan_speed_inc)) -ge $max_fan_speed ]]; then
                        #Max fan speed
                        ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x$max_fan_speed
                        sleep 1
                        ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x$max_fan_speed
                else
                        #Increase fan speed
                        fan_speed=$(($fan_speed + $fan_speed_inc))
                        ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x$fan_speed
                        sleep 1
                        ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x$fan_speed
                fi
                #Echo useful information
                echo "CPU Temp: $(sensors | grep "Package id" | awk '{sum += $4} END {print int(sum/2)}')°c"
                echo "Fan Speed: $fan_speed/64 (MAX: $max_fan_speed)"
                sleep $ramp_up_frequency
        #If cpu temp is lower by the desired temp by the temp buffer, then it ramps down
        elif [[ $cpu_temp -lt $(($desired_temp - $temp_buffer)) ]]; then
                if [[ $(($fan_speed - $fan_speed_inc)) -le $min_fan_speed ]]; then
                        ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x$min_fan_speed
                        sleep 1
                        ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x$min_fan_speed
                else
                        fan_speed=$(($fan_speed - $fan_speed_inc))
                        ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x$fan_speed
                        sleep 1
                        ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x$fan_speed
                fi
                echo "CPU Temp: $(sensors | grep "Package id" | awk '{sum += $4} END {print int(sum/2)}')°c"
                echo "Fan Speed: $fan_speed/64 (MAX: $max_fan_speed)"
                sleep $ramp_down_frequency
        fi
done
