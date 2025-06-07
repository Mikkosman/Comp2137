#!/bin/bash

OUTPUT="storage_report.txt"
echo "Linux Storage Report - $(date)" > "$OUTPUT"
echo "======================================" >> "$OUTPUT"

# 1. Mounted Local Disk Filesystems
echo -e "\n1. Mounted Local Disk Filesystems (Device Names & Mount Points):" >> "$OUTPUT"
df -hT | grep -vE 'tmpfs|devtmpfs' >> "$OUTPUT"

# 2. Mounted Network Filesystems
echo -e "\n2. Mounted Network Filesystems (NFS, CIFS, SMB):" >> "$OUTPUT"
mount | grep -Ei 'nfs|cifs|smb' >> "$OUTPUT"
if [ $? -ne 0 ]; then
  echo "No network filesystems are currently mounted." >> "$OUTPUT"
fi

# 3. Free Space in Home Directory Filesystem
echo -e "\n3. Free Space in Filesystem Holding Home Directory (~):" >> "$OUTPUT"
df -h ~ >> "$OUTPUT"

# 4. Space Used and File Count in Home Directory
echo -e "\n4. Space Used and Number of Files in Home Directory (~):" >> "$OUTPUT"
du -sh ~ >> "$OUTPUT"
echo -n "Number of files: " >> "$OUTPUT"
find ~ -type f 2>/dev/null | wc -l >> "$OUTPUT"

echo -e "\n✅ Storage report saved to $OUTPUT"
