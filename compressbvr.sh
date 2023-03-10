#!/bin/bash

### This script is FAR from well tested. Use at your own risk. ###

# Set file extensions to search for and set output file extension.
input_ext=".bvr"
output_ext=".mp4"

# Prompt user for compression rate.
echo "Please enter the compression rate, this simply sets the output bitrate to a percentage of the original bitrate, this is NOT CQ or CRF. Please enter (0-100): "
read compression_rate

# Set encoder.
while true; do
  echo "Please enter the encoding method (1: CPU x264 encoding, 2: CPU x265 encoding 3: Nvidia NVENC h264, 4: Intel QuickSync h264): "
  read encoding_method
  if [ -n "$encoding_method" ] && [ "$encoding_method" -ge 1 ] && [ "$encoding_method" -le 3 ]; then
    break
  else
    echo "Invalid encoding method selected. Please try again."
  fi
done

# Create counter for failed files.
fail_count=0

# Find all input files ending with chosen extension and process.
for input_file in $(find . -name "*$input_ext"); do
  # Use ffprobe to find input file bitrate.
  bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$input_file")
  # Multiply the bitrate by the compression rate.
  bitrate=$(echo "$bitrate * $compression_rate / 100" | bc)
  # Use ffprobe to find input file frame rate.
  fps=$(ffprobe -probesize 40M -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$input_file")
  # Convert fractional frame rates to decimal for ffmpeg
  if [[ $fps == *"/"* ]]; then
    fps=$(echo "scale=2; $fps" | bc)
  fi
  # Remove input extension and switch to output extension.
  output_file=${input_file%$input_ext}$output_ext
  # Use ffmpeg to convert the file to usable mp4 format
  case $encoding_method in
    1)
      ffmpeg -probesize 40M -framerate "$fps" -i "$input_file" -b:v "$bitrate"k -vcodec libx264 -preset slow -profile:v high -level:v 4.2 -movflags +faststart -an "${output_file}"
      ;;
    2)
      ffmpeg -probesize 40M -framerate "$fps" -i "$input_file" -b:v "$bitrate"k -vcodec libx265 -preset medium -movflags +faststart -an "${output_file}"
      ;;
    3)
      ffmpeg -probesize 40M -framerate "$fps" -i "$input_file" -b:v "$bitrate"k -vcodec h264_nvenc -preset medium -tune film -movflags +faststart -an "${output_file}"
      ;;
    4)
      ffmpeg -probesize 40M -framerate "$fps" -i "$input_file" -b:v "$bitrate"k -vcodec h264_qsv -movflags +faststart -an "${output_file}"
      ;;
  esac
  
  # Check if ffmpeg failed.
  if [ $? -ne 0 ]; then
    fail_count=$((fail_count+1))
    echo "Error converting $input_file. Skipping file."
  else
  # If ffmpeg runs successfully, reset consecutive failed counter to zero and delete the input file
    fail_count=0
    rm "$input_file"
  fi
  
  # If 5 consecutive files fail, print a warning and stop the script.
  if [ "$fail_count" -ge 5 ]; then
    echo "Warning: 5 consecutive files have failed to convert. Stopping script."
    exit 1
  fi
done
