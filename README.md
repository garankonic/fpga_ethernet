EthernetCore
=============

Base project for the EthernetCore

### Description

This project is the basic Ethernet interface between computer and Xilinx KC705 Evaluation Board. The data transfer is done using UDP protocol and 1G/2.5G Ethernet PCS/PMA or SGMII LogiCORE IP from Xilinx. MAC is very simple, but can be extended easily.

### Requirements

* Vivado 2016.2
* Xilinx KC705 Evaluation Board

### Running

Open Vivado Design Suite. At the bottom you can find Tcl console.
- Go to the cloned directory ( cd "directory" )
- Run Tcl script to create a project ( source ./build.tcl)
- Ubuntu: to receive and send ethernet packages run `sudo ethtool -K eth0 rx-all on` (with corresponding ethernet interface name)

### License

Feel free to modify the code for your specific application.
