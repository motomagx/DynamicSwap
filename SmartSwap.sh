#!/bin/bash
 
# Motomagx OS SmartSwap script
# https://github.com/motomagx/SmartSwap

rm -r /swap/*
mkdir -p "/swap/"

LOW_LIMIT=524288
UPPER_LIMIT=768432
MAX_SWAP_VOLUMES=256

while true
do
	TOTAL_PHYSICAL_RAM="`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`"
	FREE_PHYSICAL_RAM=`cat /proc/meminfo | grep MemFree | awk '{print $2}'`

	TOTAL_SWAP=`cat /proc/meminfo | grep SwapTotal | awk '{print $2}'`
	FREE_SWAP=`cat /proc/meminfo | grep SwapFree | awk '{print $2}'`

	TOTAL_RAM=`echo "$TOTAL_PHYSICAL_RAM + $TOTAL_SWAP" | bc`
	FREE_RAM=`echo "$FREE_PHYSICAL_RAM + $FREE_SWAP" | bc`

	# Create and enable 256MB adicional volume:
	
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

		SWAP_VOLUMES2="$SWAP_ZERO$SWAP_VOLUMES"
		
		#echo "ZERO: $SWAP_ZERO VOLUE: $SWAP_VOLUMES NAME: $SWAP_VOLUMES2"
		
		if [ $SWAP_VOLUMES != $MAX_SWAP_VOLUMES ] # Limit to 256 swapfiles volumes
		then 
			SWAP_ZERO=""

			echo "Creating swapfile volume $SWAP_VOLUMES2"
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
				echo "Successfully disabled /swap/${DISABLE_VOLUMES[COUNTER]}"
				rm "/swap/${DISABLE_VOLUMES[COUNTER]}"
			else
				echo "Error: swapoff /swap/${DISABLE_VOLUMES[COUNTER]} returned $SWAPOFF_STATUS"
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




