#!/bin/bash

FILE=$(readlink -f $1)

cd tex/ && pandoc -o ${FILE%.*}.pdf $FILE \
  --latex-engine=xelatex  --toc -H "header-includes.tex" \
  -V "lang=en" -V "mainfont=Gotham-Book" -V "documentclass=scrbook" \
  -V "classoption=open=any" -V "fontsize=10pt" -V "papersize=a4" 
