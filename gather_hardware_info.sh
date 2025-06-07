#!/bin/bash

OUTPUT_FILE="system_info_report.txt"
echo "Gathering system hardware information..." > "$OUTPUT_FILE"
echo "=========================================" >> "$OUTPUT_FILE"

echo -e "\n1. Network Interface Names" >> "$OUTPUT_FILE"
ip link >> "$OUTPUT_FILE"

echo -e "\n2. Processor Model Name, Cores, and Speed" >> "$OUTPUT_FILE"
lscpu | grep -E 'Model name|Socket|Thread|Core|CPU\(s\)|MHz' >> "$OUTPUT_FILE"

echo -e "\n3. Memory Size with Manufacturer Information" >> "$OUTPUT_FILE"
sudo dmidecode --type memory | grep -E 'Size:|Manufacturer:|Part Number:|Speed:' >> "$OUTPUT_FILE"

echo -e "\n4. Disk Drive Device Names and Model Names" >> "$OUTPUT_FILE"
lsblk -d -o NAME,MODEL,SIZE >> "$OUTPUT_FILE"

echo -e "\n5. Video Card Model Name" >> "$OUTPUT_FILE"
lspci | grep -i vga >> "$OUTPUT_FILE"

echo -e "\nDone! Output saved to $OUTPUT_FILE"
