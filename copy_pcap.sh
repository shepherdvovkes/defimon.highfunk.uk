#!/bin/bash

# Copy the PCAP file to a simpler name
cd /var/tmp

# Use find to locate the file and copy it
find . -name "*vovkes*" -name "*.pcap" -exec cp {} august17_capture.pcap \;

echo "File copied successfully"
ls -la august17_capture.pcap
