#!/usr/bin/env bash

# --- Colors ------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
ORANGE='\033[1;49;91m'
BLUE='\033[0;34m'
LPURPLE='\033[1;35m'
NC='\033[0m' # No Color

# --- Default values ----------------------------------------------------------
BAR_DATA=false #hatakkaj-receiver
ICOS_DATA=false #icos-downloader
HY_DATA=false #rclone
FMI_DATA=false #meteo data
SMHI_DATA=false
DATASENSE_DATA=false
GAPFILLING_DATA=false #Henriikka's gap filling
SMEAR_DATA=false #hy smear flux
ECTOUI_DATA=false
RADOBS_DATA=false
SATOBS_DATA=false
GEOJSON_DATA=false # updating geojsons

DO_ALL=false

VERBOSE=false
DEBUGGING=false
MAIN_PATH='/cephfs/fmipecan/openshift/'
LOGS_PATH=${MAIN_PATH}'field-observatory/logs/'
SITECONFIG_FILE=${MAIN_PATH}'field-observatory/field-observatory_sites.geojson'
BLOCKCONFIG_FILE=${MAIN_PATH}'field-observatory/field-observatory_blocks.geojson'
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
HOURS=2
SEARCH=""
SEARCHING=false
PRINT_LEVEL="ALL"
DAYS=2
PRINT_ENDED=false
PRINT_STAT_HEADER=true

TAG="MAIN"
COLS=$(tput cols)
LINE=$(printf -- '-%.0s' $(seq $COLS); printf "\n")

# uses associative array so bash specific and new bash required
declare -A BLOCK_DATA_ENDS
declare -A SITE_DATA_ENDS

# --- Helper functions --------------------------------------------------------

print_line() {
    if [[ $PRINT_LEVEL != 'STAT' ]]; then
        echo -e ${BLUE}${LINE}${NC}
    fi
}

