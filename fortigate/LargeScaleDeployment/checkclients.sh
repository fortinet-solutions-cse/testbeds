#!/bin/bash -e



if [[ $# -ne 1 ]] 
 then 
  (echo "must give N "; exit 2)
 fi
export N=$1

for m in {1..250} 
do 
echo "check client-$N-$m:"
 if docker top client-$N-$m 
 then
 echo "client-$N-$m is running"
 else
 echo "client-$N-$m stop/rebuild"
 docker stop client-$N-$m || true
 docker rm -f client-$N-$m 
# virsh reboot site-$N-$m
 sleep 3
 docker run --net=c$N-$m --ip 10.$N.$m.5 -itd --name client-$N-$m --cpu-shares 200 --cpus 0.1 --memory 0.1G  fit
 fi
done

