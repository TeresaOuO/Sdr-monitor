#!/bin/bash -
#===============================================================================
#
#          FILE:  SDR monitor.
#	  USAGE: ./sdr_monitor
#         NOTES: 1. Please install ipmitool before excute script.(Use VM)
#                2. Use outband ipmitool command, please check SUT BMC IP connect.
#                3.
#   DESCRIPTION: Collect SDR raw data and create csv.
#       OPTIONS: ---
#  REQUIREMENTS: 
#          BUGS: ---
#
#       AUTHORS: Teresa Chou 
#  ORGANIZATION: FOXCONN
#       CREATED: 2023/3/13
#      REVISION: v1.0
#===============================================================================
rm -rf sdr
# Setting
function setting() {	
	clear
	echo "================================================"
	echo "        Start with SDR Monitor script           "             
	echo "================================================"
	echo ""
	## Setting BMC IP
	read -p "Press BMC IP: " bmc_ip
	echo ""
	echo "Checking BMC IP -- "
	echo ""
	if  [ $(ping -c1 ${bmc_ip} |grep Unreachable|wc -l) -gt 0 ] ; then
		echo "BMC network is unreachable.Please check SUT BMC port link."
		exit 1
	fi
	echo -e "Ping BMC IP -- Success!!"
	## Setting excute time
	echo ""
	read -p "Press run time (minutes): " run_time
	echo ""
	read -p "Press time during per cycle (seconds): " during_time
}

function sdr_ipmitool_get() {
	TIME=$(date +"%Y-%m-%d_%H:%M:%S")
	ipmitool -H $bmc_ip -U Admin -P Admin sdr elist > Sdr_raw
}

function schedule(){
	sdr_ipmitool_get
	Sdr_num=$(cat Sdr_raw |wc -l)
	## Create CSV first line
	echo "Time, " > Sdr_tmp
	for ((a=2;a<=$Sdr_num;a++)) do
        	echo "$(cat Sdr_raw |awk 'NR=='$a'{print $1}'), " >> Sdr_tmp
	done
	Sdr_name=$(cat Sdr_tmp) 
	## Create CSV
	echo $Sdr_name > ${path}/sdr/$log_file
	## schedule
	TIME_START=$(date +"%s")
	TIME_RUN=$(echo |awk "{print int($run_time *60)}")
	TIME_END=$(( $TIME_START + $TIME_RUN ))
	echo ""
	echo "SDR monitor start."
	for ((n=1;n>0;n++)) do
		if  [ $(date +"%s") -gt $TIME_END ] ; then
			echo -e "\e[1;5;31;47m Time's up. \e[0m"
			exit
		else
			echo "SDR monitor Cycle $n."
			##sdr_record
			sdr_ipmitool_get
			echo "Sleep ${during_time} sec."
			sleep $during_time
			cp Sdr_raw $path/sdr/sdr_raw_data/Sdr_raw_"$n"			
			Sdr_num=$(cat Sdr_raw |wc -l)
			## Create CSV records
			echo "$TIME, " > Sdr_tmp
			for ((a=2;a<=$Sdr_num;a++)) do
				echo "$(cat Sdr_raw |awk 'NR=='$a'{print $9}' | sed -r 's/\|/ /g'), " >> Sdr_tmp
			done
			Sdr_val=$(cat Sdr_tmp) 
			echo $Sdr_val >> ${path}/sdr/$log_file	
		fi	
	done
	

}

# SDR Procedure
setting
pwd > path
path=$(cat path)
mkdir sdr
cd sdr
mkdir sdr_raw_data
log_file=Sdr-"$bmc_ip"-ipmitool.csv
schedule