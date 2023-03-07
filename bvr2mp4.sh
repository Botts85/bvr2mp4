#!/bin/bash

# Set file extensions to search for and set output file extension.
input_ext=".bvr"
output_ext=".mp4"

# Find all input files ending with chosen extension and process.
for input_file in $(find . -name "*$input_ext"); do
  # Use ffprobe to find input file frame rate.
  fps=$(ffprobe -probesize 103M -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$input_file")
  # Convert fractional frame rates to decimal for ffmpeg
  if [[ $fps == *"/"* ]]; then
    fps=$(echo "scale=2; $fps" | bc)
  fi
  # Remove input extension and switch to output extension.
  output_file=${input_file%$input_ext}$output_ext
  # Use ffmpeg to convert the file to usable mp4 format
  ffmpeg -probesize 40M -framerate "$fps" -i "$input_file" -vcodec copy -an -bsf:v h264_mp4toannexb "${output_file}"
  
  # Alert if ffmpeg failed.
  if [ $? -ne 0 ]; then
    echo "Error converting $input_file. Skipping file."
    continue
  fi
  
  # If ffmpeg runs successfully, delete the input file
  rm "$input_file"
done
