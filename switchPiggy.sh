#!/bin/sh
export PATH="/usr/local/bin:$PATH"

#Shows device status, ip address, and uptime

SWITCHES=""
COMMUNITY=""

SYSUPTIME_OID="1.3.6.1.2.1.1.3.0"
IPADDR_OID="1.3.6.1.2.1.4.20.1.1"

for SW in $SWITCHES; do
    HOSTNAME=$(snmpget -v2c -c "$COMMUNITY" -Oqv "$SW" sysName.0 2>/dev/null)
    [ -z "$HOSTNAME" ] && HOSTNAME="switch_${SW}"

    # Test SNMP reachability
    snmpget -v2c -c "$COMMUNITY" -Oqv "$SW" "$SYSUPTIME_OID" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        REACHABLE=0
    else
        REACHABLE=1
    fi

    echo "<<<<${HOSTNAME}>>>>"
    echo "<<<local>>>"

    # 1. Device status
    if [ "$REACHABLE" -eq 1 ]; then
        echo "0 Device-Status - ${HOSTNAME} reachable via SNMP"
    else
        echo "2 Device-Status - ${HOSTNAME} not reachable via SNMP"
        echo "<<<<>>>>"
        continue
    fi

    # 2. Device uptime
    UPTIME_RAW=$(snmpget -v2c -c "$COMMUNITY" -Oqv "$SW" "$SYSUPTIME_OID" 2>/dev/null)
    if echo "$UPTIME_RAW" | grep -q ':'; then
        DAYS=$(echo "$UPTIME_RAW" | cut -d':' -f1)
        HOURS=$(echo "$UPTIME_RAW" | cut -d':' -f2)
        MINS=$(echo "$UPTIME_RAW" | cut -d':' -f3)
    else
        SECS=$(expr "$UPTIME_RAW" / 100 2>/dev/null)
        DAYS=$(expr "$SECS" / 86400)
        HOURS=$(expr \( "$SECS" % 86400 \) / 3600)
        MINS=$(expr \( "$SECS" % 3600 \) / 60)
    fi
    echo "0 Uptime - Uptime: ${DAYS}d ${HOURS}h ${MINS}m"

    # 3. Switch IP address
    IP_ADDR="$SW"
    echo "0 IP-Address - IP: $IP_ADDR"

    echo "<<<<>>>>"
done
