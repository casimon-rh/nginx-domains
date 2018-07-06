#!/bin/bash
verlte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}
# nginx version?
if verlte 1.9 $(nginx -v 2>&1 | sed -e 's/.*\///g'); then
  # nginx is nice
  sudo nginx -T 2>/dev/null | grep -e " server_name " -e " location " | uniq;
else
  # unpolitely ask for info
  idproc=$(ps aux -P | grep -e 'nginx' | grep -e 'master' | awk '{print $2}' | head -1) 
  # generate gdb commands from the process's memory mappings using awk
  sudo cat /proc/$idproc/maps | awk '$6 !~ "^/"{split ($1,addrs,"-"); print "dump memory mem_" addrs[1] " 0x" addrs[1] " 0x" addrs[2] ;}END{print "quit"}' > gdb-commands
  # gdb installed?
  if [ -x "$(command -v gdb)" ]; then
    # use gdb with the -x option to dump these memory regions to mem_* files
    sudo gdb -p $idproc -x gdb-commands 2>&1 1>/dev/null;
  else
    # untar gdb binnary
    tar -xzf gdb.tar.gz
    sudo ./gdb -p $idproc -x gdb-commands
  fi
  # look for some (any) nginx.conf text
  sudo ls mem* | xargs cat | tr -d '\000' | grep -e " server_name " -e " location " | uniq
  # clean mess
  sudo rm mem*
fi