#!/bin/bash
fname="ultimate-nmap-parser.sh"
version="0.9"
modified="03/23/2026"

: '
TO DO:
BUG: cant handle paths with spaces. so far the makcsv function doesnt appear to write to temp.csv
     **THINK I FIXED THIS -- Need lots more testing. go through and parse last projectes

--------------------
- 1. check if tcp,udp,unique,up and down files are empty - if empty then say 
- 2. more check of input file and exit if cant find open it. if no inputfile - exit
- 3. better checks for Up/Down hosts
- improve web-urls to check for http/https properly . dont parse out udp .. chaneg the name to urls .. rebuild this to make it more accurate
- add check to closed ports if no closed ports than say and dont make file liek the rest
- include modules from other tools  in the pack 
- take in xml file do checks and make more vauge... maybe make it pickup from folder location in future 
- make the output echo out each host file 
- improve closed ports - make a nice table 
- closed ports so they are a table .. csv?
- better processing output... show lines
- create a vesions file  of all the versions which can be looked up
- need to make the hosts files better .. dont like the output and the same port sometimes has multiple files
- lots more work needed on the output bit at the end  maybe use the ifs
- make like a log file - time stats. input swtichees used files es.. all stats ports est
- fix the output at the end 
- better error handling 
- need to check if there is nothing in the file then delete it and sate no hosts
- output stating what files been picked up ...list them out ?
- fix and check ssl function
- closed ports needs sorting 
- sort the port files - tcp, udp, unique
- have a bit at the end to print the output of files
- use less temp files try and keep things consistant in oneliner
- tidy up the script make it organised
- give the functions desicriptions so know what they are doing 
- renames the hosts services for indvidual port file ftp,telnet,ssl,web,http/https/ssl,mysql,oracle,mssql,smb,snmp....est so they are a bit bteer 
- create some error checking. file checks for each function. main file checks. fix the switches 
- test every switch and options
- stop reusing code. make functions for repeats
- better input checks. all runs first - giant if statemnt to check switches are valid first
- add useful features from OLD nmap-parser
- change the if statements so that there is an all function so it will set all the varibles on and create the folder. this needs testing too 
- TEST TEST TEST TEST TEST and check the output with lots of different scans and make sure it is all accurate. 

add parse out versions of stuff and look them up
remove duplicates in hosts files 
summary seems to show duplicates too 
fix web parsing - seems to pickup 3389 - look @ CBS
unqiue all the hosts bit 


#----------------------------------------------------------------- START OF SCRIPT -----------------------------------------------------------------
'

# colours - https://misc.flogisoft.com/bash/tip_colors_and_formatting
RED='\e[91m'
RESETCOL='\e[39m'


# doesnt seem to work that well so used version sort seems to be the best
export sortip="sort -V"
#export sortip="sort -t. -n -k1 | sort -t. -n -k2 | sort -t. -n -k3 | sort -t. -n -k4 | sort -u -V"
#export sortip="sort -t. -k 1 -V | sort -t. -k 2 -V | sort -t. -k 3 -V | sort -t. -k 4 -V"


#name of temp files
inputtemp="temp.gnmap"
csvtemp="temp.csv"


#output folder 
createoutdir="N"	#change to Y - if you always want mkdir outdir
outdir="parse"
outhostsdir="hosts"


#output file names
outputcsvfile="parsed_nmap.csv"
outputsummaryfile="summary.txt"
outputclosedfile="closed-summary.txt"
outputipfile="parsed_ipport.txt"
outputupfile="hosts_up.txt"
outputdownfile="hosts_down.txt"
outputuniquefile="ports_unique.txt"
outputtcpfile="ports_tcp.txt"
outputudpfile="ports_udp.txt"
outputsmbfile="smb.txt"
outputwebfile="urls.txt"
outputwebfile2="urls-dirty.txt"
outputsslfile="ssl.txt"
outputreport1file="report1.txt"
outputclosedsummaryfile="closed-summary.txt"

outputudpfileextra="ports_tcp_extra.txt"
outputtcpfileextra="ports_udp_extra.txt"



# Menu Switches
men_all="N"
men_csv="N"
men_summary="N"
men_uports="N"
men_tcpports="N"
men_udpports="N"
men_uphosts="N"
men_downhosts="N"
men_ipport="N"
men_smb="N"
men_ssl="N"
men_web="N"
men_hostports="N"
men_closed="N"
men_report1="N"
men_htmlreport="N"
men_summarylog="N"
# recursive flag - opt-in only, not included in --all
men_recursive="N"

function header () {
# header function  - used to print out the title of the script 
# need a better name i think
echo -e "\e[1m	_  _ _    ___ _ _  _ ____ ___ ____    _  _ _  _ ____ ___  "  
echo "	|  | |     |  | |\/| |__|  |  |___    |\ | |\/| |__| |__] "  
echo "	|__| |___  |  | |  | |  |  |  |___    | \| |  | |  | |    "  
echo "			___  ____ ____ ____ ____ ____                   "                                    
echo "			|__] |__| |__/ [__  |___ |__/                   "      
echo "			|    |  | |  \ ___] |___ |  \                   "
echo "			                                                "
echo -e "\e[39m\e[0m\e[96mVersion: $version - $modified" 																				 
echo -e "Created By: Shifty0g 	https://github.com/shifty0g  \e[39m"
echo ""
}

