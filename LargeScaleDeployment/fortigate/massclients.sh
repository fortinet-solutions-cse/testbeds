#!/bin/bash



if [[ $# -ne 1 ]] 
 then 
  (echo "must give N "; exit 2)
 fi
export N=$1

for m in {1..250} 
do 
 docker rm client-$N-$m || true
 docker run --net=c$N-$m --ip 10.$N.$m.5 -itd --name client-$N-$m  --cpus 0.05 --memory 50M fit
done

