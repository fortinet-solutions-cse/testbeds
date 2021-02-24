#!/bin/bash 



if [[ $# -ne 1 ]] 
 then 
  (echo "must give N "; exit 2)
 fi
export N=$1
for m in {1..250} 
do 
 echo "client-$N-$m stopped"
 docker stop client-$N-$m
 docker rm client-$N-$m
done
for m in {1..250}
do
 docker run --net=c$N-$m --ip 10.$N.$m.5 -d --name client-$N-$m --cpu-shares 250 --cpus 0.2 --memory 50M  fit
done

