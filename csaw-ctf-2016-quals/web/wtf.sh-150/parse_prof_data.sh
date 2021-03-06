#!/usr/bin/env bash

# a parser for bash log files generated by adding the following code to your program:

#PS4='+ $(date "+%s.%N") $(if [[ ${FUNCNAME} = "" ]]; then echo NONE; else echo "${FUNCNAME}"; fi ) ${LINENO}\011 '
#exec 3>&2 2>/tmp/bashprof.$$.log
#set -x

LOGFILES=(/tmp/bashprof.*.log)

declare -A NUM_CALLS;
declare -A TOT_TIME;

n=0
for file in ${LOGFILES[@]}; do
    n=$((n+1));
    num_files=${#LOGFILES[@]}
    printf "\r[%${#num_files}d/%d]\t%s" "${n}" "${num_files}" "${file}" 1>&2;
    prevtime=0;
    prevkey='none';
    while read -r depth starttime function line code; do
        depth=${#depth};
        # if we're on the first entry, we'll just count it as 0 time,
        # since we can't have a time delta to base it off of.
        if [[ ${prevtime} = 0 ]]
        then
            prevtime=${starttime};
        fi
        duration=$(echo "${starttime}-${prevtime}" | bc);
        prevtime=${starttime};
        
        #echo "---------------------------";
        #echo "Depth: ${depth}";
        #echo "Duration (s): ${duration}";
        #echo "Function: ${function}";
        #echo "Line: ${line}";
        #echo "Code: ${code}";
        #echo "---------------------------";

        key="${function}:${line}";
        if [[ ${NUM_CALLS["${prevkey}"]} = '' ]]
        then
            NUM_CALLS["${prevkey}"]=1;
            TOT_TIME["${prevkey}"]=${duration}
        else
            NUM_CALLS["${prevkey}"]=$(( ${NUM_CALLS["$prevkey"]} + 1 ));
            TOT_TIME["${prevkey}"]=$(echo "${TOT_TIME["$prevkey"]} + ${duration}" | bc );
        fi
        prevkey="${key}";
    done < <(grep '^+' ${file})
done
printf "\n" 1>&2;




for key in ${!NUM_CALLS[@]}; do
    echo "${key} ${NUM_CALLS[${key}]} ${TOT_TIME[${key}]}"
done \
| sort --key=3.2 -n \
| while read -r key n dur; do
    echo "${key} (called ${n} times): ${dur}s";
done