function footer () {
# footer to print out at the end of the script 
echo "--------------------------------------------------------------------------------------"
echo "				           ___                           "
echo "				  _  _  .-'   '-.                        "
echo "				 (.)(.)/         \                       "
echo "				  /@@             ;                      "
echo "				 o_\\-mm-......-mm\`~~~~~~~~~~~~~~~~\`   "
echo "				                                         "                                          
echo 
}

function helpmenu () {
# prints out the header and help menu when --help switch is selected to show the options to use 
header
echo 
echo "[*] Usage: $fname [input] [options]"
echo
echo -e "\e[95m[input]:		Grepable nmap file(s) .gnmap - can have multiple\e[39m"
echo
echo -e "\e[93m[options]:"
echo 
echo "	--help		Show this help menu"
echo "	--all		Runs ALL options - **EXCLUDING: report1, --html**"
echo "	--csv		Create .csv file - $outputcsvfile"
echo "	--summary	Create host Summary report - $outputsummaryfile"
echo "	--closed	Create Summary of hosts with CLOSED ports - $outputclosedfile"
echo "	--unique	Parse open unique TCP & UDP ports - $outputuniquefile"
echo "	--tcp		Parse open TCP ports - $outputtcpfile"
echo "	--udp		Parse open UDP ports - $outputudpfile"
echo "	--up		Parse 'Up' hosts - $outputupfile"
echo "	--down		Parse 'Down' hosts - $outputdownfile"
echo "	--ipport	Parse targets IP:PORT - $outputipfile"
echo "	--smb		Generate smb paths smb://IP - $outputsmbfile"
echo "	--web		Generate web URLS http://IP:PORT https://IP:PORT  - $outputwebfile"
echo "	--ssl		Generate ssl/tls hosts list IP:PORT - $outputsslfile"
echo "	--hostports	Generate hosts/hosts_<PORT>-<PROTOCOL>-<SERVICE>.txt files"
#echo "	--html		Generates a .html report for each scan (uses xml file - will auto pickup from \$pwd)"
echo "	--summarylog		Parses all local *.log file and creats ip:port/proto file - summary.log"
echo "	--r, --recursive	Recursively find and parse .gnmap files from current directory"
echo "  	--report1   	Report - IP[PORT1,PORT2,PORT3, ] - parsip.pl" 
echo 
echo -e "\e[39m[*] Example:"
echo 
echo "$fname *.gnmap --all"
echo "$fname nmap_tcp_full.gnmp nmap_udp_def.gnmap --summary --unique"
echo "$fname nmap_tcp_full.gnmp nmap_udp_def.gnmap --web"
# recursive example - no filenames needed, finds .gnmap files automatically
echo "$fname --all --recursive"
echo
echo "--------------------------------------------------------------------------------------"
echo
}

function diagnostics () {
# diagnostics function used to help figure out whats wrong - will delete this when release the script 
echo
echo
echo "################################[ DIAGNOSTICS ]########################################"
echo "\$0 - "$0
echo "\$1 - "$1
echo "\$* - "$*
echo "inpputfile - "$file
echo "inputfilepath - "$inputfilepath
echo "tempfile - "$tempfile
echo "outpath - "$outpath
echo "filecheck - "$filecheck
echo "#######################################################################################"
}

function mastercleanup () {
# MASTER cleanup - lazy just to wipe the temp stuff before and after soo all fresh
rm "${outpath}tempinput" "${outpath}ipptemp" "${outpath}closedtemp" "${outpath}summtemp" "${outpath}tempfile" "${outpath}tempfile2" "${outpath}$varTempFile2" "${outpath}inputfile" "${outpath}$varTempFile" "${outpath}$tempfile" "${outpath}$varSummTempFile" "${outpath}webtemp" "${outpath}webtemp2" "${hostportspath}hostptemp" "${outpath}$inputtemp" "${outpath}$inputtemp "${outputpath}$csvtemp > /dev/null 2>&1
}

function makecsv () {
# this is the main function which processes the inputfile and creates a csv file 
echo -e "\e[1m\e[93m[>]\e[0m Creating CSV File"

# single-pass awk replaces the original per-line shell loop for speed
# split on "/," which is the actual port entry terminator, preserving commas in version strings
awk '/\/open\/|\/closed\//{
    host=$2
    match($0, /Ports:[^\t]*/)
    ports=substr($0, RSTART+7, RLENGTH-7)
    n=split(ports, entries, "/,")
    for(i=1; i<=n; i++) {
        gsub(/^ +/, "", entries[i])
        m=split(entries[i], f, "/")
        if(f[2]=="open" || f[2]=="closed") {
            printf "%s,%s,%s,%s,%s,%s\n", host, f[1], f[2], f[3], f[5], f[7]
        }
    }
}' "${outpath}$inputtemp" > "${outpath}$csvtemp"

