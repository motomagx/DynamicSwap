Motomagx's DynamicSwap script
https://github.com/motomagx/DynamicSwap

Usage: Just run the script as root, with no arguments. The main swap must be deactivated to be relocated by DynamicSwap.

By default, the script will trigger an additional 256MB SWAP block, if the total free memory (swap + RAM) is less than 512MB.
The script will allocate blocks of 256MB in a row, and the blocks will be deactivated if there is 768MB (512 + 256MB) of RAM free, automatically.
When deactivating the adjacent blocks, the data will be reloaded to RAM, eliminating subsequent lags during the loading of the data that would be in the disk swap.

The script can also be used in conjunction with zram, which can dramatically reduce consumption and RAM in many cases.
