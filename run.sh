#!/bin/bash

echo "
The SOHO FOSS ntopng Docker build - cobbled together for you by HomeSecSi (homesecsi@ctemplar.com)

Donations welcome
BTC 1M7RBtkUEk1Rcq79ubk5ktZar5NMVDXKqj
ETH 0xf0D65F6edF89D9B1B5F45A84bDCe628705A0175A
LTC LcCsNL6nnEobDwaqcsxZu48YhoN5QjPDAF

"
if [ -z "$LOCALNET" ]; then
	echo -e "*** No -e LOCALNET variable set, defaulting to 192.168.1.0/24. You probably dont want this"
        LOCALNET="192.168.1.0/24"
fi

if [ "$ACCOUNTID" ]; then
        if [ "$LICENSEKEY" ]; then
                echo -e "*** Found a Maxmind account and licensekey pair, ntopng will support GeoIP lookups if this is valid\nUpdating Maxmind Database"
                echo -e "AccountID $ACCOUNTID\nLicenseKey $LICENSEKEY\nEditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country" > /etc/GeoIP.conf
                /usr/bin/geoipupdate
        else
                echo -e "*** No Maxmind GeoIP account and licensekey pair found, ntop will not support GeoIP lookups. Please get a license from maxmind.com and add as docker run -e options"
        fi
else
        echo -e "*** No Maxmind GeoIP account and licensekey pair found, ntop will not support GeoIP lookups. Please get a license from maxmind.com and add as docker run -e options"
fi

if [ -z "$PUID" ]; then
        echo "*** You can use -e PUID=xyz and -e PGID=zxy as docker run switches to set the UID and GID to run as on the host"
else
        PUID=${PUID:-911}
        PGID=${PGID:-911}
        groupmod -o -g "$PGID" ntopng
        usermod -o -u "$PUID" ntopng
	chown ntopng:ntopng /etc/redis/redis.conf /var/log/redis /var/lib/redis
        echo "
Running as: 
User uid:    $(id -u ntopng)
User gid:    $(id -g ntopng)"
fi

#chown ntopng:ntopng /etc/redis/redis.conf /var/log/redis

echo "*** Starting Redis"
/etc/init.d/redis-server start
echo "*** Starting netflow2ng"
su - ntopng -c /ntop/netflow2ng-v0.0.2-8-g887b99b-linux-x86_64 &
echo "*** Starting ntopng"
if [ -z "$FLOWDUMP" ]; then 
        echo -e "*** no -e FLOWDUMP switch set, expired ntopng flows will not be dumped"
	cd /ntop/ntopng && ./ntopng --local-networks $LOCALNET -i tcp://127.0.0.1:5556
else
        echo -e "*** -e FLOWDUMP switch is present, expired ntopng flows will dump with ntopng switch -F $FLOWDUMP "
	cd /ntop/ntopng && ./ntopng --local-networks $LOCALNET -i tcp://127.0.0.1:5556 -F $FLOWDUMP
fi

