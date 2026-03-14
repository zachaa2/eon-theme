#!/bin/sh
sed -i \
         -e 's/rgb(0%,0%,0%)/#c3bdaf/g' \
         -e 's/rgb(100%,100%,100%)/#1a1b1a/g' \
    -e 's/rgb(50%,0%,0%)/#1a1b1a/g' \
     -e 's/rgb(0%,50%,0%)/#5ab7cb/g' \
 -e 's/rgb(0%,50.196078%,0%)/#5ab7cb/g' \
     -e 's/rgb(50%,0%,50%)/#dfe0df/g' \
 -e 's/rgb(50.196078%,0%,50.196078%)/#dfe0df/g' \
     -e 's/rgb(0%,0%,50%)/#1a1b1a/g' \
	"$@"