# finalise and move the file if temp.csv
if [ -f "${outpath}$csvtemp" ]; then
   echo "HOST,PORT,STATUS,PROTOCOL,SERVICE,VERSION" > "${outpath}$outputcsvfile" 
   # sort by ip address - 1st.2nd.3rd.4th
   cat "${outpath}"temp.csv"" |  sort -u | sort -t"," -n -k1 | $sortip >> "${outpath}$outputcsvfile" 
   echo "	- $outputcsvfile"
fi

#cleanup 
rm "${outpath}$csvtemp" "${outpath}"tempfile2"" > /dev/null 2>&1

echo
#end
}

function checkcsv () {
# checks if the makecsv fu nction has already ran and then sets the tempfile varible - stops repition as most other functions use the csv file 
if [ "$men_csv" == "Y" ]
then
	cp "${outpath}$outputcsvfile" "${outpath}$csvtemp"
else
	makecsv > /dev/null 2>&1
	mv "${outpath}$outputcsvfile" "${outpath}$csvtemp"
fi

# remove the head from the csv file 
sed -i -e "1d" "${outpath}$csvtemp"

# remove lines that have closed ports 
sed -i '/,closed,/d' "${outpath}$csvtemp"

export tempfile="$(realpath "${outpath}$csvtemp")"

# end
}

function summary () {
# creates the summary file of from the input of open ports 
echo -e "\e[1m\e[93m[>]\e[0m Creating Summary"

#check for csv file to process 
checkcsv

#clear any old file - fresh
rm "${outpath}$outputsummaryfile" > /dev/null 2>&1

# single-pass awk replaces per-line shell loop for speed
{
echo "+=========================================================================================+"
printf "%-18s %-16s %-52.52s %-2s \n" "| HOST " "| PORT / PROTOCOL" " | SERVICE" "|"
awk -F',' '{
    if($1 != lasthost && NR>1) print "+=========================================================================================+"
    ver = ($6 != "") ? "- " $6 : ""
    printf "%-18s %-16s %-52.52s %-2s \n", "| " $1 " ", "| " $2 " / " $4 " ", "  | " $5 " " ver, " |"
    lasthost=$1
}' "$tempfile"
echo "+=========================================================================================+"
} > "${outpath}$outputsummaryfile"

echo "	- $outputsummaryfile"
echo

#cleanup
rm  "$tempfile" > /dev/null 2>&1

#end
}

function ipport () {
# creates a file of open ports IP:PORT
echo -e "\e[1m\e[93m[>]\e[0m Creating IP Port file "

# check is csv is run and get a tempfile 
checkcsv

#clear any old file - fresh
rm "${outpath}$outputipfile" > /dev/null 2>&1

# finalise the file and clean up 
cat "$tempfile"  | cut -d, -f1,2 | tr -d '"' | tr , : | $sortip > "${outpath}$outputipfile"

#cleanup
rm  "$tempfile" > /dev/null 2>&1

echo "	- $outputipfile"
echo

#end
}

function uphosts () {
# creates a file with IPs for hosts with Up Statues - needs further checks to be better 
echo -e "\e[1m\e[93m[>]\e[0m Parsing up hosts"
cat "$inputfilepath" | grep -e 'Status: Up' -e '/open/' |  awk '{ print $2 }' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u -V  > "$outpath$outputupfile" 

# check if there are actually any IP addresses in the file - if not delete it no point 
if [ -z "$(cat "${outpath}$outputupfile" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")" ]
then
	  echo -e "$RED	- no up hosts $RESETCOL"
	  rm "${outpath}$outputupfile" > /dev/null 2>&1
else
      echo "	- $outputupfile"
fi
echo


#end
}

function downhosts () {
# creates a file with IPs for hosts with Down status 
echo -e "\e[1m\e[93m[>]\e[0m Parsing down hosts"
cat "$inputfilepath" | grep -e 'Status: Down' | awk '{ print $2 }' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u -V > "${outpath}$outputdownfile"

# check if there are actually any IP addresses in the file - if not delete it no point 
if [ -z "$(cat "${outpath}$outputdownfile" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")" ]
then
      echo -e "$RED	- no down hosts $RESETCOL"
	  rm "${outpath}$outputdownfile" > /dev/null 2>&1
else
      echo "	- $outputdownfile"
fi
echo

#end
}

function uniqueports () {
# creates a file listing out uniquie open TCP and UDP ports
echo -e "\e[1m\e[93m[>]\e[0m Parsing unique ports"
cat "$inputfilepath" | grep -o -P '.{0,9}/open/' | awk '{ print $2}' | cut -d /  -f 1 | sort -u -V | paste -s -d, 2>&1 > "${outpath}$outputuniquefile"; 

# check for a number if the file has them then likely has ports in  
if [ -z "$(cat "${outpath}$outputuniquefile" | grep '[0-9]')" ]
then
	  echo -e "$RED	- no Unique ports $RESETCOL"
	  rm "${outpath}$outputuniquefile" > /dev/null 2>&1
else
      echo "	- $outputuniquefile"
fi
echo

# end 
}

