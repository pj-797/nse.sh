#!/bin/bash
function trap_all(){  			# set up for any interruptions and exit program cleanly
		rm -f /tmp/list1 &>/dev/null
		rm -f /tmp/list2 &>/dev/null
		exit 0
}
function script_info(){		# Display the script information
							# Display brief description of script
		tput reset
		script_path="script${number}"
		script="${!script_path}"
		content=$(nmap --script-help $script | tail -n +4)
		content2=$(while read -r line;do line="	$line"; echo "$line"; done <<< $content)
		sed "$number r /dev/stdin" /tmp/list1 <<< "$content2" > /tmp/list2
		echo -e "\033[1mScript(s) related to \"$keywords\":\033[0m"
		cat /tmp/list2
							# Display the web link and script code
		echo -ne "\nFor more details, press 'Enter'\nFor different script, enter 'Script Number'\nChoose your option (To quit, enter \"q\"): " && read choice
		if [ -z "$choice" ];then
			gnome-terminal -e "bash -c 'cat $script';bash" 2>/dev/null
			nmap --script-help $script | grep -v Starting | grep ".html" | grep -m 1 -i http | xargs open  2>/dev/null
		elif [ "$choice" == "q" ];then
			trap_all
		elif [[ $choice =~ ^[1-9]+$ ]]; then
			if (($choice > 0 && $choice <= $total_script)); then
				number="$choice"
				script_info "$number"
			fi
		else
			:
		fi
}		
function search_script(){	# search for .nse scripts
	case $total in
		1) script_list=$(locate *.nse | grep -i $word1);;
		2) script_list=$(locate *.nse | grep -i $word1 | grep -i $word2);;
		3) script_list=$(locate *.nse | grep -i $word1 | grep -i $word2 | grep -i $word3);;
	esac
	
							# display search results with help information
	tput reset
	echo -e "\033[1mScript(s) related to \"$keywords\":\033[0m"
	count=1
	for i in $script_list
	do
		echo -ne "\033[0;32m\e[1m$count) " && echo -e "$i\033[0m\e[0m" | awk -F/ '{print$NF}'
		var="script$count"	# assigning a number to each script
		eval "$var=\$(echo \"\$script_list\" | sed -n \"${count}p\")"
		count=$((count+1))
	done > /tmp/list1
							# if search result is None
	if [ -z "$script_list" ];then
		echo -e "\t0 script found related to '$keywords'. Try again."
		trap_all
	fi
	
	total_script=$(echo "$script_list" | wc -l)
	cat /tmp/list1
	while true
	do
		# Choice of script based on number		
		echo "" && read -p "Choose your Script Number (To quit, enter \"q\"): " number
		if [[ $number =~ ^[1-9]+$ ]]; then
			if (($number > 0 && $number <= $total_script)); then
				script_info "$number"
			fi
		# if user enter nothing, assumed default as script1 (first script)	
		elif [ -z "$number" ]; then
			number=1
			script_info "$number"
		# if user decided to quit
		elif [ "$number" == "q" ]; then
			trap_all
		fi
	done
}
rm -f /tmp/list1 &>/dev/null
rm -f /tmp/list2 &>/dev/null
trap "trap_all" 3 2
while true;do				# check if gnome-terminal is installed
	if [ "$(which gnome-terminal)" = "/usr/bin/gnome-terminal" ]
	then
		break
	else
		echo "Installing gnome-terminal..."
		sudo apt-get install gnome-terminal -y 	1>/dev/null
	fi
done
#sudo nmap --script-updatedb
total=$#
keywords="$@"
if [ $total == 0 ]; then
  echo -e "Usage: nse <argument1> <argument2> <argument3>\nMaximum is 3 arguments." 
  exit
fi
if [ $total -eq 1 ]; then
  word1=$1
fi
if [ $total -eq 2 ]; then
  word1=$1
  word2=$2
fi
if [ $total -eq 3 ] || [ $total -gt 3 ]; then
  word1=$1
  word2=$2
  word3=$3
  total=3
fi
search_script
