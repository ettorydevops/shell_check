#!/bin/bash
set -eou pipefail

GREEN='\033[1;32m'
RED='\033[1;31m'
MAGENTA='\033[1;35m'
NC='\033[0m'

get_cpu_consumption(){
	pids=$(ps -eo pid,%cpu --sort=-%cpu | awk 'NR>1 && $2 >= 70 {print $1}')

	if [[ -n "$pids" ]]; then
    		printf "%b\n" "${MAGENTA}=== Processes Running: Above 70% (CPU) ===${NC}"
      		printf "\n"
    		ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | awk -v pids="$pids" 'NR==1 || index(" "pids" ", " "$1" ")'
	else
    		printf "%b\n" "${MAGENTA}=== Processes Running: Above 70% (CPU) ===${NC}"
			printf "\n"
    		printf "%b\n" "${GREEN}Nenhum processo está consumindo mais de 70% de CPU${NC}"
	fi
}

get_load_average(){
	cores=$(nproc)
	
	read load1 load5 load15 < <(cut -d ' ' -f1-3 /proc/loadavg | sed 's/,/./g')
	
	printf "\n%b\n" "${MAGENTA}=== Load Average (1, 5, 15 min) ===${NC}"
	printf "\n"
	printf "%b\n" "CPUs disponíveis: $cores"
 	printf "\n"
	LC_NUMERIC=C printf "1min:  %.2f\n5min:  %.2f\n15min: %.2f\n" "$load1" "$load5" "$load15"
	
	alert=$(awk -v l="$load1" -v c="$cores" '
	BEGIN {
	    if (l > c) {
		print "critical"
	    } else if (l > (c * 0.7)) {
		print "warning"
	    } else {
		print "ok"
	    }
	}'
	)
	
	case "$alert" in
	critical)
	    printf "%b\n" "${RED}\nALERTA: Load de 1 minuto acima do número de núcleos!\n${NC}"
	    ;;
	warning)
	    printf "%b\n" "${MAGENTA}\nAtenção: Load de 1 minuto está acima de 70% da capacidade total.\n${NC}"
	    ;;
	ok)
	    printf "\n"
	    printf "%b\n" "${GREEN}Load Average dentro do normal.${NC}"
	    ;;
	esac
}

cpu_check(){
	clear
	get_cpu_consumption
	get_load_average

	printf "\n${MAGENTA}Pressione ENTER para retornar ao menu...${NC}"
        read -r
}
