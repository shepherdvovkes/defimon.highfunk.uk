#!/bin/bash

# Comprehensive WiFi Malicious Traffic Analysis
# Analyzes /var/tmp/wififlow.pcap for all signs of malicious activity

PCAP_FILE="/var/tmp/august17_capture.pcap"
ANALYSIS_FILE="/var/tmp/comprehensive_wifi_analysis_$(date +%Y%m%d_%H%M%S).txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    echo -e "$1" | tee -a "$ANALYSIS_FILE"
}

# Function to check if tshark is available
check_tshark() {
    if ! command -v tshark &> /dev/null; then
        log_message "${RED}ERROR: tshark is not installed. Please install Wireshark/tshark first.${NC}"
        exit 1
    fi
}

# Function to check if PCAP file exists
check_pcap_file() {
    if [ ! -f "$PCAP_FILE" ]; then
        log_message "${RED}ERROR: PCAP file $PCAP_FILE not found!${NC}"
        exit 1
    fi
}

# Function to analyze packet types and frequencies
analyze_packet_types() {
    log_message "${BLUE}=== PACKET TYPE ANALYSIS ===${NC}"
    
    echo "WiFi Frame Types Found:" >> "$ANALYSIS_FILE"
    tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype" -T fields -e wlan.fc.type_subtype | sort | uniq -c | sort -nr >> "$ANALYSIS_FILE"
    
    log_message "${CYAN}Frame Type Breakdown:${NC}"
    tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype" -T fields -e wlan.fc.type_subtype | sort | uniq -c | sort -nr
    
    # Analyze specific frame types
    local beacon_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 8" -q | wc -l)
    local probe_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 4" -q | wc -l)
    local deauth_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12" -q | wc -l)
    local disassoc_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 10" -q | wc -l)
    
    log_message "${CYAN}Key Frame Counts:${NC}"
    log_message "Beacon frames: $beacon_count"
    log_message "Probe requests: $probe_count"
    log_message "Deauthentication: $deauth_count"
    log_message "Disassociation: $disassoc_count"
}

# Function to analyze SSIDs and BSSIDs
analyze_networks() {
    log_message "${BLUE}=== NETWORK ANALYSIS ===${NC}"
    
    echo "All Networks Detected:" >> "$ANALYSIS_FILE"
    tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 8" -T fields -e wlan.ssid -e wlan.bssid | sort | uniq -c | sort -nr >> "$ANALYSIS_FILE"
    
    log_message "${CYAN}Networks by Packet Count:${NC}"
    tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 8" -T fields -e wlan.ssid -e wlan.bssid | sort | uniq -c | sort -nr
    
    # Check for potential evil twins
    log_message "${CYAN}Checking for Evil Twins...${NC}"
    local evil_twins=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 8" -T fields -e wlan.ssid -e wlan.bssid | sort | uniq -c | awk '$1 > 1 && $2 != "" && $2 != "<MISSING>"')
    if [ -n "$evil_twins" ]; then
        log_message "${YELLOW}Potential Evil Twins Detected:${NC}"
        echo "$evil_twins"
        echo "Evil Twin Analysis:" >> "$ANALYSIS_FILE"
        echo "$evil_twins" >> "$ANALYSIS_FILE"
    else
        log_message "${GREEN}No Evil Twins Detected${NC}"
    fi
}

