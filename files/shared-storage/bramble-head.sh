#!/bin/bash

sudo systemctl daemon-reload
sudo systemctl start munge.service
sudo systemctl start mysql
sudo systemctl start slurmd
sudo systemctl start slurmctld
sudo systemctl start slurmdbd
