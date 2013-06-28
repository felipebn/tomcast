#!/usr/bin/env bash

ip="10.1.4.6"
url="http://"$ip"/tomcast/download.php"
filename=`wget --server-response --spider "$url" 2>&1 | grep filename | sed "s/^.*filename=\"\([^\"]\+\)\"/\1/g"`
if [ "$filename" ]; then
    echo "Ultima versao: "$filename  
fi

echo "Versao da app:"
read v

arquivo="tomcastapp."$v".tar.bz2"


tar -cj * --exclude=*setup.sh --exclude=build.sh --exclude=*.tar.bz2 -f $arquivo


scp $arquivo duxus@$ip:tomcast_repo/
scp tomcast-setup.sh duxus@$ip:public_html/tomcast/

rm -f $arquivo
