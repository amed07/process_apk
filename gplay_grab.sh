#!/bin/bash

source colors.sh

info "Grabbing latest binaries"
python googleplay-api/gplay_grab.py

if ls ./*.apk &> /dev/null; 
then
  info "Kicking off processing for apks"
  for apk in ./*.apk; do
    mv "$apk" place_apks_here
  done
  ./process_apk.sh
else
  warn "nothing to process!"
fi

info "done!"
