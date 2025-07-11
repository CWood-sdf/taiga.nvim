#!/bin/bash

source .env

echo "{"
echo '"username":"'${TAIGA_USERNAME}'",'
echo '"password":"'${TAIGA_PASSWORD}'"}'
