mkdir -p bak/apps/splunk-rolling-upgrade
touch bak/apps/splunk-rolling-upgrade/file
chown -R 1000:1000 bak
mkdir -p etc/apps
chown -R root:root etc/apps
(cd bak; tar cf - *) | sudo -u root bash -c '(cd etc; tar xf -)'
ls -ld etc/apps/splunk-rolling-upgrade
