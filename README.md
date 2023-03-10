# bvr2mp4
Convert proprietary Blue Iris AVC (h.264) .bvr files to .mp4 files.  **At present these scripts do not retain audio.**

bvr2mp4.sh searches a directory for .bvr files and quickly remuxes the .bvr files to .mp4.

compressbvr.sh searches a directory for .bvr files and then compresses based on user input. This tool is rough at the moment and only targets constant bit rate.  It does support x264, x265, as well as Nvidia and Intel's h264 hardware encoding.
