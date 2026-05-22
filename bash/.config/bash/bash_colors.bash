# bash_colors.bash — ANSI escape color variables.
# Single source of truth shared by bash.bashrc and mobprompt.sh.
# All variables use \e[...m notation for portability.
#
# ── Campbell palette alignment ────────────────────────────────────────────────
# These escape codes reference terminal color indices 0–15.  Kitty maps those
# indices to the Extended Campbell Palette hex values documented in
# theme_definition/campbell.sh.  The hex values shown below are what you
# actually see when kitty (or any Campbell-configured terminal) renders them.
#
# ANSI  Variable    CAMPBELL_* name          Hex
# ────  ─────────   ──────────────────────   ───────
#   0   Black       CAMPBELL_BLACK           #0c0c0c
#   1   Red         CAMPBELL_RED             #c50f1f
#   2   Green       CAMPBELL_GREEN           #13a10e
#   3   Yellow      CAMPBELL_YELLOW          #f19c00
#   4   Blue        CAMPBELL_BLUE            #0037da
#   5   Purple *    CAMPBELL_MAGENTA         #881798
#   6   Cyan        CAMPBELL_CYAN            #3a96dd
#   7   White       CAMPBELL_WHITE           #cccccc
#   8   IBlack      CAMPBELL_BLACK_BRIGHT    #767676
#   9   IRed        CAMPBELL_RED_BRIGHT      #e74856
#  10   IGreen      CAMPBELL_GREEN_BRIGHT    #16c60c
#  11   IYellow     CAMPBELL_YELLOW_BRIGHT   #f9f1a5
#  12   IBlue       CAMPBELL_BLUE_BRIGHT     #3b78ff
#  13   IPurple *   CAMPBELL_MAGENTA_BRIGHT  #b4009e
#  14   ICyan       CAMPBELL_CYAN_BRIGHT     #61d6d6
#  15   IWhite      CAMPBELL_WHITE_BRIGHT    #f2f2f2
#
# * ANSI 5/13 are "Magenta" in the Campbell spec and in tmux/kitty configs.
#   "Purple" is the long-established bash/prompt convention for the same slot
#   and is kept here for compatibility with mobprompt.sh.

# ─── Reset ────────────────────────────────────────────────────────────────────
Color_Off='\e[0m'

# ─── Regular (ansi 0–7) ───────────────────────────────────────────────────────
Black='\e[0;30m'    # #0c0c0c  CAMPBELL_BLACK
Red='\e[0;31m'      # #c50f1f  CAMPBELL_RED
Green='\e[0;32m'    # #13a10e  CAMPBELL_GREEN
Yellow='\e[0;33m'   # #f19c00  CAMPBELL_YELLOW
Blue='\e[0;34m'     # #0037da  CAMPBELL_BLUE
Purple='\e[0;35m'   # #881798  CAMPBELL_MAGENTA
Cyan='\e[0;36m'     # #3a96dd  CAMPBELL_CYAN
White='\e[0;37m'    # #cccccc  CAMPBELL_WHITE

# ─── Bold (ansi 0–7, bold attribute) ─────────────────────────────────────────
BBlack='\e[1;30m'   # #0c0c0c  CAMPBELL_BLACK   + bold
BRed='\e[1;31m'     # #c50f1f  CAMPBELL_RED     + bold
BGreen='\e[1;32m'   # #13a10e  CAMPBELL_GREEN   + bold
BYellow='\e[1;33m'  # #f19c00  CAMPBELL_YELLOW  + bold
BBlue='\e[1;34m'    # #0037da  CAMPBELL_BLUE    + bold
BPurple='\e[1;35m'  # #881798  CAMPBELL_MAGENTA + bold
BCyan='\e[1;36m'    # #3a96dd  CAMPBELL_CYAN    + bold
BWhite='\e[1;37m'   # #cccccc  CAMPBELL_WHITE   + bold

# ─── Underline (ansi 0–7, underline attribute) ────────────────────────────────
UBlack='\e[4;30m'   # #0c0c0c  CAMPBELL_BLACK   + underline
URed='\e[4;31m'     # #c50f1f  CAMPBELL_RED     + underline
UGreen='\e[4;32m'   # #13a10e  CAMPBELL_GREEN   + underline
UYellow='\e[4;33m'  # #f19c00  CAMPBELL_YELLOW  + underline
UBlue='\e[4;34m'    # #0037da  CAMPBELL_BLUE    + underline
UPurple='\e[4;35m'  # #881798  CAMPBELL_MAGENTA + underline
UCyan='\e[4;36m'    # #3a96dd  CAMPBELL_CYAN    + underline
UWhite='\e[4;37m'   # #cccccc  CAMPBELL_WHITE   + underline

