#!/bin/bash
########################
##      COMMENTS      ##
########################
##
## My Obligatory Bash Prompt
##
## Sets up a overly informational bash prompt
## complete with time, user, ip, performance,
## and other things that I find interesting.
##
## It's designed to be sourced from either
## ~/.bashrc or /etc/bash.bashrc or gen'd
## through /etc/profile.d
##
########################

# If not running interactively, don't do anything
test -z "${TERM}" -o "x${TERM}" = dumb && return

#the open and close brackets - with color
OPENB="${IWhite}["
CLOSEB="${IWhite}]"

#the linedraw character default
FillChar="─"

#the battery charge/discharge symbols
battdn="▼"
battup="▲"
battbolt="⌁"


########################
##     FUNCTIONS      ##
########################

function rtrim() {
        local var=$@
        var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
        echo -n "$var"
}

function ltrim() {
        local var=$@
        var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
        echo -n "$var"
}

function trim() {
        local var=$@
        var=$(ltrim "${var}")
        var=$(rtrim "${var}")
        echo -n "$var"
}

function ForceGetUserName {
	## Modified from a script I found somewhere -
	## The read command shoulda worked... but wouldn't...
	## So cut was simplest
    thisPID=$$
    origUser=$(whoami)
    thisUser=$origUser
    while [ "${thisPID}" -gt 1 ]
    do
        temp=$(\ps -ax -ouser,ppid,pid,comm | awk -v P=$thisPID ' $3 == P { print $1 "   " $2 "   " $3 "   " $4 }')
        thisUser=$(echo $temp | cut -f1 -d" ")
        myPPid=$(echo $temp | cut -f2 -d" ")
        myPid=$(echo $temp | cut -f3 -d" ")
        myComm=$(echo $temp | cut -f4 -d" ")
        thisPID=$myPPid
    done
    echo "${thisUser}"
}

function GetUserColor {
# Test user type (root-ish or normal). As root:
#       USER will be "root" with Sudo
#       UID will be 0 with su
#       C:\Windows will be writable with Windows (via cygwin)
# NOTE: logname doesn't work if the terminal doesn't allocate a tty
#       (which just started happening in my Arch installation [Sept/Oct 2015])
#       Some fudging is necessary to detect when it fails and act accordingly
#       This means the username and sudo/su info is ... less certain.
###################
        local tmpUser=$(logname 2>/dev/null)
        if [[ ! (${tmpUser} && ${tmpUser-x}) ]]; then
		tmpUser=$(ForceGetUserName)
        fi
        local retval=${Yellow}  # Default to caution... we just don't know who you are
        if [[ ${USER} == "root" ]] || [[ ${UID} -eq 0 ]] || [[ -w /cygdrive/c/Windows ]]; then
                retval="${White}(${Green}" # User is root
                if [[ ${SUDO_USER} && ${SUDO_USER-x} ]]; then
                        retval="${retval}${SUDO_USER} "
			retval="${retval}${White}sudo'd as"
                else
                        if [[ ${tmpUser} && ${tmpUser-x} ]]; then
                                retval="${retval}${tmpUser} "
                        fi
                        retval="${retval}${White}su'd as"
                fi
                        retval="${retval}${White}) ${Red}"

        elif [[ "${USER}" != "${tmpUser}" ]]; then
                retval="${Yellow}"        # Alert: User is not login user.
        else
                retval=${Green}         # User is normal (yay!).
        fi
        retval="${retval}${USER}"
        printf "%s" "${retval}"
}

