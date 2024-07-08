#!/bin/bash
mpstat >> top
mpstat >> top
mpstat >> top
mpstat >> top
mpstat >> top
mpstat >> top

while true; do mpstat >> top; sed -i -e 1,4d top; sleep 0.5; done 
