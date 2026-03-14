#!/bin/sh
sed -i \
         -e 's/#c3bdaf/rgb(0%,0%,0%)/g' \
         -e 's/#1a1b1a/rgb(100%,100%,100%)/g' \
    -e 's/#1a1b1a/rgb(50%,0%,0%)/g' \
     -e 's/#5ab7cb/rgb(0%,50%,0%)/g' \
     -e 's/#dfe0df/rgb(50%,0%,50%)/g' \
     -e 's/#1a1b1a/rgb(0%,0%,50%)/g' \
	"$@"
