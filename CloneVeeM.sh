#!/bin/sh

###############################################################################
#
# CloneVeeM is a VM clone script for VMware ESXi 4.1.0 and 5.0.0
#
###############################################################################

clone() {

echo -n "Please enter target VM: "
read tgt1
vmemt=`vim-cmd vmsvc/getallvms | grep $tgt1 | awk '{print $2}'`
if [ ! -d $tgt1 ] && [ "$tgt1" != "$vmemt" ]; then

# Check source VM power state
if [ "$vmps" == "Powered on" ]; then
vim-cmd vmsvc/power.shutdown $vmids
sleep 10
fi

# Clone VM
echo
echo `date "+%F %r %Z"` "Start cloning $src1 to $tgt1..."

mkdir $tgt1
cp $src1/$src1.nvram $tgt1/$tgt1.nvram
cp $src1/$src1.vmsd $tgt1/$tgt1.vmsd
cp $src1/$src1.vmx $tgt1/$tgt1.vmx
cp $src1/$src1.vmxf $tgt1/$tgt1.vmxf

echo
vmkfstools -i $src1/$src1.vmdk $tgt1/$tgt1.vmdk
echo

cd $tgt1
for src in $src1*
do
if [ ! -f $tgt1.vmdk ];
then
tgt=`echo $src | sed "s/$src1/$tgt1/g" -` ; mv "$src" "$tgt"
fi
done

sed -i "s/$src1/$tgt1/g" $tgt1.vmx
sed -i "s/$src1/$tgt1/g" $tgt1.vmxf
cd ..

# Register the cloned VM
echo `date "+%F %r %Z"` "Register VM $tgt1..."
vim-cmd solo/registervm `pwd`/$tgt1/$tgt1.vmx > /dev/null 2>&1

# Power on the VM in background
echo `date "+%F %r %Z"` "Power on VM $tgt1..."
tvmid=`vim-cmd vmsvc/getallvms | grep "$tgt1" | awk '{print $1}'`
vim-cmd vmsvc/power.on $tvmid &

# We choose messageChoice 2 because this is a clone VM and need a new macAddress
# 0. Cancel (Cancel)
# 1. I moved it (I moved it)
# 2. I copied it (I copied it) [default]
#
sleep 3

# Determine ESXi version to apply messageId
# 0 - ESXi 4.1.0
# _vmx1 - ESXi 5.1.0
#
if [ "$esxiv" = "ESXi 4.1.0" ];
then
vim-cmd vmsvc/message $tvmid 0 2
elif [ "$esxiv" = "ESXi 5.0.0" ];
then
vim-cmd vmsvc/message $tvmid _vmx1 2
fi

echo `date "+%F %r %Z"` "Complete clone VM $src1 to $tgt1..."
echo

else
echo
echo "Target VM $src1 exists"
echo
fi

}

clear
echo "############################################################"
echo "# CloneVeeM 1.0 - VM Clone Script for ESXi 4.1.0 and 5.0.0 #"
echo "############################################################"
echo

esxiv=`vmware -v | awk '{print $2 " " $3}'`
echo "You are running this script on $esxiv"
echo

if [ "$esxiv" = "ESXi 5.0.0" -o "$esxiv" = "ESXi 4.1.0" ];
then

echo -n "Please enter source VM: "
read src1

# To restrict cloning of source VM within the ESXi host, use steps below.
#
# 1) Uncomment 1st and 2nd lines below
# 2) Then, comment 3rd line below
#
#vmems=`vim-cmd vmsvc/getallvms | grep $src1 | awk '{print $2}'`
#if [ -d $src1 ] && [ "$src1" = "$vmems" ]; then
if [ -d $src1 ]; then

vmids=`vim-cmd vmsvc/getallvms | grep $src1 | awk '{print $1}'`
vmps=`vim-cmd vmsvc/power.getstate $vmids | tail -1`

vhwv=`grep 'virtualHW.version' $src1/$src1.vmx | awk -F'"' '{print $2}'`

if [ "$esxiv" == "ESXi 5.0.0" -a "$vhwv" = "8" ]; then
clone
elif [ "$esxiv" == "ESXi 5.0.0" -a "$vhwv" = "7" ]; then
clone
elif [ "$esxiv" == "ESXi 4.1.0" -a "$vhwv" = "7" ]; then
clone

else
echo
echo "Source VM $src1 Hardware Version mismatch ($esxiv - Hardware Version $vhwv)"
echo
fi

else
echo
echo "Source VM $src1 does not exists"
echo
fi

else
echo
echo "This version of $esxiv is not supported by this script"
echo
fi

# --- eof ---
