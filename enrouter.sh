#!/bin/bash
# Simple one-client sharing of internet from one interface to another.
# Usage:
# # ./enrouter.sh

EDEV="enp3s0f2";
WDEV="wlp2s0";

# /*
#  * Mock "gateway" IP. Other client will have to have an ip in this subnet.
#  * The other client can also access this machine via this IP.
#  */
MOCKIP="10.0.0.1";

# /*
#  * The real gateway subnet.
#  */
GATEWAYSUBNET="192.168.0.0/16";

# /*
#  * Wraps a command to a simple error handler.
#  */
wrap_command() {
	"$@" || echo "Error executing \"$*\"." && exit 1;
}

echo "* Setting mock gateway IP $MOCKIP on $EDEV"
wrap_command ip addr add $MOCKIP/24 dev $EDEV
echo "* Bringing up $EDEV"
wrap_command ip link set up dev $EDEV

if [ ! -f "/etc/iptables/iptables.rules" ] || [ "$1" == "--force" ]; then
	echo "* Fresh enrouter run. Creating rules."
	echo "* Masquerading $EDEV traffic -> $WDEV"
	wrap_command iptables -t nat -A POSTROUTING -o $EDEV -j MASQUERADE

	echo "* Adding forwarding rules"
	wrap_command iptables -I FORWARD -o $EDEV -s $GATEWAYSUBNET -j ACCEPT
	wrap_command iptables -I INPUT -s $GATEWAYSUBNET -j ACCEPT
	echo "* Saving iptables rules."
	iptables-save -f "/etc/iptables/iptables.rules";
fi
echo "* Done."