function get_uptime() {
	local retval=""
	local uptime
	if [ "${BaseOS}" == "Darwin" ]; then
		#MacOS does it differently...
		local boottime=$(sysctl -n kern.boottime | awk '{print $4}' | sed 's/,//g')
		local unixtime=$(date +%s)
		uptime=$((${unixtime} - ${boottime}))
	else
		# pulls uptime from source other than... uptime (which doesn't seem to work on cygwin)
		uptime=$(</proc/uptime)
	fi
	local timeused=${uptime%%.*}
	local daysused=0
	local hoursused=0
	local minutesused=0
	local secondsused=0
	retval="up "

	#break it up into human readable time
	if [[ ${timeused} && ${timeused-x} ]]; then
		if (( timeused > 86400 )); then
			((
				daysused=timeused/86400,
				hoursused=timeused/3600-daysused*24,
				minutesused=timeused/60-hoursused*60-daysused*60*24,
				secondsused=timeused-minutesused*60-hoursused*3600-daysused*3600*24
			))
		elif (( timeused < 3600 )); then
			((
			minutesused=timeused/60,
			secondsused=timeused-minutesused*60
		))
		elif (( timeused < 86400 )); then
			((
			hoursused=timeused/3600,
			minutesused=timeused/60-hoursused*60,
			secondsused=timeused-minutesused*60-hoursused*3600
			))
		fi

		#color and display
		retval=${retval}"${Green}${daysused}${White}d "
		retval=${retval}"${Green}${hoursused}${White}h:"
		retval=${retval}"${Green}$(echo ${minutesused} | sed -e :a -e 's/^.\{1,1\}$/0&/;ta' )${White}m:"
		retval=${retval}"${Green}$(echo ${secondsused} | sed -e :a -e 's/^.\{1,1\}$/0&/;ta' )${White}s"

		printf "%s" "${retval}"
	fi
}