function tcpports () {
# creates a file of unqiue open TCP ports - 22,23,80,443...
echo -e "\e[1m\e[93m[>]\e[0m Parsing tcp ports"
cat "$inputfilepath" | grep '/tcp/' | grep -o -P '.{0,9}/open/' | awk '{ print $2}' | cut -d /  -f 1 | sort -u -V | paste -s -d, 2>&1 > "${outpath}$outputtcpfile";

# check for a number if the file has them then likely has ports in  
if [ -z "$(cat "${outpath}$outputtcpfile" |  grep '[0-9]')" ]
then
	  echo -e "$RED	- no TCP ports $RESETCOL"
	  rm "${outpath}$outputtcpfile" > /dev/null 2>&1
else
      echo "	- $outputtcpfile"
fi
echo

tcpports-extra 
# end  
}

function tcpports-extra () {
# creates a file of unqiue open TCP ports - 22,23,80,443...
echo -e "\e[1m\e[93m[>]\e[0m Parsing tcp ports - adding extras"
cat "$inputfilepath" | grep '/tcp/' | grep -o -P '.{0,9}/open/' | awk '{ print $2}' | cut -d /  -f 1 | sort -u -V | paste -s -d, 2>&1 > "${outpath}$outputtcpfileextra";

# check for a number if the file has them then likely has ports in  
if [ -z "$(cat "${outpath}$outputtcpfileextra" |  grep '[0-9]')" ]
then
	  echo -e "$RED	- no TCP ports $RESETCOL"
	  rm "${outpath}$outputtcpfileextra" > /dev/null 2>&1
else
	export EXTRA_TCP="$(cat $outputtcpfileextra 2>/dev/null),21,22,23,25,26,53,80,81,88,110,111,113,135,136,137,138,139,143,179,199,389,443,4444,445,4500,464,465,500,514,515,548,554,587,593,646,749,750,751,752,753,754,761,993,995,1025,1026,1027,1080,1194,1433,1720,1723,2000,2001,2222,2375,2376,25565,3000,3120,3128,3268,3269,3306,3389,4444,47001,49152,49154,49751,5000,5060,50911,5666,5900,5901,5902,5903,5985,5986,6001,6443,8080,8081,8088,8443,8500,8888,9200,9300,9999,10000,10250"  
	export EXTRA_TCP="$(echo $EXTRA_TCP | tr ',' '\n' | sort -u -V | paste -s -d,)"
	echo $EXTRA_TCP > ${outpath}$outputtcpfileextra

    echo "	- $outputtcpfileextra"
fi
echo
}

function udpports-extra () {
echo -e "\e[1m\e[93m[>]\e[0m Parsing udp ports - adding extras"
cat "$inputfilepath" | grep '/tcp/' | grep -o -P '.{0,9}/open/' | awk '{ print $2}' | cut -d /  -f 1 | sort -u -V | paste -s -d, 2>&1 > "${outpath}$outputudpfileextra";

# check for a number if the file has them then likely has ports in  
if [ -z "$(cat "${outpath}$outputudpfileextra" |  grep '[0-9]')" ]
then
	  echo -e "$RED	- no UDP ports $RESETCOL"
	  rm "${outpath}$outputudpfileextra" > /dev/null 2>&1
else
	export EXTRA_UDP="$(cat ${outpath}$outputudpfileextra)53,67,68,69,123,137,138,161,162,500,514,520,623,1434,1701,1900,2049,3478,3479,3702,4500,5060,5061,5353,5683,6000,61000,33434,11211,1194,37017,41641,47998,49152,51820,5355,64738,8125,10001"
	export EXTRA_UDP="$(echo $EXTRA_UDP | tr ',' '\n' | sort -u -V | paste -s -d,)"
	echo $EXTRA_UDP > ${outpath}$outputudpfileextra

    echo "	- $outputudpfileextra"
fi
echo




# end  
}

function udpports () {
# creates a file of unqiue open UDP ports - 53,161...
echo -e "\e[1m\e[93m[>]\e[0m Parsing udp ports"
cat "$inputfilepath" | grep '/udp/'  | grep -o -P '.{0,9}/open/' | awk '{ print $2}' | cut -d /  -f 1 | sort -u -V | paste -s -d, 2>&1 > "${outpath}$outputudpfile"

# check for a number if the file has them then likely has ports in  
if [ -z "$(cat "${outpath}$outputudpfile" | grep '[0-9]')" ]
then
	  echo -e "$RED	- no UDP ports $RESETCOL"
	  rm "${outpath}$outputudpfile" > /dev/null 2>&1
else
      echo "	- $outputudpfile"
fi
echo

udpports-extra 
# end 
}

function smb () {
# createa file for URI smb://192.168.1.1 
# will only grab out OPEN 445 TCP 
echo -e "\e[1m\e[93m[>]\e[0m Creating smb paths"
cat "$inputfilepath" | grep '445/open/tcp/' | awk '{ print $2}' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sed -e 's/^/smb:\/\//' | sort -u | $sortip | sort -t'/' -k2 -V  > "${outpath}$outputsmbfile"

# check for a smb:// if the file has them then likely has ports in  
if [ -z "$(cat "${outpath}$outputsmbfile" | grep 'smb://')" ]
then
	echo -e "$RED	- no SMB ports $RESETCOL"
	rm "${outpath}$outputsmbfile" > /dev/null 2>&1
else
	echo "	- $outputsmbfile"
	# also create plain IP list for SMB hosts
	cat "$inputfilepath" | grep '445/open/tcp/' | awk '{ print $2}' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u -V > "${outpath}smb-ips.txt"
	echo "	- smb-ips.txt"
fi
echo

# end 
}

