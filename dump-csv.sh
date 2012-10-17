#!/bin/bash

exec >out.csv

sqlite3 cruises.db  << EOF
.headers on
.mode csv
select * from cruises;
EOF