# Function to analyze deauthentication attacks
analyze_deauth_attacks() {
    log_message "${BLUE}=== DEAUTHENTICATION ANALYSIS ===${NC}"
    
    local deauth_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12" -q | wc -l)
    
    if [ "$deauth_count" -gt 0 ]; then
        log_message "${RED}[!] WARNING: $deauth_count deauthentication packets detected!${NC}"
        
        echo "Deauthentication Analysis:" >> "$ANALYSIS_FILE"
        echo "Total deauth packets: $deauth_count" >> "$ANALYSIS_FILE"
        
        # Analyze deauth sources
        log_message "${CYAN}Deauth Sources:${NC}"
        tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12" -T fields -e wlan.sa | sort | uniq -c | sort -nr
        
        # Analyze deauth targets
        log_message "${CYAN}Deauth Targets:${NC}"
        tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12" -T fields -e wlan.da | sort | uniq -c | sort -nr
        
        # Analyze reason codes
        log_message "${CYAN}Deauth Reason Codes:${NC}"
        tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12" -T fields -e wlan.fixed.reason_code | sort | uniq -c | sort -nr
        
        # Check for flooding patterns
        local deauth_sources=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12" -T fields -e wlan.sa | sort | uniq -c | sort -nr | awk '$1 > 10')
        if [ -n "$deauth_sources" ]; then
            log_message "${RED}[!] WARNING: Potential deauth flooding detected!${NC}"
            echo "Deauth Flooding Sources:" >> "$ANALYSIS_FILE"
            echo "$deauth_sources" >> "$ANALYSIS_FILE"
        fi
    else
        log_message "${GREEN}[+] No deauthentication attacks detected${NC}"
    fi
}

# Function to analyze disassociation attacks
analyze_disassociation_attacks() {
    log_message "${BLUE}=== DISASSOCIATION ANALYSIS ===${NC}"
    
    local disassoc_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 10" -q | wc -l)
    
    if [ "$disassoc_count" -gt 0 ]; then
        log_message "${YELLOW}[!] WARNING: $disassoc_count disassociation packets detected!${NC}"
        
        echo "Disassociation Analysis:" >> "$ANALYSIS_FILE"
        echo "Total disassociation packets: $disassoc_count" >> "$ANALYSIS_FILE"
        
        # Analyze disassoc sources and targets
        log_message "${CYAN}Disassociation Sources:${NC}"
        tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 10" -T fields -e wlan.sa | sort | uniq -c | sort -nr
        
        log_message "${CYAN}Disassociation Targets:${NC}"
        tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 10" -T fields -e wlan.da | sort | uniq -c | sort -nr
    else
        log_message "${GREEN}[+] No disassociation attacks detected${NC}"
    fi
}

# Function to analyze beacon frame flooding
analyze_beacon_flooding() {
    log_message "${BLUE}=== BEACON FLOODING ANALYSIS ===${NC}"
    
    local beacon_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 8" -q | wc -l)
    local duration=$(tshark -r "$PCAP_FILE" -q -z io,stat,0 | grep "Duration" | awk '{print $3}' | sed 's/secs//')
    
    if [ -n "$duration" ] && [ "$duration" -gt 0 ]; then
        local beacons_per_sec=$(echo "scale=2; $beacon_count / $duration" | bc 2>/dev/null || echo "N/A")
        log_message "${CYAN}Beacon Rate: $beacons_per_sec beacons/second${NC}"
        
        if [ "$beacon_count" -gt 1000 ]; then
            log_message "${YELLOW}[!] High beacon count: $beacon_count${NC}"
        fi
    fi
    
    # Check for beacon frame flooding from same source
    local beacon_sources=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 8" -T fields -e wlan.sa | sort | uniq -c | sort -nr | awk '$1 > 100')
    if [ -n "$beacon_sources" ]; then
        log_message "${YELLOW}[!] Potential beacon flooding detected!${NC}"
        echo "Beacon Flooding Sources:" >> "$ANALYSIS_FILE"
        echo "$beacon_sources" >> "$ANALYSIS_FILE"
    fi
}

# Function to analyze probe request flooding
analyze_probe_flooding() {
    log_message "${BLUE}=== PROBE REQUEST ANALYSIS ===${NC}"
    
    local probe_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 4" -q | wc -l)
    
    if [ "$probe_count" -gt 0 ]; then
        log_message "${CYAN}Probe Request Count: $probe_count${NC}"
        
        # Check for probe request flooding
        local probe_sources=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 4" -T fields -e wlan.sa | sort | uniq -c | sort -nr | awk '$1 > 50')
        if [ -n "$probe_sources" ]; then
            log_message "${YELLOW}[!] Potential probe request flooding detected!${NC}"
            echo "Probe Flooding Sources:" >> "$ANALYSIS_FILE"
            echo "$probe_sources" >> "$ANALYSIS_FILE"
        fi
        
        # Analyze probe request targets
        log_message "${CYAN}Probe Request Targets (SSIDs):${NC}"
        tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 4" -T fields -e wlan.ssid | sort | uniq -c | sort -nr | head -10
    else
        log_message "${GREEN}[+] No probe requests detected${NC}"
    fi
}