function web () {
# make a file of URLS to use with tools like nikto wafwoof est
echo -e "\e[1m\e[93m[>]\e[0m Creating web URLS"

# start fresh
rm "${outpath}$webfinalname" "${outpath}webtemp2"  > /dev/null 2>&1

#check that the csv file has been created
checkcsv

# single-pass awk replaces per-line shell loop for speed
awk -F',' '{
	host=$1; port=$2; service=$5; version=$6
	if(port=="80")   print "http://" host ":" port "/"
	if(port=="443")  print "https://" host ":" port "/"
	if(port=="8080") print "http://" host ":" port "/"
	if(port=="8443") print "https://" host ":" port "/"
	if(service=="http") print "http://" host ":" port "/"
	if(service ~ /ssl/) print "https://" host ":" port "/"
	if(tolower(version) ~ /web/) print "http://" host ":" port "/"
}' "$tempfile" > "${outpath}webtemp2"

# if webtemp2 exists then sort it 
if [ -f "${outpath}webtemp2" ]; then
	sort -u "${outpath}webtemp2" | $sortip | sort -t'/' -k2 -V  > "${outpath}$outputwebfile" 2>&1
	echo "	- $outputwebfile"
else
	echo -e "$RED	- no ports found $RESETCOL"
	rm "${outpath}$outputwebfile" > /dev/null 2>&1
fi

#cleanup
rm "${outpath}webtemp2" "$tempfile"  > /dev/null 2>&1
echo ""

#end
}

function webdirty () {
# this will get urls all differnt ways and even from the log file .. its messy and dirty
# make a file of URLS to use with tools like nikto wafwoof est
echo -e "\e[1m\e[93m[>]\e[0m Creating web URLS (dirty  **NEED TO FIX**)"


#check that the csv file has been created
checkcsv

# start fresh
rm "${outpath}$webfinalname" "${outpath}webtemp1"  "${outpath}webtemp2" "${outpath}webtemp3" "${outpath}outputwebfile2" /tmp/we*.txt  > /dev/null 2>&1

# single-pass awk replaces per-line shell loop for speed
# checks known web ports + service/version matching
awk -F',' 'BEGIN {
    # known web ports
    split("80,443,8080,8443,8000,8888,8181,4443,8880,10443,5000,5001,9000,9443,7000,7001,7443,9090", wp, ",")
    for(i in wp) webports[wp[i]]=1
}
{
    host=$1; port=$2; service=$5; version=$6

    # service/version based detection
    if(service=="http") print "http://" host ":" port "/"
    if(service ~ /ssl/) print "https://" host ":" port "/"
    if(tolower(version) ~ /web/) print "http://" host ":" port "/"

    # known web port detection
    if(port in webports) {
        if(port=="80")       print "http://" host ":80/"
        else if(port=="443") print "https://" host ":443/"
        else {
            print "http://" host ":" port "/"
            print "https://" host ":" port "/"
        }
    }
}' "$tempfile" | sort -u > "${outpath}$outputwebfile2"

echo "	- $outputwebfile2"
echo ""
##cleanup
rm "${outpath}webtemp2" "${outpath}webtemp*" "${outpath}webtemp1" "${outpath}webtemp3" "$tempfile"  > /dev/null 2>&1

}

function ssl () {
echo -e "\e[1m\e[93m[>]\e[0m Creating ssl/tls list"

# start fresh
rm "${outpath}$outputsslfile" "${outpath}ssltemp2" > /dev/null 2>&1

#check that the csv file has been created
checkcsv

# single-pass awk replaces per-line shell loop for speed
awk -F',' '{
	host=$1; port=$2; service=$5; version=$6
	if(port=="443" || service ~ /ssl/ || version ~ /ssl/ || service ~ /tls/ || version ~ /tls/)
		print host ":" port
}' "$tempfile" > "${outpath}ssltemp2"


# if webtemp2 exists then sort it 
if [ -f "${outpath}ssltemp2" ]; then
	sort -u "${outpath}ssltemp2" | $sortip > "${outpath}$outputsslfile" 2>&1
	echo "	- $outputsslfile"
else
	echo -e "$RED	- no ports found $RESETCOL"
	rm "${outpath}$outputsslfile" > /dev/null 2>&1
fi


#clean up function
rm "${outpath}ssltemp" "${outpath}ssltemp2" "$tempfile" > /dev/null 2>&1

echo

#end
}

