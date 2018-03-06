#!/bin/sh
#
# All ethernet related stuff should come here, from inserting modules upto setti
#
ncecho 'Loading Ethernet module.    '

if [ ! ${PLATFORM} ]; then
	if [ ${IS_ETH_DEPEND} = "yes" ]; then
		for i in ${ETH_DEPEND_DRIVERS};
		do
		MODULE_TO_INSERT=`find /lib/modules -name ${i}`
	        if [ -e ${MODULE_TO_INSERT} ]; then
			${INSMOD} ${MODULE_TO_INSERT}
		fi
		if [ $? != 0 ]; then
			cecho red '[LOADING '${MODULE_TO_INSERT}' FAILED]'
	        fi
		done
	fi
	for i in ${ETH_DRIVER};
	do
	MODULE_TO_INSERT=`find /lib/modules -name ${i}`

	if [ -e ${MODULE_TO_INSERT} ]; then
	
	        if [ ${CONFIG_TX_LEN} = "yes" ]; then
	                ${INSMOD} ${MODULE_TO_INSERT} ${MFGMODE_MODPARAM}
	        else
	                ${INSMOD} ${MODULE_TO_INSERT} tx_len_per_ds=512 fifo_3=0
	        fi
	        if [  $? != 0 ]; then
	        	cecho red '[FAILED]'
	                exit;
	        fi
		if [ ${ETH_MAC_CONGIURABLE} = "yes" ]; then
			if [ -e ${MANU_BOARD_FILE} ]; then
				cecho yellow '[GENMAC]'
				ncecho '                            '
			if [ -e ${BDDATARD} ]; then
	        		${BDDATARD} ${MAC_OFFSET_4_ETH} | xargs ${IFCONFIG} ${ETH_INTERFACE} hw ether
				if [ ${PRODUCT_ID} = "WAC505" ]; then
					${BDDATARD} ${MAC_OFFSET_4_BRTRUNK} | xargs ${IFCONFIG} ${BRIDGE_INTERFACE} hw ether
					${BDDATARD} ${MAC_OFFSET_4_ETH1} | xargs ${IFCONFIG} ${ETH1_INTERFACE} hw ether
				fi
			fi
			fi
			${IFCONFIG} ${ETH_INTERFACE} mtu ${ETH_MTU}
		fi
	        cecho green '[DONE]'
	else
	        cecho red '[FAILED]'
	fi
	done

	if [ -f /etc/board ]; then
		PRODUCT_ID=`grep ProductID /etc/board | cut -d ' ' -f 3`
		if [ ${PRODUCT_ID} = "WAC510" ] || [ ${PRODUCT_ID} = "WAC505" ] || [ ${PRODUCT_ID} = "WAC710" ]; then
			if [ $MFG_MODE != 2 ]; then
				# Apply vlan settings to internal switch in IPQ40xx SoC used in WAC510 product
				echo ${SWITCH_LAN_VLAN} > /proc/sys/net/edma/default_lan_tag
				echo ${SWITCH_WAN_VLAN} > /proc/sys/net/edma/default_wan_tag

				ssdk_sh vlan entry append ${SWITCH_LAN_VLAN} ${SWITCH_LAN_VLAN} 0,${SWITCH_LAN_PORT} 0 ${SWITCH_LAN_PORT} null no no > ${NULL_DEVICE} 2>&1
				ssdk_sh vlan entry append ${SWITCH_WAN_VLAN} ${SWITCH_WAN_VLAN} 0,${SWITCH_WAN_PORT} 0 ${SWITCH_WAN_PORT} null no no > ${NULL_DEVICE} 2>&1

				ssdk_sh portvlan ingress set ${CPU_PORT} secure > ${NULL_DEVICE} 2>&1
				ssdk_sh portvlan ingress set ${SWITCH_LAN_PORT} secure > ${NULL_DEVICE} 2>&1
				ssdk_sh portvlan ingress set ${SWITCH_WAN_PORT} secure > ${NULL_DEVICE} 2>&1

				ssdk_sh portvlan egress set ${CPU_PORT} untagged > ${NULL_DEVICE} 2>&1
				ssdk_sh portvlan egress set ${SWITCH_LAN_PORT} untagged > ${NULL_DEVICE} 2>&1
				ssdk_sh portvlan egress set ${SWITCH_WAN_PORT} untagged > ${NULL_DEVICE} 2>&1

				ssdk_sh portvlan defaultcvid set ${SWITCH_LAN_PORT} ${SWITCH_LAN_VLAN} > ${NULL_DEVICE} 2>&1
				ssdk_sh portvlan defaultcvid set ${SWITCH_WAN_PORT} ${SWITCH_WAN_VLAN} > ${NULL_DEVICE} 2>&1

			fi

			if [ $MFG_MODE == 1 ]; then
				# Enable force mode for LAN port LED_100M
				ssdk_sh debug phy set 0x3 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x8075 > /dev/null
				ssdk_sh debug phy set 0x3 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x8640 > /dev/null

				# Enable force mode for LAN port LED_1000M
				ssdk_sh debug phy set 0x3 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x8077 > /dev/null
				ssdk_sh debug phy set 0x3 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x8640 > /dev/null

				# Enable force mode for WAN port LED_100M
				ssdk_sh debug phy set 0x4 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x8075 > /dev/null
				ssdk_sh debug phy set 0x4 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x8640 > /dev/null

				# Enable force mode for WAN port LED_1000M
				ssdk_sh debug phy set 0x4 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x8077 > /dev/null
				ssdk_sh debug phy set 0x4 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x8640 > /dev/null
			else
				# Enable normal mode for LAN port LED_100M
				ssdk_sh debug phy set 0x3 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x8075 > /dev/null
				ssdk_sh debug phy set 0x3 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x0 > /dev/null

				# Enable normal mode for LAN port LED_1000M
				ssdk_sh debug phy set 0x3 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x8077 > /dev/null
				ssdk_sh debug phy set 0x3 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x0 > /dev/null

				# Enable normal mode for WAN port LED_100M
				ssdk_sh debug phy set 0x4 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x8075 > /dev/null
				ssdk_sh debug phy set 0x4 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x602 > /dev/null

				# Enable normal mode for WAN port LED_1000M
				ssdk_sh debug phy set 0x4 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x8077 > /dev/null
				ssdk_sh debug phy set 0x4 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x604 > /dev/null

				# LAN port - Turn ON Solid Green when 1000M link is Up
				ssdk_sh debug phy set 0x3 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x8076 > /dev/null
				ssdk_sh debug phy set 0x3 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x40 > /dev/null

				# WAN port - Turn ON Solid Green when 1000M link is Up
				ssdk_sh debug phy set 0x4 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x8076 > /dev/null
				ssdk_sh debug phy set 0x4 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x40 > /dev/null

				# LAN port - Turn ON Solid Amber when 10/100M link is Up
				ssdk_sh debug phy set 0x3 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x8074 > /dev/null
				ssdk_sh debug phy set 0x3 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x3 0xe 0x30 > /dev/null

				# WAN port - Turn ON Solid Amber when 10/100M link is Up
				ssdk_sh debug phy set 0x4 0xd 0x7 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x8074 > /dev/null
				ssdk_sh debug phy set 0x4 0xd 0x4007 > /dev/null
				ssdk_sh debug phy set 0x4 0xe 0x30 > /dev/null
			fi
		fi
	fi
else
	ip address flush dev ${ETH_INTERFACE}
	${BDDATARD} ${MANUFAC_MTD_CHAR} ${MAC_OFFSET_4_ETH} | xargs ${IFCONFIG} ${ETH_INTERFACE} down hw ether
	${IFCONFIG} ${ETH_INTERFACE} up
	${IFCONFIG} ${ETH_INTERFACE} mtu ${ETH_MTU}
	cecho green '[DONE]'
fi
