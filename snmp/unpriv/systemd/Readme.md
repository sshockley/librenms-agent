# systemd

## Installation

1. Copy systemd.py into /usr/bin/
2. Copy 99systemd-generate to /etc/cron.d
3. Fix selinux label with `restorecon -vF /etc/cron.d/99systemd-generate`
4. Create file with `touch /var/lib/net-snmp/systemd`
5. Set selinux whatever with `restorecon -Fv /var/lib/net-snmp/systemd`
6. Set `extend osupdate /usr/bin/cat /var/lib/net-snmp/systemd` in `/etc/snmp/snmpd.conf`