function hostports () {
# will create a folder hosts and generate ip lists for each open ports for example 80 http will be hosts/hosts_80-tcp-http.txt
# need to reqord some fo the service names to make them a little better 
echo -e "\e[1m\e[93m[>]\e[0m Generating host port files"

# fresh folder
rm "${outpath}$outhostsdir" -rf > /dev/null 2>&1

# make folder - this can be spammy
mkdir "${outpath}$outhostsdir" > /dev/null 2>&1
hostportspath=$(realpath "$outpath$outhostsdir")

#check that the csv file has been created
checkcsv

# single-pass awk replaces per-line shell loop for speed
awk -F',' '{
	host=$1; port=$2; proto=$4; service=$5
	# clean service name
	gsub(/[-?|]/, "", service)
	# normalize known port names
	if(port==445) service="smb"
	else if(port==161) service="snmp"
	else if(port==25) service="smtp"
	else if(port==21) service="ftp"
	else if(port==2049) service="nfs"
	else if(port==22) service="ssh"
	else if(port==23) service="telnet"
	else if(port==111) service="rpc"
	else if(port==137 || port==139) service="netbios"
	else if(port==3389) service="rdp"
	else if(port==53) service="dns"
	else if(port==113) service="ident"
	else if(port==79) service="finger"
	else if(port==5432) service="postgres"
	else if(port==3306) service="mysql"
	else if(port==1433) service="mssql"
	else if(port==443) service="https"
	else if(port==80) service="http"
	else if(port==636) service="ldap"
	else if(proto=="udp" && port==161) service="snmp"
	else if(proto=="udp" && port==177) service="xdmcp"
	else if(service=="msrpc") next
	else if(proto=="udp" && service=="unknown") next
	else if(service=="") next
	print host "\t" proto "_" port "-" service
}' "$tempfile" | while IFS='	' read -r host fname; do
	echo "$host" >> "$hostportspath/$fname.txt"
done

#function cleanup
rm  "${hostportspath}/_-.txt" "$tempfile" > /dev/null 2>&1

echo "	- "${outhostsdir}"/[PROTOCOL]_[PORT]-[SERVICE].txt"
echo
#end
}

function closedsummary() {
# creates a little report of hosts with closed ports
echo -e "\e[1m\e[93m[>]\e[0m Generating Closed Ports Summary"

rm "${outpath}$outputclosedsummaryfile" > /dev/null 2>&1
for host in $(cat "$inputfilepath" | grep "Host:" | grep "\/closed\/" | awk '{ print $2}'| sort --unique); do # will go through each host
    echo "Closed Ports For Host: $host " >> "${outpath}$outputclosedsummaryfile"
	echo -n "	" >> "${outpath}$outputclosedsummaryfile"
    for port in $(cat "$inputfilepath" | grep -w $host | grep -o -P '.{0,10}/closed/' | awk '{ print $2}' | cut -d /  -f 1 | sort --unique); do # go through ports
		echo -n $port", " >> "${outpath}$outputclosedsummaryfile"
    done # end ports loop
	echo -e "\n " >> "${outpath}$outputclosedsummaryfile"
done # end hosts loop

# old oneliner
#cat $inputfilepath |awk '/closed/{ s = ""; for (i = 5; i <= NF-4; i++) s = s substr($i,1,length($i)-4) "\n"; print $2 " " $3 "\n" s}' |grep -v open |grep -v "-" |sed "s/[/].*//" | grep -e '[[:digit:]]*\|"\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"' |sed 's/(//' |sed 's/)//' |sed "s/[a-zA-Z']/ /g" |sed -r '/^\s*$/d' |sed 's/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/\nBREAK Closed Ports For Host: &\n/' |paste -s -d,| sed 's/Closed/\n&/g'|sed 's/^\(, ,\)*//' | sed 's/,*$//g' |sed  -e 's/, ,/-/g' |tr - '\n' |sed 's/BREAK/\'$'\n/g' | sed 's/,,$//' > ${outpath}$closedsummaryname

echo "	- "$outputclosedsummaryfile
echo

#end
}

function htmlreport () {
# Experminetal and made just 
# creates a .html report from each .xml file in current directory - ignored the gnmap file input 
# uses https://github.com/honze-net/nmap-bootstrap-xsl

xmlfiles=$(ls | grep .xml)

while read line; do 
      # line is available for processing
      cat $line    
done < $xmlfiles
 


}

function report1() {
# create a different type of report like  parsip - will produce same output as nmap-parse.py

echo -e "\e[1m\e[93m[>]\e[0m Generating Report1"

# start fresh
rm "${outpath}$outputreport1file" "${outpath}"reportemp"" > /dev/null 2>&1

for host in $(cat $inputfilepath | grep "Host:" | grep "\/open\/" | awk '{ print $2}'| sort --unique); do # will go through each host
    echo -n $host  "[" >> "${outpath}"reportemp""
    for port in $(cat $inputfilepath | grep -w $host | grep -o -P '.{0,10}/open/' | awk '{ print $2}' | cut -d /  -f 1 | sort --unique); do # go through ports
		echo -n $port", " >> "${outpath}"reportemp""
    done # end ports loop
    echo  "]" >> "${outpath}"reportemp""
done # end hosts loop
cat "${outpath}"reportemp"" | $sortip | grep -v "\[\]"  >  "${outpath}$outputreport1file"

echo "	- "$outputreport1file
echo

#end
}

