#!/bin/bash

service postgresql start

# service mongod start
/usr/bin/mongod --bind_ip 0.0.0.0 &