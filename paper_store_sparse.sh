#!/usr/bin/env bash

# MIT License
#
# Copyright (c) 2018 Maxim Biro <nurupo.contributions@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

set -euo pipefail

INPUT="$1"

if [ -z "$INPUT" ]; then
    echo "Error: No input file was specified. Please specify an input file as the first argument."
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: The input file \"$INPUT\" doesn't exist."
    exit 1
fi

if ! command -v pdflatex >/dev/null 2>&1; then
    echo "Error: Program \"pdflatex\" is not installed (Debian/Ubuntu: texlive-latex-base)."
    exit 1
fi
if ! command -v pdfunite >/dev/null 2>&1; then
    echo "Error: Program \"pdfunite\" is not installed (Debian/Ubuntu: poppler-utils)."
    exit 1
fi
if ! command -v qrencode >/dev/null 2>&1; then
    echo "Error: Program \"qrencode\" is not installed (Debian/Ubuntu: qrencode)."
    exit 1
fi
if ! command -v zbarimg >/dev/null 2>&1; then
    echo "Error: Program \"zbarimg\" is not installed (Debian/Ubuntu: zbar-tools)."
    exit 1
fi

TMP_DIR="$(mktemp -d)"

echo "Taking base64 of \"$INPUT\" file"
base64 "$INPUT" > "${TMP_DIR}/full_base64.txt"

OLD_PWD="${PWD}"
cd "$TMP_DIR"

cat <<EOF > page.tex.in
\documentclass[12pt,@@papersize@@]{article}

\usepackage[left=1cm,right=1cm,top=2cm,bottom=2cm]{geometry}
\usepackage[utf8]{inputenc}
\usepackage{graphicx}
\usepackage{fancyhdr}

\fancyhf{}
\renewcommand{\headrulewidth}{0pt}

\chead{\fontfamily{pcr}\selectfont \detokenize{@@header@@}}
\cfoot{\fontfamily{pcr}\selectfont \detokenize{@@footer@@}}

\begin{document}

\thispagestyle{fancy}
\fontfamily{pcr}\selectfont

\begin{flushleft}
\input{base64.txt}
\end{flushleft}

\begin{figure}[!b]
\begin{center}
\includegraphics{qr.png}
\end{center}
\end{figure}

\end{document}
EOF


INPUT_BASENAME="$(basename "$INPUT")"

# You can store only so much data in a QR code and some QR readers
# have trouble with QR codes containing too much data. 12 lines of
# base64 works fine with most readers though, so we split the file
# into QR codes containing 12 line pieces.
echo "Splitting the base64 file into 12-line files"
split -l 12 -a 4 -d --additional-suffix=.txt full_base64.txt

total=0
for f in x*; do
    total=$((total + 1))
done

echo "Split in $total of 12-lines files"

i=1
for f in x*; do
    echo "Creating QR code image for file #$i"
    head -c -1 "$f" | qrencode -o "qr-$f.png"
    cp "$f" base64.txt
    cp "qr-$f.png" qr.png
    echo "Creating a pdf page with the base64 text and QR code image for file #$i"
    sed "s/@@papersize@@/${PAPER_STORE_PAPER_SIZE:-a4paper}/g" page.tex.in | sed "s/@@header@@/$INPUT_BASENAME/g" | sed "s#@@footer@@#Page $i/$total#g" > page.tex
    pdflatex page.tex >/dev/null 2>&1
    cp page.pdf "page-$(printf "%04d" $i).pdf"
    i=$((i + 1))
done

echo "Combining all the pages into a single pdf"
pdfunite $(find . -name 'page-*.pdf' | sort) pages.pdf

echo "Using a QR code reader on the pdf file to make sure we get back the initial base64 file correctly"
zbarimg --raw -Sdisable -Sqrcode.enable pages.pdf > read_base64.txt
if ! diff -u read_base64.txt full_base64.txt; then
    echo "Error: Weren't able to reconstruct original file when scanning the created pdf with a QR scanner."
    rm -rf "${PWD}"
    exit 1
fi
echo "Success: the read QR codes matched the initial base64 file"
echo "To reconstruct the file, scan the QR codes, concatenate the results into a single file and decode it as base64"

mv pages.pdf "${OLD_PWD}/${INPUT_BASENAME}.pdf"

rm -rf "${PWD}"
