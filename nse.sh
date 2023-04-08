#!/bin/bash
function search_script(){	# search for .nse scripts
	case $total in
		1) script_list=$(locate *.nse | grep -i $word1);;
		2) script_list=$(locate *.nse | grep -i $word1 | grep -i $word2);;
		3) script_list=$(locate *.nse | grep -i $word1 | grep -i $word2 | grep -i $word3);;
	esac	
	# display search results with help information
	count=1
	for i in $script_list
	do
		echo -ne "\033[0;32m\e[1m$count) " && echo -e $i | awk -F/ '{print$NF}' && echo -ne "\e[0m\033[0m"
		content=$(nmap --script-help $i | tail -n +4)
		while read -r line;do line="	$line"; echo "$line"; done <<< $content
		echo ""
		# assign each script to variable according to number e.g. script1 script2 script3 etc...
		var="script$count"
		eval "$var=\$(echo \"\$script_list\" | sed -n \"${count}p\")"
		count=$((count+1))
	done
	# if search result is None
	if [ -z "$script_list" ];then
		echo -e "\t0 script found related to '$keywords'. Try again$script_list."
		exit
	fi
	total_script=$(echo "$script_list" | wc -l)
	while true
	do
		# allow user to view more information on specific script selected
		read -p "For more details, choose your Script Number (To quit, enter \"q\"): " number
		if [[ $number =~ ^[0-9]+$ ]]; then
			if (($number >= 0 && $number <= $total_script)); then
				script_path="script${number}"
				script="${!script_path}"
				gnome-terminal -e "bash -c 'cat $script';bash" 2>/dev/null
				nmap --script-help $script | grep -v Starting | grep ".html" | grep -m 1 -i http | xargs open  2>/dev/null
			fi
		# if user enter nothing, assumed default as script1 (first script)	
		elif [ -z "$number" ]; then
			gnome-terminal -e "bash -c 'cat $script1';bash" 2>/dev/null
			nmap --script-help $script1 | grep -v Starting | grep ".html" | grep -m 1 -i http | xargs open  2>/dev/null
		# if user decided to quit
		elif [ "$number" == "q" ]; then
			exit
		fi
	done
}
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
