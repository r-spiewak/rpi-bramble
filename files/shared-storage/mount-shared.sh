#!/bin/bash

while ! ping -c 1 -n -w 1 10.0.0.1 &> /dev/null
do
    sleep 1
done
sudo mount -a
sudo systemctl daemon-reload
sudo systemctl start munge.service
sudo systemctl start mysql.service
sudo systemctl start slurmd
