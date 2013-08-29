#!/bin/bash


kill `cat server.pid`
node server.js > server.log  &
echo $!>server.pid
echo "service started"