function path_info()
{
	# Returns a color according to free disk space in $PWD.
	# Also pulls the count of various files in the dir
	#    (but only if there's enough room on screen)
	local retval=""
	local totval=""
	local freval=""
	local lengthlimit=$((${1} + 3))
	local diskloc="${PWD/$HOME/~}"

	#show the size of the current directory
	totval=" ${White}total $(pwd_size)"

	#Now trim the path down if the screen is too narrow
	local curclean=$(cleanesc "${retval}${totval}${freval}")
	local curlength=${#curclean}
	local maxlength=0
	(( maxlength = curlength + lengthlimit ))
	local pwdshrunk=$(trim_pwd ${maxlength} "${diskloc}")
	diskloc="${pwdshrunk}"

	#Check if the pwd is read-only (not read-write)
	#and color the text (but not the slashes)
	local reppat="/"
	if [ "${BaseOS}" = "Darwin" ]; then
		#Don't need to escape the slash on Mac
		reppat="/"
	fi
	if [ ! -w "${PWD}" ] ; then
	        # No write privilege in the current directory.
        	retval="${Red}RO ${diskloc//${reppat}/${White}${reppat}${Red}}"${retval}
	else
		retval="${Green}${diskloc//${reppat}/${White}${reppat}${Green}}"${retval}
	fi

	printf "%s" "${retval}"
}

function trim_pwd() {
	#shrink the pwd to initials if it's too long (leave the actual working dir)
	if [ "${BaseOS}" == "Darwin" ]; then
		local p=${2/#$HOME/~} b s
	else
		local p=${2/#$HOME/\~} b s
	fi
	local slashcount="${PWD//[^\/]/}"
	local retval=""
	slashcount=${#slashcount}
	if [ ${slashcount} -gt 1 ]; then
		local s=${#p}
		while [[ $p != "${p//\/}" ]]&&(($s>((${COLUMNS}-$1))))
		do
			p=${p#/}
			[[ $p =~ \.?. ]]
			local b=$b/${BASH_REMATCH[0]}
			p=${p#*/}
			((s=${#b}+${#p}))
		done
	if [ "${BaseOS}" == "Darwin" ]; then
		retval="${b/\/~/~}${b+/}$p"
	else
		retval="${b/\/~/\~}${b+/}$p"
	fi
	else
		retval="${p}"
	fi
	#Now let's make sure there is (or is not) a single /
	case "${retval}" in
		/~* | //* )
			retval="${retval:1}"
		;;
		/* | ~* )
			retval="${retval}"
		;;
		* )
			retval="/${retval}"
		;;
	esac
	printf "%s" "${retval}"
}

function pwd_size() {
	#totals all files in the pwd and shows the human readable total
	local TotalBytes
	local Bytes
	local suffix
	TotalBytes=0
	
	for Bytes in $(\ls -lAn 2>/dev/null | grep "^-" | awk '{print $5}'); do
		(( TotalBytes += Bytes ))
	done

	if [ $TotalBytes -lt 1024 ]; then
		TotalSize=$(echo -e "scale=1 \n$TotalBytes \nquit" | bc)
		suffix="B"
	elif [ $TotalBytes -lt 1048576 ]; then
		TotalSize=$(echo -e "scale=1 \n$TotalBytes/1024 \nquit" | bc)
		suffix="KB"
	elif [ $TotalBytes -lt 1073741824 ]; then
		TotalSize=$(echo -e "scale=1 \n$TotalBytes/1048576 \nquit" | bc)
		suffix="MB"
	elif [ $TotalBytes -lt 1099511627776 ]; then
		TotalSize=$(echo -e "scale=1 \n$TotalBytes/1073741824 \nquit" | bc)
		suffix="GB"
	else
		TotalSize=$(echo -e "scale=1 \n$TotalBytes/1099511627776 \nquit" | bc)
		suffix="TB"
	fi

	printf "%s" "${Green}${TotalSize}${White}${suffix}"
}

#Returns error stuff
function error_result()
{
	local Last_Command=$?
	local retval
	if [[ ! $Last_Command == 0 ]]; then
		retval="${OPENB}e${Red}${Last_Command}${CLOSEB}"
	fi
    #echo -n ${retval}
    printf "%s" ${retval}
}

function get_tty()
{
	local splay=$(tty | sed -e 's:/dev/::')
	local retval=""
	case "${splay}" in
		tty* )
			retval=${White}tty${Green}$(echo -en ${splay} | sed -e 's:tty::' )
		;;
		pts* )
			retval=${White}pts${Green}$(echo -en ${splay}| sed -e 's:pts/::' )
		;;
		* )
			retval=${White}${splay}
		;;
	esac
	printf "%s" "${retval}"
}

function fill_line() {
	local fillsize
	local cleanedup=$(cleanesc ${*})
	(( fillsize = COLUMNS - ${#cleanedup} ))
	local fill=""
	while [ "${fillsize}" -gt 0 ]
	do
		fill="${fill}${FillChar}"
		(( fillsize-- ))
	done
	printf "%s" "${fill}"
}

function cleanesc() {
	local retval=$(echo -n $* | sed "s,\e\[[0-9;]*[a-zA-Z],,g" | sed "s,\\\,,g" | sed "s,e(0qe(B, ,g")
	printf "%s" "${retval}"
}

function color_of_time() {
	local retval
	case "${2}" in
		a*)
			case "${1}" in
				12 | 1 | 2 | 3 | 4 )
					retval=${IBlue}
			;;
				5 | 6 | 7 )
					retval=${White}
			;;
				8 | 9 | 10 )
					retval=${Yellow}
			;;
				11 )
					retval=${IYellow}
			;;
				* )
					retval=${Purple}
			;;
			esac
		;;
		p*)
			case "${1}" in
				8 | 9 | 10 | 11 )
					retval=${IBlue}
			;;
				5 | 6 | 7 )
					retval=${White}
			;;
				2 | 3 | 4 )
					retval=${Yellow}
			;;
				12 | 1 )
					retval=${IYellow}
			;;
				* )
					retval=${Purple}
			;;
			esac
		;;
		* )
			retval=${Purple}
		;;
		esac
	printf "%s" "${retval}"
}

# Now ... the prompt.
PROMPT_COMMAND=prompt_small

function prompt_big {
	local last_rc=$?
	local ErrLevel=""
	[[ $last_rc -ne 0 ]] && ErrLevel="${OPENB}e${Red}${last_rc}${CLOSEB}"

	local ssh_label=""
	[[ -n "${SSH_CONNECTION}" ]] && ssh_label=" ${Green}SSH'd"

	local leftstuff=""
	local rightstuff=""
	local outstuff=""
	local LineColor=${IWhite}
	[[ -n "${SSH_CONNECTION}" ]] && LineColor=${BYellow}
	[[ -n "${ErrLevel}" ]]       && LineColor=${Red}

	local FillCharTemp=${FillChar}
	outstuff=${LineColor}$(fill_line)"\n"
	FillChar=" "

	#Shell depth
	leftstuff=${leftstuff}"${OPENB}${White}sh${Green}${SHLVL} "
	# Terminal type and number
	leftstuff=${leftstuff}$(get_tty)
	leftstuff=${leftstuff}${CLOSEB}
	leftstuff=${leftstuff}${LineColor}${FillChar}
	#Uptime - but only if the term is wide enough
	local up_time=${OPENB}$(get_uptime)${CLOSEB}
	local lefttemp=$(cleanesc ${up_time}${leftstuff})
	local lefttemplen=${#lefttemp}
	if [[ ${lefttemplen} -lt $((${COLUMNS} / 2)) ]]; then
		leftstuff=${leftstuff}${up_time}
	fi

	# User@Host (with SSH indicator if connected via SSH):
	rightstuff=${rightstuff}"${OPENB}$(GetUserColor)${White}@${Purple}${HOSTNAME%.*}${ssh_label}${CLOSEB}${FillChar}"
	local rightclean=$(cleanesc ${rightstuff})
	local rightlength=${#rightclean}
        # PWD (with 'disk space' info):
        leftstuff=${leftstuff}${FillChar}"${OPENB}${IBlue}$(path_info ${rightlength})${CLOSEB}"
	leftstuff=${leftstuff}${LineColor} #${FillChar}

	# Day and Time
	local holdday=$(date +'%a')
	local holdhour=$(date +'%_I')
	holdhour=$(trim ${holdhour})
	local holdmin=$(date +'%M')
	local holdmeri=$(date +%p | tr [:upper:] [:lower:])
	local colortime=$(color_of_time ${holdhour} ${holdmeri})
	rightstuff=${rightstuff}"${OPENB}${Green}${holdday} ${colortime}${holdhour}${White}:${colortime}${holdmin}${holdmeri}${CLOSEB}"

	#Line to right justify
	local filled=$(fill_line ${leftstuff}${rightstuff})
	outstuff=${outstuff}${leftstuff}${LineColor}${filled}${rightstuff}"\n"
	#Reset the fill character
	FillChar=${FillCharTemp}

	outstuff=${outstuff}${LineColor}$(fill_line)

	#The Actual Prompt!
	PS1="\[\n\n${outstuff}\]"
	# new line and $ or #
	PS1=${PS1}"\n\[${IYellow}\]\$\[${Color_Off}\] "

}

function prompt_small {
	local last_rc=$?

	local OB CL
	if [[ $last_rc -eq 0 ]]; then
		OB="${IWhite}["; CL="${IWhite}]"
	else
		OB="${Red}[";    CL="${Red}]"
	fi

	local ssh_label=""
	[[ -n "${SSH_CONNECTION}" ]] && ssh_label=" ${Green}SSH'd"

	local holdday holdhour holdmin holdmeri colortime
	holdday=$(date +'%a')
	holdhour=$(date +'%_I'); holdhour=$(trim "${holdhour}")
	holdmin=$(date +'%M')
	holdmeri=$(date +%p | tr '[:upper:]' '[:lower:]')
	colortime=$(color_of_time "${holdhour}" "${holdmeri}")

	local line1="${OB}$(GetUserColor)${IWhite}@${Purple}${HOSTNAME%.*}${ssh_label}${CL} ${OB}${Green}${holdday} ${colortime}${holdhour}${IWhite}:${colortime}${holdmin}${holdmeri}${CL}"
	local line2="${OB}${IBlue}$(trim_pwd 4 "${PWD/$HOME/~}")${CL}"

	PS1="\[\n${line1}\n${line2}\n\]\[${IYellow}\]\$\[${Color_Off}\] "
}

_PROMPT_MODE="small"
function SwitchPrompts {
	if [[ "${_PROMPT_MODE}" == "small" ]]; then
		_PROMPT_MODE="big"
		PROMPT_COMMAND=prompt_big
		echo "Switched to prompt_big"
	else
		_PROMPT_MODE="small"
		PROMPT_COMMAND=prompt_small
		echo "Switched to prompt_small"
	fi
}

PS2="> "
PS3="> "
PS4="+ "

