#!/bin/bash

service ssh start

R -e "Rserve::run.Rserve(remote=TRUE)"