# Function to analyze EAPOL packets (KRACK attacks)
analyze_eapol_packets() {
    log_message "${BLUE}=== EAPOL ANALYSIS (KRACK DETECTION) ===${NC}"
    
    local eapol_count=$(tshark -r "$PCAP_FILE" -Y "eapol" -q | wc -l)
    
    if [ "$eapol_count" -gt 0 ]; then
        log_message "${YELLOW}[!] Found $eapol_count EAPOL packets - checking for KRACK attacks...${NC}"
        
        echo "EAPOL Analysis:" >> "$ANALYSIS_FILE"
        echo "Total EAPOL packets: $eapol_count" >> "$ANALYSIS_FILE"
        
        # Check for replayed handshakes
        log_message "${CYAN}EAPOL Packet Types:${NC}"
        tshark -r "$PCAP_FILE" -Y "eapol" -T fields -e eapol.type | sort | uniq -c | sort -nr
        
        # Check for potential KRACK patterns
        local eapol_pairs=$(tshark -r "$PCAP_FILE" -Y "eapol" -T fields -e wlan.sa -e wlan.da -e eapol.type | sort | uniq -c | awk '$1 > 1')
        if [ -n "$eapol_pairs" ]; then
            log_message "${RED}[!] WARNING: Potential KRACK attack indicators!${NC}"
            echo "Potential KRACK Indicators:" >> "$ANALYSIS_FILE"
            echo "$eapol_pairs" >> "$ANALYSIS_FILE"
        fi
    else
        log_message "${GREEN}[+] No EAPOL packets found${NC}"
    fi
}

# Function to analyze WPS attacks
analyze_wps_attacks() {
    log_message "${BLUE}=== WPS ATTACK ANALYSIS ===${NC}"
    
    local wps_count=$(tshark -r "$PCAP_FILE" -Y "wlan.tag.number == 221 && wlan.tag.oui == 0x0050f2" -q | wc -l)
    
    if [ "$wps_count" -gt 0 ]; then
        log_message "${RED}[!] WARNING: WPS packets detected - potential WPS attacks!${NC}"
        
        echo "WPS Analysis:" >> "$ANALYSIS_FILE"
        echo "Total WPS packets: $wps_count" >> "$ANALYSIS_FILE"
        
        log_message "${CYAN}WPS Packet Sources:${NC}"
        tshark -r "$PCAP_FILE" -Y "wlan.tag.number == 221 && wlan.tag.oui == 0x0050f2" -T fields -e wlan.sa | sort | uniq -c | sort -nr
    else
        log_message "${GREEN}[+] No WPS attacks detected${NC}"
    fi
}

# Function to analyze Michael attacks (TKIP MIC failures)
analyze_michael_attacks() {
    log_message "${BLUE}=== MICHAEL ATTACK ANALYSIS ===${NC}"
    
    local michael_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12 && wlan.fixed.reason_code == 6" -q | wc -l)
    
    if [ "$michael_count" -gt 0 ]; then
        log_message "${RED}[!] WARNING: Michael attack indicators detected!${NC}"
        
        echo "Michael Attack Analysis:" >> "$ANALYSIS_FILE"
        echo "Total Michael attack indicators: $michael_count" >> "$ANALYSIS_FILE"
        
        log_message "${CYAN}Michael Attack Sources:${NC}"
        tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12 && wlan.fixed.reason_code == 6" -T fields -e wlan.sa | sort | uniq -c | sort -nr
    else
        log_message "${GREEN}[+] No Michael attacks detected${NC}"
    fi
}