function printresults() {
# will print out the files generated at the end

# if yes will print the output - maybe flip this around so ENTER is for yes

# COMMENTED THIS OUT FOR EXAM
#echo 
#read -p "[-] Display Output? <ENTER = YES / Anything else = NO> : " prompt
#echo
prompt="Y"
men_all="Y"

if [ -z "$prompt" ]
then
	if [ $men_all == "Y" ]
	then
		more "${outpath}"*.txt
		more "${hostportspath}"/*_*.txt
	else
		if [ "$men_csv" == "Y" ]; then cat "${outpath}$outputcsvfile" 2> /dev/null; fi
		if [ "$men_summary" == "Y" ]; then cat "${outpath}$outputsummaryfile" 2> /dev/null; fi
		if [ "$men_ipport" == "Y" ]; then cat "${outpath}$outputipfile" 2> /dev/null; fi
		if [ "$men_uports" == "Y" ]; then cat "${outpath}$outputuniquefile" 2> /dev/null; fi
		if [ "$men_tcpports" == "Y" ]; then	cat "${outpath}$outputtcpfile" 2> /dev/null; fi
		if [ "$men_udpports" == "Y" ]; then	cat "${outpath}$outputudpfile" 2> /dev/null; fi
		if [ "$men_uphosts" == "Y" ]; then cat "${outpath}$outputupfile" 2> /dev/null; fi
		if [ "$men_downhosts" == "Y" ]; then cat "${outpath}$outputdownfile"; fi
		if [ "$men_smb" == "Y" ]; then cat "${outpath}$outputsmbfile" 2> /dev/null; fi
		if [ "$men_web" == "Y" ]; then cat "${outpath}$outputwebfile" 2> /dev/null; fi
		if [ "$men_ssl" == "Y" ]; then cat "${outpath}$outputsslfile" 2> /dev/null; fi
		if [ "$men_closed" == "Y" ]; then cat "${outpath}$outputclosedsummaryfile" 2> /dev/null; fi
		if [ "$men_report1" == "Y" ]; then cat "${outpath}$outputreport1file" 2> /dev/null; fi
		if [ "$men_hostports" == "Y" ]; then more "${hostportspath}"/*_*.txt 2> /dev/null; fi
	fi
fi
#end
}

function summay-log {
echo -e "\e[1m\e[93m[>]\e[0m Summary log"

if ! ls *.log 1>/dev/null 2>&1; then
	echo -e "$RED	- no .log files found $RESETCOL"
	echo ""
	return
fi

# fix: removed leading / from paths - $outpath already ends with /
# e.g. ${outpath}/hostslog.txt was producing parse//hostslog.txt
cat *.log | grep Discover | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort -u > "${outpath}hostslog.txt"

while read -r ip; do
    grep "$ip" *.log | grep "Disco" | awk -v ip="$ip" '{print ip ":" $4}' >> "${outpath}summarytemp.txt"
done < "${outpath}hostslog.txt"
cat "${outpath}summarytemp.txt" | sort -u > "${outpath}summary.log"
 echo "	- summary.log"
echo ""
#cat "${outpath}summary.log"
rm -rf "${outpath}hostslog.txt" "${outpath}summarytemp.txt" 2>/dev/null >/dev/null
}



########################
# MAIN 
########################

#cleanup
mastercleanup

# look trough and check inputfile and switches
for word in $(echo $*); do
	#echo $word
	if [[ $word == *".gnmap"* ]]; then
		#file+="$word "
		cat "$(realpath $word)" | sort -V >> $inputtemp
	fi
	# accept single-dash versions of switches
	case "$word" in
		-help) word="--help" ;;
		-all) word="--all" ;;
		-csv) word="--csv" ;;
		-summary) word="--summary" ;;
		-summarylog) word="--summarylog" ;;
		-unique) word="--unique" ;;
		-up) word="--up" ;;
		-down) word="--down" ;;
		-ipport) word="--ipport" ;;
		-smb) word="--smb" ;;
		-web) word="--web" ;;
		-ssl) word="--ssl" ;;
		-tcp) word="--tcp" ;;
		-udp) word="--udp" ;;
		-hostports) word="--hostports" ;;
		-closed) word="--closed" ;;
		-report1) word="--report1" ;;
		-html) word="--html" ;;
		-recursive|-r) word="--recursive" ;;
	esac
	if [ $word == "--help" ]; then
		helpmenu
		switch+="$word"
		exit
	fi
	if [ $word == "--csv" ]; then
		men_csv="Y"
		switch+="$word"
	fi
	if [ $word == "--summary" ]; then
		men_summary="Y"
		switch+="$word"
	fi
	if [ $word == "--summarylog" ]; then
		men_summarylog="Y"
		switch+="$word"
	fi
	if [ $word == "--unique" ]; then
		men_uports="Y"
		switch+="$word"
	fi
	if [ $word == "--up" ]; then
		men_uphosts="Y"
		switch+="$word"
	fi
	if [ $word == "--down" ]; then
		men_downhosts="Y"
		switch+="$word"
	fi
	if [ $word == "--ipport" ]; then
		men_ipport="Y"
		switch+="$word"
	fi
	if [ $word == "--smb" ]; then
		men_smb="Y"
		switch+="$word"
	fi
	if [ $word == "--web" ]; then
		men_web="Y"
		switch+="$word"
	fi
	if [ $word == "--ssl" ]; then
		men_ssl="Y"
		switch+="$word"
	fi
	if [ $word == "--tcp" ]; then
		men_tcpports="Y"
		switch+="$word"
	fi
	if [ $word == "--udp" ]; then
		men_udpports="Y"
		switch+="$word"
	fi
	if [ $word == "--hostports" ]; then
		men_hostports="Y"
		switch+="$word"
	fi	
	if [ $word == "--closed" ]; then
		men_closed="Y"
		switch+="$word"
	fi		
	if [ $word == "--report1" ]; then
		men_report1="Y"
		switch+="$word"
	fi
	if [ $word == "--html" ]; then
		men_htmlreport="Y"
		switch+="$word"
	fi	
	if [ $word == "--recursive" ] || [ $word == "--r" ]; then
		# enable recursive .gnmap file discovery
		men_recursive="Y"
		switch+="$word"
	fi
	if [ $word == "--all" ]; then
		#include 
		men_all="Y"
		men_csv="Y"
		men_summary="Y"
		men_uports="Y"
		men_tcpports="Y"
		men_udpports="Y"
		men_uphosts="Y"
		men_downhosts="Y"
		men_ipport="Y"
		men_smb="Y"
		men_ssl="Y"
		men_web="Y"
		men_hostports="Y"
		men_closed="Y"
		men_summarylog="Y"
		
		#exclude
		men_report1="N"
		men_htmlreport="N"

		#Create $outdir to put all outout in - stop spam
		createoutdir="Y"
		switch+="$word"
	fi	
done

# recursive discovery of .gnmap files
if [ "$men_recursive" == "Y" ]; then
	echo -e "\e[1m\e[93m[>]\e[0m Recursively searching for .gnmap files..."
	# exclude temp.gnmap from find - it lives in cwd and would cat into itself
	gnmap_count=$(find . -name "*.gnmap" -type f ! -name "$inputtemp" | wc -l | tr -d ' ')
	if [ "$gnmap_count" -gt 0 ]; then
		echo "[*] Found $gnmap_count .gnmap files"
		echo -n "[*] Loading..."
		find . -name "*.gnmap" -type f ! -name "$inputtemp" -print0 | xargs -0 cat >> "$inputtemp"
		echo -e "\r[*] $gnmap_count .gnmap files loaded"
	else
		echo "[*] No .gnmap files found"
	fi
	echo
fi

# does some checks on the input file to make sure its .gnmap + inspects the file to see its finished and has the right output flags -oA or -oG	
if [ -z "$(file "$(realpath $inputtemp)" | grep -o -e ASCII && head "$(realpath $inputtemp)" | grep -o -e "\-oA" -e "\-oG" && cat "$(realpath $inputtemp)")" ]; then
	helpmenu
	echo
	echo -e "\e[1m\e[91m[X] No input files FOUND - \e[5m.gnmap \e[25mfilename required - Must be nmap grepable! [X]\e[0m"
  	echo 
	exit 
fi



# check valid switches
if [ -z "$switch" ] 
then
	  helpmenu
	  echo 
      echo -e "\e[1m\e[91m[X] No Valid Switches FOUND - --csv, --all, etc.. [X]\e[0m"
	  echo 
	  exit  
fi

header 
                                      
# if all is selected make the outdir folder - stop the spam
if [ "$createoutdir" == "Y" ]
then 
	# fix: mkdir before realpath - macOS BSD realpath fails on non-existent paths
	mkdir $outdir > /dev/null 2>&1
	export outpath="$(realpath $outdir)/"
	#mv inputfile $outdir
	mv temp.gnmap $outdir
	export inputfilepath="$(realpath "$outdir/$inputtemp")"
else
	export outpath=$(pwd)"/"
	export inputfilepath="$(realpath $inputtemp)"
fi


#1 -- make csv file
if [ "$men_csv" == "Y" ]; then makecsv; fi
#2 - summary (uses makecsv)
if [ "$men_summary" == "Y" ]; then summary; fi
# rest
if [ "$men_ipport" == "Y" ]; then ipport; fi
if [ "$men_uports" == "Y" ]; then uniqueports;udpports-extra; fi
if [ "$men_tcpports" == "Y" ]; then	tcpports; tcpports-extra; fi
if [ "$men_udpports" == "Y" ]; then	udpports; fi
if [ "$men_uphosts" == "Y" ]; then uphosts; fi
if [ "$men_downhosts" == "Y" ]; then downhosts; fi
if [ "$men_smb" == "Y" ]; then smb; fi
if [ "$men_web" == "Y" ]; then web;webdirty; fi
#if [ "$men_web" == "Y" ]; then webdirty; fi
if [ "$men_ssl" == "Y" ]; then ssl; fi
if [ "$men_hostports" == "Y" ]; then hostports; fi
if [ "$men_closed" == "Y" ]; then closedsummary; fi
if [ "$men_report1" == "Y" ]; then report1; fi
if [ "$men_htmlreport" == "Y" ]; then htmlreport; fi
if [ "$men_summarylog" == "Y" ]; then summay-log; fi




# print output directory location so user knows where files landed
if [ "$createoutdir" == "Y" ]; then
	echo -e "\e[1m\e[93m[>]\e[0m Output directory: ${outpath}"
	echo
fi

# print footer once completed 
footer

# if yet print the results 
printresults


# remove comment to enable diagnostics function
#diagnostics


#cleanup
mastercleanup

# exit 
exit 0



#----------------------------------------------------------------- END OF SCRIPT -----------------------------------------------------------------