# ─── Background (ansi 0–7) ────────────────────────────────────────────────────
On_Black='\e[40m'   # #0c0c0c  CAMPBELL_BLACK
On_Red='\e[41m'     # #c50f1f  CAMPBELL_RED
On_Green='\e[42m'   # #13a10e  CAMPBELL_GREEN
On_Yellow='\e[43m'  # #f19c00  CAMPBELL_YELLOW
On_Blue='\e[44m'    # #0037da  CAMPBELL_BLUE
On_Purple='\e[45m'  # #881798  CAMPBELL_MAGENTA
On_Cyan='\e[46m'    # #3a96dd  CAMPBELL_CYAN
On_White='\e[47m'   # #cccccc  CAMPBELL_WHITE

# ─── High Intensity foreground (ansi 8–15) ────────────────────────────────────
IBlack='\e[0;90m'   # #767676  CAMPBELL_BLACK_BRIGHT
IRed='\e[0;91m'     # #e74856  CAMPBELL_RED_BRIGHT
IGreen='\e[0;92m'   # #16c60c  CAMPBELL_GREEN_BRIGHT
IYellow='\e[0;93m'  # #f9f1a5  CAMPBELL_YELLOW_BRIGHT
IBlue='\e[0;94m'    # #3b78ff  CAMPBELL_BLUE_BRIGHT
IPurple='\e[0;95m'  # #b4009e  CAMPBELL_MAGENTA_BRIGHT
ICyan='\e[0;96m'    # #61d6d6  CAMPBELL_CYAN_BRIGHT
IWhite='\e[0;97m'   # #f2f2f2  CAMPBELL_WHITE_BRIGHT

# ─── Bold High Intensity (ansi 8–15, bold attribute) ─────────────────────────
BIBlack='\e[1;90m'  # #767676  CAMPBELL_BLACK_BRIGHT   + bold
BIRed='\e[1;91m'    # #e74856  CAMPBELL_RED_BRIGHT     + bold
BIGreen='\e[1;92m'  # #16c60c  CAMPBELL_GREEN_BRIGHT   + bold
BIYellow='\e[1;93m' # #f9f1a5  CAMPBELL_YELLOW_BRIGHT  + bold
BIBlue='\e[1;94m'   # #3b78ff  CAMPBELL_BLUE_BRIGHT    + bold
BIPurple='\e[1;95m' # #b4009e  CAMPBELL_MAGENTA_BRIGHT + bold
BICyan='\e[1;96m'   # #61d6d6  CAMPBELL_CYAN_BRIGHT    + bold
BIWhite='\e[1;97m'  # #f2f2f2  CAMPBELL_WHITE_BRIGHT   + bold

# ─── High Intensity Backgrounds (ansi 8–15) ───────────────────────────────────
On_IBlack='\e[0;100m'  # #767676  CAMPBELL_BLACK_BRIGHT
On_IRed='\e[0;101m'    # #e74856  CAMPBELL_RED_BRIGHT
On_IGreen='\e[0;102m'  # #16c60c  CAMPBELL_GREEN_BRIGHT
On_IYellow='\e[0;103m' # #f9f1a5  CAMPBELL_YELLOW_BRIGHT
On_IBlue='\e[0;104m'   # #3b78ff  CAMPBELL_BLUE_BRIGHT
On_IPurple='\e[0;105m' # #b4009e  CAMPBELL_MAGENTA_BRIGHT
On_ICyan='\e[0;106m'   # #61d6d6  CAMPBELL_CYAN_BRIGHT
On_IWhite='\e[0;107m'  # #f2f2f2  CAMPBELL_WHITE_BRIGHT

# ─── Inverse — swap fg/bg using the current pair (used by mobprompt) ─────────
InvBlack='\e[7;30m'    InvRed='\e[7;31m'    InvGreen='\e[7;32m'   InvYellow='\e[7;33m'
InvBlue='\e[7;34m'     InvPurple='\e[7;35m' InvCyan='\e[7;36m'    InvWhite='\e[7;37m'

# ─── Bold Inverse (used by mobprompt) ─────────────────────────────────────────
BInvBlack='\e[7;1;30m'   BInvRed='\e[7;1;31m'    BInvGreen='\e[7;1;32m'   BInvYellow='\e[7;1;33m'
BInvBlue='\e[7;1;34m'    BInvPurple='\e[7;1;35m' BInvCyan='\e[7;1;36m'    BInvWhite='\e[7;1;37m'
