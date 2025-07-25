#!/usr/bin/env bash
################################################################
# copy this script to /etc/snmp/ and make it executable:       #
# chmod +x /etc/snmp/osupdate                                  #
# ------------------------------------------------------------ #
# edit your snmpd.conf and include:                            #
# extend osupdate /etc/snmp/osupdate                           #
#--------------------------------------------------------------#
# restart snmpd and activate the app for desired host          #
#--------------------------------------------------------------#
# please make sure you have the path/binaries below            #
################################################################
BIN_WC='/usr/bin/env wc'
BIN_GREP='/usr/bin/env grep'
CMD_GREP='-c'
CMD_WC='-l'
BIN_ZYPPER='/usr/bin/env zypper'
CMD_ZYPPER='-q lu'
BIN_YUM='/usr/bin/env yum'
CMD_YUM='-q check-update'
BIN_DNF='/usr/bin/env dnf'
CMD_DNF='-q check-update'
BIN_APT='/usr/bin/env apt-get'
CMD_APT='-qq -s upgrade'
BIN_PACMAN='/usr/bin/env pacman'
CMD_PACMAN='-Sup'
BIN_CHECKUPDATES='/usr/bin/env checkupdates'
BIN_PKG='/usr/sbin/pkg'
CMD_PKG=' audit -q -F'
BIN_APK='/sbin/apk'
CMD_APK=' version'

SNMP_PERSISTENT_DIR="$(net-snmp-config --persistent-directory)"
UNPRIV_SHARED_FILE="$SNMP_PERSISTENT_DIR/osupdates/stats.txt"

# Set to RW for PiKVM
/usr/bin/rw

mkdir -p "$(dirname "$UNPRIV_SHARED_FILE" )"

do_check() {
    ################################################################
    # Don't change anything unless you know what are you doing     #
    ################################################################
    if command -v zypper &>/dev/null ; then
        # OpenSUSE
        # shellcheck disable=SC2086
        UPDATES=$($BIN_ZYPPER $CMD_ZYPPER | $BIN_WC $CMD_WC)
        if [ "$UPDATES" -ge 2 ]; then
            echo $(($UPDATES-2));
        else
            echo "0";
        fi
    elif command -v dnf &>/dev/null ; then
        # Fedora
        # shellcheck disable=SC2086
        UPDATES=$($BIN_DNF $CMD_DNF | $BIN_WC $CMD_WC)
        if [ "$UPDATES" -ge 1 ]; then
            echo $(($UPDATES-1));
        else
            echo "0";
        fi
    elif command -v pacman &>/dev/null ; then
        # Arch
        # calling pacman -Sup does not refresh the package list from the mirrors,
        # thus it is not useful to find out if there are updates. Keep the pacman call
        # to accommodate users that do not have it. checkupdates is in pacman-contrib.
        # also enables snmpd to collect this information if it's not run as root
        if command -v checkupdates &>/dev/null ; then
            # shellcheck disable=SC2086
            UPDATES=$($BIN_CHECKUPDATES | $BIN_WC $CMD_WC)
        else
            # shellcheck disable=SC2086
            UPDATES=$($BIN_PACMAN $CMD_PACMAN | $BIN_WC $CMD_WC)
        fi
        if [ "$UPDATES" -ge 1 ]; then
            echo $(($UPDATES-1));
        else
            echo "0";
        fi
    elif command -v yum &>/dev/null ; then
        # CentOS / Redhat
        # shellcheck disable=SC2086
        UPDATES=$($BIN_YUM $CMD_YUM | $BIN_WC $CMD_WC)
        if [ "$UPDATES" -ge 1 ]; then
            echo $(($UPDATES-1));
        else
            echo "0";
        fi
    elif command -v apt-get &>/dev/null ; then
        # Debian / Devuan / Ubuntu
        # shellcheck disable=SC2086
        UPDATES=$($BIN_APT $CMD_APT | $BIN_GREP $CMD_GREP 'Inst')
        if [ "$UPDATES" -ge 1 ]; then
            echo "$UPDATES";
        else
            echo "0";
        fi
    elif command -v pkg &>/dev/null ; then
        # FreeBSD
        # shellcheck disable=SC2086
        UPDATES=$($BIN_PKG $CMD_PKG | $BIN_WC $CMD_WC)
        if [ "$UPDATES" -ge 1 ]; then
            echo "$UPDATES";
        else
            echo "0";
        fi
    elif command -v apk &>/dev/null ; then
        # Alpine
        # shellcheck disable=SC2086
        UPDATES=$($BIN_APK $CMD_APK | $BIN_WC $CMD_WC)
        if [ "$UPDATES" -ge 2 ]; then
            echo $(($UPDATES-1));
        else
            echo "0";
        fi
    else
        echo "0";
    fi
}

do_check > "$UNPRIV_SHARED_FILE"

# Set back to read-only for PiKVM
/usr/bin/ro