usage() {
    cat <<EOF

Usage: $0 [OPTIONS]

Options:
  --datasense         Do Datasense check
  --bar               Do bar data check
  --icos              Do ICOS log check
  --hy                Do HY rclone check
  --smhi              DO SMHI check
  --fmi               Do FMI data check
  --gapfilling        Do Gap Filling check
  --smear             Do SMEAR check
  --ectoui            Do EC to UI update check
  --radobs            Do RadObs checks 
  --satobs            Do SatObs checks
  --geojson           Do geojson update checks
  --do-all            Do all the above
  --ended             Print also the sites/blocks that have data_end
  --noheader          Do not print stat header
  --search <this>     Search the word from result line (Works for FMI)
  --year <year>       Use given year (default: today's year)
  --month <month>     Use given month (default: today's month) remember to pad 1-9 with a 0
  --day <day>         Use given day (default: today's day) remember to pad 1-9 with a 0
  --hours <hours>     Use hour offset (default: 2 ) (positive int)
  --days <days>       How many days before something is considered as old (positive int, default: 2)
  --level <level>     Print only this level (default: all, allowed INFO WARN ERROR SEARCH DEBUG)
  --debug             Debug printing (also triggers --verbose)
  --verbose           Print more than usual
  -h, --help          Show this help and exit

Examples:
  $0 --year 2025 --month 03
  NOTE! the fill zero in month (also in day)

EOF
}

log() {
    local level="$1"; shift
    local color="${GREEN}"
    case "$level" in
        INFO) color="${GREEN}" ;;
        WARN) color="${YELLOW}" ;;
        ERROR) color="${RED}" ;;
        SEARCH) color="${ORANGE}" ;;
        DEBUG)
            if $DEBUGGING; then 
                color="${LPURPLE}"
            else
                return 
            fi
            ;;
        *) color="${BLUE}" ;;
    esac
    PRINT=false
    if [[ $PRINT_LEVEL == "ALL" ]] || \
       [[ $level == ${PRINT_LEVEL^^} ]] || \
       [[ $level == "RUNINFO" ]]; then
        PRINT=true
    fi
    if [[ $PRINT_LEVEL == 'STAT' ]] && [[ $level == "RUNINFO" ]]; then
        PRINT=false
    fi
    if $PRINT; then
        echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')][$level][$TAG]${NC} $1"
        # if we have the second argument and we want more output
        if [[ $# == 2 ]]; then
            if $VERBOSE; then echo "$2"; fi
        fi
    fi
}

print_stat_header() {
    if [[ $PRINT_LEVEL == 'STAT' ]] && $PRINT_STAT_HEADER; then 
        echo "Checked at $(date '+%Y-%m-%d %H:%M')"
        echo "Module, Err, Warn, Old, Notime, Eventfile, PythonWarn"      
    fi
}

print_stat_line() {
    local mod=""
    local err=0
    local warn=0
    local warnold=0
    local notime=0
    local eventfiles=0
    local future=0
    if (( $# > 0 )); then mod=$1; fi 
    if (( $# > 1 )); then err=$2; fi
    if (( $# > 2 )); then warn=$3; fi
    if (( $# > 3 )); then warnold=$4; fi
    if (( $# > 4 )); then notime=$5; fi
    if (( $# > 5 )); then eventfiles=$6; fi
    if (( $# > 6 )); then future=$7; fi

    echo -e "$mod, $err, $warn, $warnold, $notime, $eventfiles, $future"
}

run_info() {
    # will print this as blue
    TAG="MAIN"
    log RUNINFO "Reading from $MAIN_PATH"
    log RUNINFO "Using date: $YEAR-$MONTH-$DAY"  
    log RUNINFO "Using $DAYS days as cut of date for recent results"
    log RUNINFO "Using -$HOURS to for offset the hours"
    if [[ "ALL" != $PRINT_LEVEL ]]; then 
        log RUNINFO "Print only $PRINT_LEVEL msgs"
    fi    
    if $SEARCHING; then 
        log RUNINFO "Searching for lines with: $SEARCH (used only in FMI)"
    fi
    if $DEBUGGING; then 
       log RUNINFO "Mode: DEBUG + VERBOSE"
    fi 
    if ! $DEBUGGING && $VERBOSE; then
       log RUNINFO "Mode: VERBOSE"
    fi
}

get_site_data_ends() {
    local i=0 
    while IFS="" read -r line; do
        #echo '**'"$line"'**'
        if [[ $line == *\"site\":* ]] && (( i==0 )); then
            local site=${line##* }
            site=${site//\"/}
            site=${site//,/}
            i=1
        fi
        if [[ $line == *\"data_end\":* ]] && (( i==1 )); then
            local dend=${line##* }
            dend=${dend//\"/}
            dend=${dend//,/}
            dend=${dend%%T*}
            i=2
        fi
        if (( i==2 )); then
           #echo Current $site $dend 
           # store the data end
           SITE_DATA_ENDS[$site]=$dend
           i=0
        fi
           
    done < $SITECONFIG_FILE
}

get_block_data_ends() {
    local i=0 
    while IFS="" read -r line; do
        #echo '**'"$line"'**'
        if [[ $line == *\"block\":* ]] && (( i==0 )); then 
            local block=${line##* }
            block=${block//\"/}
            block=${block//,/}
            i=1
        fi 
        if [[ $line == *\"site\":* ]] && (( i==1 )); then
            local site=${line##* }
            site=${site//\"/}
            site=${site//,/}
            i=2
        fi
        if [[ $line == *\"data_end\":* ]] && (( i==2 )); then
            local dend=${line##* }
            dend=${dend//\"/}
            dend=${dend//,/}
            dend=${dend%%T*}
            i=3
        fi
        if (( i==3 )); then
           #echo Current $site $block $dend 
           # store the data end
           BLOCK_DATA_ENDS[$site'_'$block]=$dend
           i=0
        fi
           
    done < $BLOCKCONFIG_FILE
}

# --- funtions ----------------------------------------------------------------

datasense_data() {
    TAG="DATASENSE"
    log WARN "# Datasense check not implemented, Not used!"
    print_stat_line $TAG 0 1 0 0
    print_line
}

bar_data() {
    TAG='BARData'
    shopt -s nullglob
    local err_count=0
    local old_count=0
    local bar_path=${MAIN_PATH}'BARData/'
    for dir in ${bar_path}*/flux/res ${bar_path}*/pyflux/res; do
        local no_error=true
        log DEBUG "Next -> $dir"
        local files=("$dir"/*$"$YEAR"-"$MONTH".csv)
        # Get site
        IFS='/' read -ra SITESPLIT <<< "$dir"
        local site=${SITESPLIT[5]}
        if (( ${#files[@]} == 0 )); then
            log ERROR "Site: ${site}: No file !!"
            ((err_count++))
            no_error=false
        else
            for file in "${files[@]}"; do
                log DEBUG "File -> $file"
                local last_line="$(tail -n 1 $file 2>&1)"
                local last_date=${last_line:0:16}
                local day=${last_date:8:2}
                log DEBUG "Last date: $last_date" "$last_line"
                # timestamp(now) - timestamp(last_date) / seconds in a day
                let DIFF=($(date +%s -d $YEAR$MONTH$DAY)-$(date +%s -d ${last_date:0:10}))/86400
                if (( $DIFF > $DAYS )); then
                    log ERROR "Site: ${site}, last date: $last_date"
                    ((old_count++))
                    no_error=false
                fi
            done
        fi
        if $no_error; then
             log INFO "Site: ${site}, OK!"
        fi
    done
    shopt -u nullglob
    print_stat_line $TAG $err_count 0 $old_count 0
    print_line
}

icos_data() {
    TAG='ICOS'
    local log_path=${LOGS_PATH}'icos-downloader-cronjob.log'
    # OK line
    # [1] "[2025-12-04 14:27:28.702073] Handling: BE-Lon"
    # Error line
    # [1] "[2025-12-04 14:06:22.318165] Error: BE-Lon: small meteo zip (112350)"    
    # If all goes wrong it will drop [1] and just output the error msg 
    # Error in utils::unzip(zip_file_name, list = TRUE) : 
    #   zip file '/data/ICOS/DE-Geb/data/ICOSETC_DE-Geb_METEO_NRT.zip' cannot be opened
    # Calls: grep -> is.factor -> <Anonymous>
    # Execution halted
    local lines=$(grep $YEAR-$MONTH-$DAY ${log_path} | grep Error)  
    local no_error=true
    local err_count=0
    while IFS="" read -r line; do
        if [[ ! -z $line ]]; then 
           log ERROR "$line"
           ((err_count++))
           no_error=false
        fi
    done <<< "$lines" 
    if $no_error; then 
        log INFO "Log, OK!"
    fi
    print_stat_line $TAG $err_count
    print_line
}

hy_data() {
    TAG='HY'
    shopt -s nullglob
    local log_path=${LOGS_PATH}'hy-rclone-cronjob.log'
    # OK Line that need to be found
    # 2025/12/08 06:15:32 INFO  : viikki_fluxres_2025-12.csv: Copied (replaced existing)
    local lines=$(grep $YEAR/$MONTH/$DAY ${log_path} | grep -E $YEAR-$MONTH)
    local i=0
    local err_count=0
    local old_count=0
    while IFS="" read -r line; do
        if [[ ! -z $line ]]; then
            log DEBUG "$line"
            ((i++))
        fi
    done <<< "$lines" 
    if (( i == 0 )); then
        log ERROR "No current month log lines found"
        ((err_count++))
    fi
    #do file check for flux
    local viikki_file_path=${MAIN_PATH}'hy-eddy2/data/viikki_fluxres_'${YEAR}'-'${MONTH}'.csv'
    local files=($viikki_file_path)
    if (( ${#files[@]} == 0 )); then
        log ERROR "Did not find current month Viikki fluxres"
        ((err_count++))
    else
        # there is only one file
        local last_line="$(tail -n 1 ${files[0]})"
        local last_date=${last_line:0:10}
        local last_time=${last_line:11:5}
        log INFO "Fluxres file found last date: ${last_date}, last time: ${last_time}"
        let DIFF=($(date +%s -d $YEAR$MONTH$DAY)-$(date +%s -d ${last_date}))/86400
        if (( $DIFF > $DAYS )); then
            log ERROR "Site: ${site}: last date: $last_date !!"
            ((old_count++))
        else
            log INFO "Fluxres file, OK!"
        fi
    fi   
    shopt -u nullglob
    print_stat_line $TAG $err_count 0 $old_count
    print_line
}

fmi_data() {
    TAG='FMI'
    shopt -s nullglob
    # what to check 
    # NOTE that the month does not have padding zero...
    # /data/field-observatory/observations/haltiala/fmimeteo/observations/2025-12.csv
    local sites=(${MAIN_PATH}field-observatory/observations/*)
    local i=0
    local err_count=0
    local warn_count=0
    local old_count=0
    local notime_count=0
    while (( i < ${#sites[@]} )); do
        # folder had some extra log files so while at it skip them.
        local file_ending=${sites[i]##*.} 
        if [[ "log" != "${file_ending}" ]]; then
            log DEBUG "################################"
            local site=${sites[$i]##*/}
            local file=(${sites[$i]}'/fmimeteo/observations/'$YEAR-$MONTH'.csv')
            if [[ ! -f $file ]]; then
                log ERROR "Site: ${site}, no monthly file"
                log DEBUG "$(echo '...'; ls ${sites[$i]}'/fmimeteo/observations/'* | tail -n 4)"
                ((err_count++))
            else
                #only one file for the month
                local last_line=$(tail -n 1 ${file})
                if ! $SEARCHING; then
                    if [[ ${last_line:1:4} != $YEAR ]]; then
                        log WARN "Site: $site, no year on last line, File: ${file##*/}" "$last_line"
                        log DEBUG "$file"
                        ((notime_count++))
                    else
                        # should be at least the same year check the rest
                        # note this file has " around time
                        local last_date=${last_line:1:10}
                        let DIFF=($(date +%s -d $YEAR$MONTH$DAY)-$(date +%s -d ${last_date}))/86400
                        if (( $DIFF > $DAYS )); then
                            log WARN "Site: $site File: ${file##*/}" "$last_line"
                            log ERROR "Site: ${site}: last date: $last_date"
                            ((old_count++))
                        else
                            log DEBUG "$file" "$last_line"
                            log INFO "Site: $site, OK!"
                        fi
                    fi
                else
                    # Print only lines that match
                    if [[ $last_line == *"${SEARCH}"* ]]; then
                        log SEARCH  $file
                        log SEARCH "$last_line"
                    fi 
                fi
            fi
        fi
        (( i++ ))
    done
    shopt -u nullglob
    print_stat_line $TAG $err_count $warn_count $old_count $notime_count
    print_line
}

smhi_data() {
    TAG='SMHI'
    # LOG
    local err_count=0
    local warn_count=0
    local old_count=0
    local notime_count=0
    local log_path=${LOGS_PATH}'fieldobs-smhi-cronjob.log'
    local last_line=$(tail -n 1 $log_path 2>&1)
    if [[ ${last_line:0:4} != $YEAR ]]; then
        log ERROR "No year on line start" "${last_line}"
        ((err_count++))
    else 
        local last_date=${last_line:0:10}
        let DIFF=($(date +%s -d $YEAR$MONTH$DAY)-$(date +%s -d ${last_date}))/86400
        if (( $DIFF > $DAYS )); then
            log WARN "Log file, last date: $last_date" "${last_line}"
            ((warn_count++))
        else
            log INFO "Log file, OK!" "$last_line"
        fi
    fi
    # data
    # ui-data/hoja/smhimeteo/{daily,hourly}
    local file=${MAIN_PATH}'field-observatory/ui-data/hoja/smhimeteo/daily/'${YEAR}.csv
    if [[ ! -f ${file} ]]; then
        log ERROR "No daily file found for ${YEAR}"
        ((err_count++))
    else
        local last_line=$(tail -n 1 ${file})
        local last_date=${last_line:0:10}
        let DIFF=($(date +%s -d $YEAR$MONTH$DAY)-$(date +%s -d ${last_date}))/86400
        if (( $DIFF > $DAYS )); then
            log WARN "Daily file, last date: $last_date" "$last_line"
            ((warn_count++))
        else
            log INFO "Daily file, OK!" "$last_line"
        fi
   fi
    local file=${MAIN_PATH}'field-observatory/ui-data/hoja/smhimeteo/hourly/'${YEAR}-${MONTH}.csv
    if [[ ! -f ${file} ]]; then
        log ERROR "No hourly file found for ${YEAR} ${MONTH}"
        ((err_count++))
    else
        if (( $DIFF > $DAYS )); then
            log WARN "Hourly file, last date: $last_date" "$last_line"
            ((warn_count++))
        else
            log INFO "Hourly file, OK!" "$last_line"
        fi
    fi
    print_stat_line $TAG $err_count $warn_count $old_count $notime_count
    print_line
}

gapfilling_data() {
    TAG='GAP'
    # LOG
    local log_file=${LOGS_PATH}'fieldobs-ecsites-run-gapfilling-cronjob.log'
    local todays_lines=$(sed -n '/'${YEAR}'-'${MONTH}'-'${DAY}'/,$p' ${log_file} 2>&1)
    local err_count=0
    local warn_count=0
    local old_count=0
    local notime_count=0
    local first_timestr=""
    local last_timestar=""
    local first_timestamp=""
    local last_timestamp=""
    while IFS="" read -r line; do
        if [[ ! -z $line ]]; then
            if [[ $YEAR != ${line:0:4} ]]; then
                if $VERBOSE; then
                   log WARN "$line"
                fi
                ((notime_count++))
            else
                if (( notime_count == 0 )); then
                    first_timestr=${line:0:19}
                    first_timestamp=$(date +%s -d "${first_timestr}")
                else
                    last_timestr=${line:0:19}
                    last_timestamp=$(date +%s -d "${last_timestr}")
                fi
            fi
        fi
    done <<< "$todays_lines"    
    if [[ -z "$todays_lines" ]]; then 
        log ERROR "No log lines for today"
        ((err_count++))
    else
        let DIFF=($last_timestamp - $first_timestamp)/60
        log DEBUG "First time: ${first_timestr}, last time: ${last_timestr}" 
        log DEBUG "First timestamp: $first_timestamp, last timestamp: $last_timestamp"
        log INFO "Logged $DIFF minutes of runtime (does not include the last fill)"
    fi
    # DATA
    local gap_path=${MAIN_PATH}'field-observatory/gapfilled_fluxes/'
    local sites="${gap_path}*"
    for s in $sites; do
        local site=${s##*/}
        local data_path=${gap_path}${site}'/'${site}'_gapfilled_data.csv'
        log DEBUG "$data_path"
        local last_line=$(tail -n 1 ${data_path})
        local last_date=${last_line:0:10}
        let DIFF=($(date +%s -d $YEAR$MONTH$DAY)-$(date +%s -d ${last_date}))/86400
        if (( $DIFF > $DAYS )); then
            log WARN "Site: $site data file, last date: $last_date" "$last_line"
            ((old_count++))
        else
            log INFO "Site: $site: data file, OK!" "$last_line"
        fi
       log DEBUG "$last_line"
    done    
    print_stat_line $TAG $err_count $warn_count $old_count $notime_count
    print_line
}

smear_data() {
    TAG='SMEAR'
    # LOG usefull only if something is totally wrong (no times in log file)
    local err_count=0
    local warn_count=0
    local old_count=0
    local notime_count=0
    local log_file=${LOGS_PATH}'fieldobs-ecsites-update-smear-flux-to-observations-cronjob.log'
    local data_path=${MAIN_PATH}'field-observatory/observations/viikki/smear_flux/'$YEAR'-'$MONTH'.csv'
    if [[ ! -f $data_path ]]; then 
        log ERROR 'Viikki, no monthly file for '$YEAR'-'$MONTH "$data_path"
        ((err_count++))
    else
        local last_line=$(tail -n 1 ${data_path} 2>&1)
        local last_date=${last_line:0:10}
        let DIFF=($(date +%s -d $YEAR$MONTH$DAY)-$(date +%s -d ${last_date}))/86400
        if (( $DIFF > $DAYS )); then
            log WARN "Viikki: monthly file, last date: $last_date" "$last_line"
            ((old_count++))
        else
            log INFO "Viikki: montly file, OK!" "$last_line"
        fi 
    fi
    print_stat_line $TAG $err_count $warn_count $old_count $notime_count
    print_line
}

ectoui_data() {
    TAG='ECTOUI'
    local log_file=${LOGS_PATH}'fieldobs-ecsites-update-ec-data-to-ui-cronjob.log'
    local err_count=0
    local warn_count=0
    local old_count=0
    local notime_count=0
    local noevents_count=0
    local futurewarn_count=0
    # offset the hour back... at least for now the HELSINKI UTC ERROR is the reason
    # Example given HOURS 2 and now is 10:00:00 so $hour is going to be 8:00:00 and $nhour 9:00:00
    local hour=$(date -d "-$HOURS hour" +%H)
    let  n=$HOURS-1
    local nhour=$(date -d "-$n hour" +%H)
    log DEBUG "Getting from hour $hour to $nhour"
    local todays_lines=$(sed -n '/'${YEAR}'-'${MONTH}'-'${DAY}' '${hour}':/,$p' ${log_file} | \
                         sed -n '/'$YEAR'-'${MONTH}'-'${DAY}' '${nhour}':/q;p')
    local first_timestr=""
    local last_timestar=""
    local first_timestamp=""
    local last_timestamp=""
    while IFS="" read -r line; do
        if [[ ! -z $line ]]; then
            if [[ $YEAR != ${line:0:4} ]]; then
                if $VERBOSE; then
                   log WARN "$line"
                fi
                ((notime_count++))
                if [[ $line == *'No events'* ]]; then ((noevents_count++)); fi
                if [[ $line == *'FutureWarning'* ]]; then ((futurewarn_count++)); fi
            else
                if (( notime_count == 0 )); then
                    first_timestr=${line:0:19}
                    first_timestamp=$(date +%s -d "${first_timestr}")
                else
                    last_timestr=${line:0:19}
                    last_timestamp=$(date +%s -d "${last_timestr}")
                fi
            fi
        fi
    done <<< "$todays_lines"    
    if [[ -z "$todays_lines" ]]; then 
        log ERROR "No log lines for today"
        ((err_count++))
    else
        let DIFF=($last_timestamp - $first_timestamp)/60
        log DEBUG "First time: ${first_timestr}, last time: ${last_timestr}" 
        log DEBUG "First timestamp: $first_timestamp, last timestamp: $last_timestamp"
        log INFO "Logged $DIFF minutes of runtime"
        if (( $DIFF > 30 )); then
            log WARN "Took a long time"
            ((warn_count++))
        fi
    fi
    print_stat_line $TAG $err_count $warn_count $old_count $notime_count $noevents_count $futurewarn_count
    print_line
}

radobs_data() {
    TAG='RADOBS'
    local log_file=${LOGS_PATH}'fieldobs-radobs-cronjob.log'
    local lines=$(grep $YEAR-$MONTH-$DAY ${log_file} 2>&1)
    local i=0
    local err_count=0
    local warn_count=0
    local old_count=0
    local notime_count=0
    local first_timestr=""
    local last_timestar=""
    local first_timestamp=""
    local last_timestamp=""
    local sites=""
    local previous_line=""
    while IFS="" read -r line; do
        if [[ ! -z $line ]]; then
            log DEBUG "$line"
            # skip the ones that have the already up-to-date on the next line
            # the data is not updated any more
            if [[ $line != *'Already up-to-date,'* ]]; then
                if [[ $previous_line == *'Updating'* ]]; then
                    local site=${previous_line##* } 
                    if [[ -z $sites ]]; then
                        sites=$site
                    else
                        sites=$sites' '$site
                    fi
                fi 
            fi
            if [[ $line == *'ERROR'* ]]; then 
                ((err_count++))
                if $VERBOSE && ! $DEBUGGING; then
                    log ERROR "$line"
                fi
            fi
            if [[ $YEAR != ${line:0:4} ]]; then
                ((notime_count++))
                if $VERBOSE && ! $DEBUGGING; then
                    log WARN "$line"
                fi
            else
                if (( i == 0 )); then
                    first_timestr=${line:0:19}
                    first_timestamp=$(date +%s -d "${first_timestr}")
                else
                    last_timestr=${line:0:19}
                    last_timestamp=$(date +%s -d "${last_timestr}")
                fi
            fi
            previous_line=$line
            ((i++))
    fi
    done <<< "$lines"
    if [[ -z "$lines" ]]; then 
        log ERROR "No log lines for today"
        ((err_count++))
    else
        let DIFF=($last_timestamp - $first_timestamp)/60
        log DEBUG "First time: ${first_timestr}, last time: ${last_timestr}" 
        log DEBUG "First timestamp: $first_timestamp, last timestamp: $last_timestamp"
        log INFO "Logged $DIFF minutes of runtime"
        if (( $DIFF > 30 )); then
            log WARN "Took a long time"
            ((warn_count++))
        fi
        if (( $err_count>0 )); then 
            log ERROR 'Error count '$errors' (--verbose)'

        else
            log INFO 'No logged errors'
        fi
        if (( $notime_count > 0 )); then
            log WARN $notime' lines without time (--verbose)'
        fi
    fi
    # Data checking
    for s in $sites; do
        local irradiation=${MAIN_PATH}'field-observatory/observations/'${s}'/cams/'${s}'_cams_irradiation.csv'
        local last_line=$(tail -n 1 $irradiation)
        local last_date=${last_line:0:10}
        let DIFF=($(date +%s -d $YEAR$MONTH$DAY)-$(date +%s -d ${last_date}))/86400
        if (( $DIFF > $DAYS )); then
            log WARN "${s}: irradiation file, last date: $last_date" "$last_line"
            ((old_count++))
        else
            log INFO "${s}: irradiation file, OK!" "$last_line"
        fi 
    done
    print_stat_line $TAG $err_count $warn_count $old_count $notime_count
    print_line
}

satobs_data() {
    TAG='SATOBS'
    local log_file=${LOGS_PATH}'fieldobs-satobs-cronjob.log'
    local lines=$(grep $YEAR-$MONTH-$DAY ${log_file} 2>&1)
    local i=0
    local err_count=0
    local warn_count=0
    local old_count=0
    local notime_count=0
    local first_timestr=""
    local last_timestar=""
    local first_timestamp=""
    local last_timestamp=""
    local sites_fields=""
    while IFS="" read -r line; do
        if [[ ! -z $line ]]; then
            log DEBUG "$line"
            if [[ $line == *'Updating'* ]]; then
                local site=${line##* } 
                if [[ -z $sites_fields ]]; then
                    sites_fields=$site
                else
                    sites_fields=$sites_fields' '$site
                fi
            fi 
            if [[ $line == *'ERROR'* ]]; then 
                ((err_count++))
                if $VERBOSE && ! $DEBUGGING; then
                    log ERROR "$line"
                fi
            fi
            if [[ $YEAR != ${line:0:4} ]]; then
                ((notime_count++))
                if $VERBOSE && ! $DEBUGGING; then
                    log WARN "$line"
                fi
            else
                if (( i == 0 )); then
                    first_timestr=${line:0:19}
                    first_timestamp=$(date +%s -d "${first_timestr}")
                else
                    last_timestr=${line:0:19}
                    last_timestamp=$(date +%s -d "${last_timestr}")
                fi
            fi
            ((i++))
    fi
    done <<< "$lines"
    if [[ -z "$lines" ]]; then 
        log ERROR "No log lines for today"
        ((err_count++))
    else
        let DIFF=($last_timestamp - $first_timestamp)/60
        log DEBUG "First time: ${first_timestr}, last time: ${last_timestr}" 
        log DEBUG "First timestamp: $first_timestamp, last timestamp: $last_timestamp"
        log INFO "Logged $DIFF minutes of runtime"
        if (( $DIFF > 30 )); then
            log WARN "Took a long time"
            ((warn_count++))
        fi
        if (( $err_count>0 )); then 
            log ERROR 'Error count '$errors' (--verbose)'
        else
            log INFO 'No logged errors'
        fi
        if (( $notime_count > 0 )); then
            log WARN $notime' lines without time (--verbose)'
        fi
    fi
    # Data checking
    local block_count=0
    for s in $sites_fields; do
        # site_field split
        local site=${s%%_*}
        local field=${s##*_}
        # known good days
        local path=${MAIN_PATH}'field-observatory/observations/'${site}'/'${field}'/sentinel2/timeseries/'${site}'_'${field}'_ci_red_edge.csv'
        local last_line=$(tail -n 1 ${path} 2>&1)
        local last_date=${last_line:0:10}
        # the last line in some gi files contains a linefeed and is actually on two lines
        # quickly checking if the start is the year so it would be start of the correct line
        local qi_path=${MAIN_PATH}'field-observatory/observations/'${site}'/'${field}'/sentinel2/'${site}'_'${field}'_s2_qi_observations.csv'
        local qi_last_lines=$(tail -n 2 ${qi_path} 2>&1)
        while IFS="" read -r line; do
            local testing=$(date -d "${line:0:10}" 2>: 1>:; echo $?) 
            if (( $testing == 0 )); then
                local qi_last_date=${line:0:10}
            fi
        done <<< "$qi_last_lines"
        local sitedataend=${SITE_DATA_ENDS[$site]}
        local blockdataend=${BLOCK_DATA_ENDS[$s]}
        if [[ $sitedataend == "null" ]] || $PRINT_ENDED ; then 
            if [[ $blockdataend == "null" ]] || $PRINT_ENDED ; then       
                ((block_count++))
                let DIFF=($(date +%s -d $YEAR$MONTH$DAY)-$(date +%s -d ${qi_last_date}))/86400
                if (( $DIFF > $DAYS )); then
                    log WARN "${s}: qi file, last date: $qi_last_date (good OBS: ${last_date})" "$qi_last_line"
                    log DEBUG "$last_line"
                    ((old_count++))
                else
                    log INFO "${s}: qi file, OK: $qi_last_date (good OBS: ${last_date})" "$last_line"
                    log DEBUG "$last_line"
                fi
            fi
        fi
    done
    log INFO "${block_count} blocks (also ended blocks: ${PRINT_ENDED})"
    print_stat_line $TAG $err_count $warn_count $old_count $notime_count
    print_line
}

geojson_data() {
    TAG='GEOJSONS'
    local log_file=${LOGS_PATH}'fieldobs-update-ui-geojsons-cronjob.log'
    # offset the hour back... at least for now the HELSINKI UTC ERROR is the reason
    # Example given HOURS 2 and now is 10:00:00 so $hour is going to be 8:00:00 and $nhour 9:00:00
    local hour=$(date -d "-$HOURS hour" +%H)
    let  n=$HOURS-1
    local nhour=$(date -d "-$n hour" +%H)
    log DEBUG "Getting from hour $hour to $nhour"
    local hours_lines=$(sed -n '/'${YEAR}'-'${MONTH}'-'${DAY}' '${hour}':/,$p' ${log_file} | \
                         sed -n '/'$YEAR'-'${MONTH}'-'${DAY}' '${nhour}':/q;p')
    local first_timestr=""
    local err_count=0
    local warn_count=0
    local old_count=0
    local notime_count=0
    local last_timestar=""
    local first_timestamp=""
    local last_timestamp=""
    while IFS="" read -r line; do
        if [[ ! -z $line ]]; then
            log DEBUG "$line"
            if [[ $line == *'ERROR'* ]]; then 
                ((err_count++))
                if $VERBOSE && ! $DEBUGGING; then
                    log ERROR "$line"
                fi
            fi
            if [[ $YEAR != ${line:0:4} ]]; then
                ((notime_count++))
                if $VERBOSE && ! $DEBUGGING; then
                    log WARN "$line"
                fi
            else
                if (( i == 0 )); then
                    first_timestr=${line:0:19}
                    first_timestamp=$(date +%s -d "${first_timestr}")
                else
                    last_timestr=${line:0:19}
                    last_timestamp=$(date +%s -d "${last_timestr}")
                fi
            fi
            ((i++))
    fi
    done <<< "$hours_lines"
    if [[ -z "$hours_lines" ]]; then 
        log ERR "No log lines for today"
        ((err_count++))
    else
        let DIFF=($last_timestamp - $first_timestamp)/60
        log DEBUG "First time: ${first_timestr}, last time: ${last_timestr}" 
        log DEBUG "First timestamp: $first_timestamp, last timestamp: $last_timestamp"
        log INFO "Logged $DIFF minutes of runtime"
        if (( $DIFF > 30 )); then
            log WARN "Took a long time"
            ((warn_count++))
        fi
        if (( $err_count>0 )); then 
            log ERROR 'Error count '$errors' (--verbose)'
        else
            log INFO 'No logged errors'
        fi
        if (( $notime_count > 0 )); then
            log WARN $notime_count' lines without time (--verbose)'
        fi
    fi
    print_stat_line $TAG $err_count $warn_count $old_count $notime_count
    print_line
}

# --- Parse arguments ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --do-all) DO_ALL=true;;
        --bar) BAR_DATA=true;;
        --datasense) DATASENSE_DATA=true;;
        --icos) ICOS_DATA=true;;
        --hy) HY_DATA=true;;
        --fmi) FMI_DATA=true;;
        --smhi) SMHI_DATA=true;;
        --gapfilling) GAPFILLING_DATA=true;;
        --smear) SMEAR_DATA=true;;
        --ectoui) ECTOUI_DATA=true;;
        --radobs) RADOBS_DATA=true;;
        --satobs) SATOBS_DATA=true;;
        --geojson) GEOJSON_DATA=true;;
        --verbose) VERBOSE=true;;
        --debug) DEBUGGING=true; VERBOSE=true;;
        --ended) PRINT_ENDED=true;;
        --noheader) PRINT_STAT_HEADER=false;;
        --days)
            shift
            DAYS=${1:-days}
            if ! [[ "$DAYS" =~ ^[0-9]+$ ]]
            then
                echo "Days can only be a positive integer"
                exit 1
            fi
            ;;
        --hours)
            shift
            HOURS=${1:-hours}
            if ! [[ "$HOURS" =~ ^[0-9]+$ ]]
            then
                echo "Hours can only be a positive integer"
                exit 1
            fi
            ;;
        --level) 
            shift
            PRINT_LEVEL=${1:-level}
            ;;
        --search)
            shift
            SEARCH=${1:-search}
            SEARCHING=true
            ;;
        --year)
            shift
            YEAR=${1:-year}
            ;;
        --month)
            shift
            MONTH=${1:-month}
            ;;
        --day)
            shift
            DAY=${1:-day}
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED} Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
    shift
done

# --- Main execution flow -----------------------------------------------------
TAG='MAIN'
log RUNINFO "Monitor starting at $(date '+%Y-%m-%d %H:%M')"
print_stat_header
get_site_data_ends
get_block_data_ends
run_info
print_line    

if $DO_ALL; then
  DATASENSE_DATA=true
  BAR_DATA=true
  ICOS_DATA=true
  HY_DATA=true
  FMI_DATA=true
  SMHI_DATA=true
  GAPFILLING_DATA=true
  SMEAR_DATA=true
  ECTOUI_DATA=true
  RADOBS_DATA=true
  SATOBS_DATA=true
  GEOJSON_DATA=true
fi

if $DATASENSE_DATA; then 
    datasense_data
fi
if $BAR_DATA; then
    bar_data
fi
if $ICOS_DATA; then
    icos_data
fi
if $HY_DATA; then
    hy_data
fi
if $FMI_DATA; then
    fmi_data
fi
if $SMHI_DATA; then
    smhi_data
fi
if $GAPFILLING_DATA; then 
    gapfilling_data
fi
if $SMEAR_DATA; then 
    smear_data
fi
if $ECTOUI_DATA; then
    ectoui_data
fi
if $RADOBS_DATA; then 
    radobs_data
fi
if $SATOBS_DATA; then
    satobs_data
fi
if $GEOJSON_DATA; then
   geojson_data
fi
TAG='MAIN'
log RUNINFO "Monitor ended at $(date '+%Y-%m-%d %H:%M')"
