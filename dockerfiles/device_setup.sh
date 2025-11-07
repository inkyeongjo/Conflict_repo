#!/bin/bash

##########################################################################
## Device Information
##########################################################################

TMPDIR=/tmp/

# Scan Xilinx FPGA user ids
if [ ! -f ${TMPDIR}/xfpga_user ]; then
  /opt/xilinx/xrt/bin/xbutil examine | grep 0000 | awk '{print $5}' | grep -oP 'inst=\K\d+' > ${TMPDIR}/xfpga_user
fi

# Scan Xilinx FPGA mgmt ids
if [ ! -f ${TMPDIR}/xfpga_mgmt ]; then
  /opt/xilinx/xrt/bin/xbmgmt examine | grep 0000 | awk '{print $5}' | grep -oP 'inst=\K\d+' > ${TMPDIR}/xfpga_mgmt
fi

# Read scanned file
mapfile -t USER_IDS < "${TMPDIR}/xfpga_user"
mapfile -t MGMT_IDS < "${TMPDIR}/xfpga_mgmt"

##########################################################################
## Commands
##########################################################################

# Output device information
echo "User IDs: ${USER_IDS[@]}"
echo "Management IDs: ${MGMT_IDS[@]}"

# Set the device info
for i in ${!USER_IDS[@]}
do
  echo "Setting device: /dev/dri/renderD${USER_IDS[$i]} and /dev/xfpga/xvc_pri.m${MGMT_IDS[$i]}.0"
done
