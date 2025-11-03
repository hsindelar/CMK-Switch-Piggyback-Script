# SwitchPiggyScript

CheckMK agent plugin for monitoring network switches through SNMP queries using CheckMK's piggyback mechanism.

## Overview

This script queries network switches via SNMP to collect basic monitoring data including device status, uptime, and IP addresses. The switches are reported to CheckMK as piggyback hosts, allowing centralized monitoring without requiring agent installation on the switches themselves.

## Script

### `switchPiggy.sh`
Main plugin script that generates CheckMK piggyback data for network switches.

**Monitors:**
- Device reachability status (via SNMP)
- Device uptime (formatted as days, hours, minutes)
- Switch IP address

**Output format:** CheckMK piggyback data with local checks for each switch

## Requirements

- CheckMK agent installed on the monitoring host
- SNMP client tools (`snmpget`)
- Network switches with:
  - SNMP v2c enabled
  - Read access configured
- Read-only SNMP community string

## Configuration

Edit the script to configure your environment:

```bash
COMMUNITY="your_snmp_community"
SWITCHES="10.0.0.1 10.0.0.2 10.0.0.3"
```

**Variables:**
- `COMMUNITY`: SNMP community string for authentication
- `SWITCHES`: Space-separated list of switch IP addresses to monitor

## Installation

1. Copy `switchPiggy.sh` to the CheckMK agent plugins directory:
   ```bash
   sudo cp switchPiggy.sh /usr/local/lib/check_mk_agent/plugins/
   sudo chmod +x /usr/local/lib/check_mk_agent/plugins/switchPiggy.sh
   ```

2. Configure your SNMP community and switch IPs in the script

3. Test the script manually:
   ```bash
   /usr/local/lib/check_mk_agent/plugins/switchPiggy.sh
   ```

4. Perform service discovery in CheckMK to see the piggyback hosts

## How It Works

1. Script iterates through configured switches
2. For each switch, performs SNMP queries:
   - `sysName.0` - Device hostname (used as piggyback host name)
   - `SYSUPTIME_OID` (1.3.6.1.2.1.1.3.0) - System uptime
3. Tests SNMP reachability before attempting data collection
4. Outputs piggyback data in CheckMK format with local checks

## CheckMK Piggyback Format

The script outputs data in CheckMK's piggyback format:

```
<<<<SwitchHostname>>>>
<<<local>>>
0 Device-Status - SwitchHostname reachable via SNMP
0 Uptime - Uptime: 45d 12h 30m
0 IP-Address - IP: 10.0.0.1
<<<<>>>>
```

Each switch creates three local checks in CheckMK:
- **Device-Status**: Status 0 (OK) if reachable, 2 (CRITICAL) if unreachable
- **Uptime**: Status 0 (OK) with formatted uptime information
- **IP-Address**: Status 0 (OK) with the switch's IP address

## Error Handling

- If a switch hostname cannot be retrieved, defaults to `switch_<IP>`
- If a switch is unreachable via SNMP, reports critical status and skips remaining checks
- All SNMP errors are suppressed to prevent cluttering output

## Use Cases

- Basic switch health monitoring
- Multi-switch uptime tracking
- Network device inventory
- SNMP connectivity verification
- Foundation for additional switch monitoring metrics

## Extending the Script

To add additional switch metrics, follow the existing pattern:

1. Define the SNMP OID for the metric
2. Query using `snmpget` or `snmpwalk`
3. Format the output
4. Add an `echo` statement in the piggyback section

**Example - Adding temperature monitoring:**
```bash
TEMP_OID="1.3.6.1.4.1.9.9.13.1.3.1.3"
TEMP=$(snmpget -v2c -c "$COMMUNITY" -Oqv "$SW" "$TEMP_OID" 2>/dev/null)
echo "0 Temperature - Temp: ${TEMP}°C"
```

## Troubleshooting

**No output:**
- Verify SNMP community string is correct
- Check network connectivity to switches
- Ensure SNMP v2c is enabled on switches
- Verify firewall rules allow SNMP (UDP port 161)

**Switches showing as unreachable:**
- Test SNMP manually: `snmpget -v2c -c <community> <switch_ip> sysName.0`
- Check SNMP access control lists on switches
- Verify correct community string

**Incorrect hostname:**
- Check if `sysName.0` is properly configured on switches
- Script will fall back to `switch_<IP>` if hostname retrieval fails

## License

MIT License - Feel free to modify and distribute

## Contributing

Pull requests welcome! Please test thoroughly in your environment before submitting.