# Function to analyze aireplay attacks
analyze_aireplay_attacks() {
    log_message "${BLUE}=== AIREPLAY ATTACK ANALYSIS ===${NC}"
    
    local aireplay_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12 && wlan.fixed.reason_code == 2" -q | wc -l)
    
    if [ "$aireplay_count" -gt 0 ]; then
        log_message "${RED}[!] WARNING: Potential aireplay-ng attack indicators!${NC}"
        
        echo "Aireplay Attack Analysis:" >> "$ANALYSIS_FILE"
        echo "Total aireplay indicators: $aireplay_count" >> "$ANALYSIS_FILE"
        
        log_message "${CYAN}Aireplay Attack Sources:${NC}"
        tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12 && wlan.fixed.reason_code == 2" -T fields -e wlan.sa | sort | uniq -c | sort -nr
    else
        log_message "${GREEN}[+] No aireplay-ng attacks detected${NC}"
    fi
}

# Function to analyze signal strength patterns
analyze_signal_patterns() {
    log_message "${BLUE}=== SIGNAL STRENGTH ANALYSIS ===${NC}"
    
    log_message "${CYAN}Signal Strength Distribution:${NC}"
    tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 8" -T fields -e radiotap.dbm_antsignal | sort | uniq -c | sort -nr | head -10
    
    # Check for suspicious signal patterns (very strong signals from unknown sources)
    local strong_signals=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 8" -T fields -e radiotap.dbm_antsignal -e wlan.bssid | awk '$1 > -30' | sort | uniq -c | sort -nr)
    if [ -n "$strong_signals" ]; then
        log_message "${YELLOW}[!] Very strong signals detected (potential nearby attacker):${NC}"
        echo "$strong_signals" | head -5
    fi
}

# Function to analyze timing patterns
analyze_timing_patterns() {
    log_message "${BLUE}=== TIMING PATTERN ANALYSIS ===${NC}"
    
    # Check for rapid packet sequences
    log_message "${CYAN}Analyzing packet timing patterns...${NC}"
    
    # Check for burst patterns in deauth packets
    local deauth_bursts=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12" -T fields -e frame.time_relative | awk '{if(NR>1) print $1-prev; prev=$1}' | awk '$1 < 0.1' | wc -l)
    if [ "$deauth_bursts" -gt 10 ]; then
        log_message "${RED}[!] WARNING: Rapid deauth bursts detected!${NC}"
        echo "Deauth Burst Analysis: $deauth_bursts rapid sequences" >> "$ANALYSIS_FILE"
    fi
}

# Function to generate comprehensive statistics
generate_statistics() {
    log_message "${BLUE}=== COMPREHENSIVE STATISTICS ===${NC}"
    
    echo "=== COMPREHENSIVE WIFI ANALYSIS STATISTICS ===" >> "$ANALYSIS_FILE"
    echo "Analysis Date: $(date)" >> "$ANALYSIS_FILE"
    echo "PCAP File: $PCAP_FILE" >> "$ANALYSIS_FILE"
    
    # Basic statistics
    local total_packets=$(tshark -r "$PCAP_FILE" -q | wc -l)
    echo "Total Packets: $total_packets" >> "$ANALYSIS_FILE"
    
    # Protocol hierarchy
    echo "" >> "$ANALYSIS_FILE"
    echo "=== PROTOCOL HIERARCHY ===" >> "$ANALYSIS_FILE"
    tshark -r "$PCAP_FILE" -q -z io,phs >> "$ANALYSIS_FILE" 2>/dev/null
    
    # Top talkers
    echo "" >> "$ANALYSIS_FILE"
    echo "=== TOP TALKERS ===" >> "$ANALYSIS_FILE"
    tshark -r "$PCAP_FILE" -q -z io,stat,0,wlan.sa >> "$ANALYSIS_FILE" 2>/dev/null
    
    # Conversation statistics
    echo "" >> "$ANALYSIS_FILE"
    echo "=== CONVERSATION STATISTICS ===" >> "$ANALYSIS_FILE"
    tshark -r "$PCAP_FILE" -q -z conv,wlan >> "$ANALYSIS_FILE" 2>/dev/null
}

