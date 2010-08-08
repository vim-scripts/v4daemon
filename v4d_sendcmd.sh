#!/bin/sh

while [ true ];
do
    read line < $1;
	if [[ $line == "__EOF__" ]]; then
		exit 0;
	fi
    echo "$line";
done

