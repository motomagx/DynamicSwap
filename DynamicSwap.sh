#!/bin/bash
 
# Motomagx's DynamicSwap script
# https://github.com/motomagx/DynamicSwap

# Usage: Just run the script as root, with no arguments. The main swap must be deactivated to be relocated by DynamicSwap.
# By default, the script will trigger an additional 256MB SWAP block, if the total free memory (swap + RAM) is less than 512MB.
# The script will allocate blocks of 256MB in a row, and the blocks will be deactivated if there is 768MB (512 + 256MB) of RAM free, automatically.
# When deactivating the adjacent blocks, the data will be reloaded to RAM, eliminating subsequent lags during the loading of the data that would be in the disk swap.
# The script can also be used in conjunction with zram, which can dramatically reduce consumption and RAM in many cases.
# Note: do not use this script on a BTRFS file system, as this FS does not support swapping.

LOG_DIR="/var/log/dynamicswap"

rm -r /swap/*
mkdir -p "/swap/"
mkdir -p "$LOG_DIR"

LOW_LIMIT=524288       # 512MB (Value in KB)
UPPER_LIMIT=768432     # 768MB (Value in KB)
MAX_SWAP_VOLUMES=256   # As the name says.
SWAPPINESS_VALUE=20    # 

LOG_FILE="$LOG_DIR/`date '+%d-%m-%Y_%Hh%Mm%S'`.log"

# Automatic writing function in the log file:
echo1()
{
	echo "[`date '+%d/%m/%Y - %Hh%Mm%S'`] $1" >> "$LOG_FILE"
}

echo1 "Starting SmartCache script."

sysctl vm.swappiness=$SWAPPINESS_VALUE

while true
do
	TOTAL_PHYSICAL_RAM="`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`"
	FREE_PHYSICAL_RAM=`cat /proc/meminfo | grep MemFree | awk '{print $2}'`

	TOTAL_SWAP=`cat /proc/meminfo | grep SwapTotal | awk '{print $2}'`
	FREE_SWAP=`cat /proc/meminfo | grep SwapFree | awk '{print $2}'`

	TOTAL_RAM=`echo "$TOTAL_PHYSICAL_RAM + $TOTAL_SWAP" | bc`
	FREE_RAM=`echo "$FREE_PHYSICAL_RAM + $FREE_SWAP" | bc`

	# Create and enable 256MB adicional volume, if the lower limit is reached:
	
	if [ $FREE_RAM -lt $LOW_LIMIT ]
	then
		SWAP_VOLUMES=1
		SWAP_VOLUMES2=001
		SWAP_ZERO="00"
		
		while [ -f "/swap/swapfile_$SWAP_VOLUMES2" ]
		do
			SWAP_VOLUMES=$(($SWAP_VOLUMES+1))

			if [ $SWAP_VOLUMES -lt 100 ]
			then
				SWAP_ZERO="0"
			fi

			if [ $SWAP_VOLUMES -lt 10 ]
			then
				SWAP_ZERO="00"
			fi
			
			SWAP_VOLUMES2="$SWAP_ZERO$SWAP_VOLUMES"
		done
	
		# Merges the names with the corresponding block ID:
		SWAP_VOLUMES2="$SWAP_ZERO$SWAP_VOLUMES"
		
		# Debug:
		# cho "ZERO: $SWAP_ZERO VOLUE: $SWAP_VOLUMES NAME: $SWAP_VOLUMES2"
		
		if [ $SWAP_VOLUMES != $MAX_SWAP_VOLUMES ] # Limit to 256 swapfiles volumes
		then 
			SWAP_ZERO=""

			echo1 "Creating swapfile volume $SWAP_VOLUMES2"
			fallocate -l 256M "/swap/swapfile_$SWAP_VOLUMES2"
			chmod 0600 "/swap/swapfile_$SWAP_VOLUMES2"
			mkswap "/swap/swapfile_$SWAP_VOLUMES2"
			swapon "/swap/swapfile_$SWAP_VOLUMES2"
		fi
	fi

	# Remove unused swap volumes:
	
	if [ $FREE_RAM -gt $UPPER_LIMIT ]
	then
		DISABLE_VOLUMES=( `ls /swap/` )
	
		COUNTER=0
		
		while [ "x${DISABLE_VOLUMES[COUNTER]}" != "x" ]
		do
			COUNTER=$(($COUNTER+1))
		done

		COUNTER=$(($COUNTER-1))
	
		if [ $COUNTER != -1 ]
		then
			swapoff "/swap/${DISABLE_VOLUMES[COUNTER]}"
			SWAPOFF_STATUS="$?"
			
			if [ $SWAPOFF_STATUS == 0 ]
			then
				echo1 "Successfully disabled /swap/${DISABLE_VOLUMES[COUNTER]}"
				rm "/swap/${DISABLE_VOLUMES[COUNTER]}"
			else
				echo1 "Error: swapoff /swap/${DISABLE_VOLUMES[COUNTER]} returned $SWAPOFF_STATUS"
			fi
		fi
	fi

	COUNTER_VOLUMES=( `ls /swap/` )
	COUNTER=0
		
	while [ "x${COUNTER_VOLUMES[COUNTER]}" != "x" ]
	do
		COUNTER=$(($COUNTER+1))
	done

	echo "Total: $TOTAL_RAM KB - Free: $FREE_RAM KB - Swap volumes: $COUNTER"
	
	sleep 1s
done