# Function to create security assessment
create_security_assessment() {
    log_message "${BLUE}=== SECURITY ASSESSMENT ===${NC}"
    
    echo "" >> "$ANALYSIS_FILE"
    echo "=== SECURITY ASSESSMENT ===" >> "$ANALYSIS_FILE"
    
    local threat_level="LOW"
    local threats_found=0
    
    # Check various attack indicators
    local deauth_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 12" -q | wc -l)
    local disassoc_count=$(tshark -r "$PCAP_FILE" -Y "wlan.fc.type_subtype == 10" -q | wc -l)
    local eapol_count=$(tshark -r "$PCAP_FILE" -Y "eapol" -q | wc -l)
    local wps_count=$(tshark -r "$PCAP_FILE" -Y "wlan.tag.number == 221 && wlan.tag.oui == 0x0050f2" -q | wc -l)
    
    if [ "$deauth_count" -gt 0 ]; then
        threats_found=$((threats_found + 1))
        echo "THREAT: Deauthentication packets detected ($deauth_count)" >> "$ANALYSIS_FILE"
    fi
    
    if [ "$disassoc_count" -gt 0 ]; then
        threats_found=$((threats_found + 1))
        echo "THREAT: Disassociation packets detected ($disassoc_count)" >> "$ANALYSIS_FILE"
    fi
    
    if [ "$eapol_count" -gt 10 ]; then
        threats_found=$((threats_found + 1))
        echo "THREAT: Excessive EAPOL packets detected ($eapol_count)" >> "$ANALYSIS_FILE"
    fi
    
    if [ "$wps_count" -gt 0 ]; then
        threats_found=$((threats_found + 1))
        echo "THREAT: WPS packets detected ($wps_count)" >> "$ANALYSIS_FILE"
    fi
    
    # Determine threat level
    if [ "$threats_found" -gt 3 ]; then
        threat_level="HIGH"
    elif [ "$threats_found" -gt 1 ]; then
        threat_level="MEDIUM"
    fi
    
    echo "Overall Threat Level: $threat_level" >> "$ANALYSIS_FILE"
    echo "Threats Detected: $threats_found" >> "$ANALYSIS_FILE"
    
    log_message "${CYAN}Security Assessment:${NC}"
    log_message "Threat Level: $threat_level"
    log_message "Threats Detected: $threats_found"
}

# Main execution
main() {
    log_message "${GREEN}=== Comprehensive WiFi Malicious Traffic Analysis ===${NC}"
    log_message "Starting analysis at $(date)"
    log_message "PCAP File: $PCAP_FILE"
    log_message "Analysis File: $ANALYSIS_FILE"
    echo ""

    # Check prerequisites
    check_tshark
    check_pcap_file

    # Run all analyses
    analyze_packet_types
    echo ""
    analyze_networks
    echo ""
    analyze_deauth_attacks
    echo ""
    analyze_disassociation_attacks
    echo ""
    analyze_beacon_flooding
    echo ""
    analyze_probe_flooding
    echo ""
    analyze_eapol_packets
    echo ""
    analyze_wps_attacks
    echo ""
    analyze_michael_attacks
    echo ""
    analyze_aireplay_attacks
    echo ""
    analyze_signal_patterns
    echo ""
    analyze_timing_patterns
    echo ""
    generate_statistics
    echo ""
    create_security_assessment

    log_message ""
    log_message "${GREEN}=== Analysis Complete ===${NC}"
    log_message "Detailed analysis saved to: $ANALYSIS_FILE"
    
    # Show summary
    log_message "${CYAN}Quick Summary:${NC}"
    if [ -s "$ANALYSIS_FILE" ]; then
        grep -i "threat\|warning\|attack" "$ANALYSIS_FILE" | head -5
    fi
}

# Run main function
main "$@"
