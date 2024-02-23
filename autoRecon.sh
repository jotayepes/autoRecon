#!/bin/bash
# Exploit Title: Auto reconnaissance bash script
# Date Authored: 23/02/2024
# Script Author: Juan Yepes (NormalMan)
# Script Github: https://github.com/jotayepes/autoRecon
# Usage: ./autoRecon.sh [targetIP]
# This script uses DirSearch and Whatweb
# so you must have DirSearch and Whatweb installed

targetIP=$1

pingIP=$(ping -c 1 $targetIP)
ttlValue=$(echo "$pingIP" | grep -oP 'ttl=\K\d+')

echo ""
echo -e "\e[92m"
echo "  ___  _   _ _____ ___________ _____ _____ _____ _   _ "
echo " / _ \| | | |_   _|  _  | ___ \  ___/  __ \  _  | \ | |"
echo "/ /_\ \ | | | | | | | | | |_/ / |__ | /  \/ | | |  \| |"
echo "|  _  | | | | | | | | | |    /|  __|| |   | | | | . \` |"
echo "| | | | |_| | | | \ \_/ / |\ \| |___| \__/\ \_/ / |\  |"
echo "\_| |_/\___/  \_/  \___/\_| \_\____/ \____/\___/\_| \_/"
echo ""
echo -e "\e[0m"

machineType=""
if (( ttlValue <= 128 )); then
        machineType="Windows"
fi
if (( ttlValue <= 64 )); then
        machineType="Linux"
fi

echo ""
echo -e "\e[96mYou are scanning a" "\e[33m"$machineType"\e[0m" "\e[96mmachine\e[0m"

echo ""
echo -e "\e[96mExecuting port reconnaissance over address:""\e[33m" $targetIP"\e[0m"

echo ""
nmap -p- --open -sS --min-rate 5000 -n -Pn $targetIP -oN allPorts
echo ""

ports=$(grep -oP '\d+/tcp' ./allPorts | cut -d '/' -f 1 | paste -sd "," -)
echo ""

echo -e "\e[96mDiscovering services and version for detected ports:""\e[33m" $ports"\e[0m"
echo ""

nmap -sCV -p$ports $targetIP -oN targetedPorts
echo ""

httpServiceDetected=false
httpPort=""
serviceName=""
serviceVersion=""

while IFS= read -r line; do
        if [[ $line =~ (http|https) && $line =~ ^[0-9]+/tcp ]]; then
                httpServiceDetected=true
                httpPort=$(echo "$line" | cut -d'/' -f 1)

                echo -e "\e[92mHTTP service detected on port:" "\e[33m"$httpPort"\e[0m" | tee -a webScan
                echo ""
                echo -e "\e[96mSearching for Web Technologies\e[0m"
                whatweb "http://"$targetIP":"$httpPort | tee -a webScan
                echo "" | tee -a webScan
        fi
done < targetedPorts

while IFS= read -r line; do
        if [[ $line =~ ^[0-9]+/tcp ]]; then
                serviceName=$(echo "$line" | awk '{print $4}')
                serviceVersion=$(echo "$line" | awk '{print $5}')
                if [[ $serviceName != "" ]]; then
                        echo -e "\e[96mSarching for exploits for " "\e[33m"$serviceName $serviceVersion"\e[0m" | tee -a exploitsList
                        echo ""
                        searchsploit $serviceName $serviceVersion | tee -a exploitsList
                        echo "" | tee -a exploitsList
                fi
        fi
done < targetedPorts


if [ "$httpServiceDetected" = true ]; then
        echo -e "\e[96mRunning directory reconnaissance over:" "\e[33m"$targetIP"\e[0m"
        echo ""
        dirsearch -u $targetIP
fi

echo""
