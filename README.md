# Paper Store

A bash script for cold storing small files on paper.

Store your PGP keys, Bitcoin wallet keys, Tox profile keys, etc. on paper.

Works the best with files below 50KiB, as the resulting page count increases very fast.

## Examples

[Input file](examples/input.txt), [sparse PDF](examples/output_sparse.pdf), [dense PDF](examples/output_dense.pdf).

## How it works

The script takes a file path as an argument, computes base64 of the file, splits the base64 into 12-line pieces, encodes each piece in a QR code, and generates a printable PDF file with all those QR codes. 
The PDF is tested by a QR reader to make sure that you can restore the original base64 of the file off the PDF.
(Each QR code encodes only 12 lines of base64 because QR readers have trouble decoding QR codes that contain more information than that.)

To restore the file, decode the printed QR codes, concatenate the results in the page order into a single file and decode that file as base64.

## Script variants

There are two variants of the script: sparse and dense.

Sparse version prints just one QR code per page and includes the encoded in the QR code text for the reference of what the QR code should decode to.

Dense version prints four QR codes per page and nothing more.
Each QR code is numbered within the page, so that you know in which order to scan them.

Both sparse and dense versions result in pages that are foldable in half without QR codes being on the folding line.
The sparse version is foldable in half exactly once.
The dense version is foldable in half exactly twice.

## Usage

Make sure you have `pdflatex`, `pdfunite`, `qrencode` and `zbarimg` programs installed, along with some common fonts.

On Debian/Ubuntu systems you can install them with

```bash
apt-get install poppler-utils texlive-fonts-recommended texlive-latex-base qrencode zbar-tools
```

Run the scripts as

```bash
bash paper_store_sparse.sh <path-to-file>
```

and 

```bash
bash paper_store_dense.sh <path-to-file>
```

The scripts create A4-sized PDFs by default.
If you want to change the paper size to something other than A4, set the environment variable `PAPER_STORE_PAPER_SIZE` to any of: a0paper, a1paper, a2paper, a3paper, a4paper, a5paper, a6paper, b0paper, b1paper, b2paper, b3paper, b4paper, b5paper, b6paper, c0paper, c1paper, c2paper, c3paper, c4paper, c5paper, c6paper, b0j, b1j, b2j, b3j, b4j, b5j, b6j, ansiapaper, ansibpaper, ansicpaper, ansidpaper, ansiepaper, letterpaper, executivepaper and legalpaper.

For example, if you want to set the paper size to Letter, do

```bash
PAPER_STORE_PAPER_SIZE=letterpaper bash paper_store_dense.sh <path-to-file>
```

Note that only A4 and Letter paper sizes were tested, other paper sizes will likely not work.
Feel free to contribute a LaTeX template that scales well with the paper size, just don't scale up the images above 100% scale, QR readers have trouble scanning large QR codes.

## Troubleshooting

The script tests if the original file can be restored off the PDF by scanning the QR codes with `zbarimg` and comparing the result against the base64 of the input file.
Sometimes `zbarimg` fails to scan a QR code correctly, which is a false negative, and the script fails thinking that the original file can't be restored off the PDF.
There is not much that can be done here to determine if it's indeed a false negative or it's actually a true negative, you can't just run the test several times, there is no non-determinism anywhere, you get the exactly the same result no mater how many times you scan the PDF with `zbarimg`, so the right to make the call is on you.
If you think that it is indeed a false negative, just remove the early exit on the error path from the script and don't forget to put it back later.

## Consider encrypting your file

Consider encrypting your file if it's not already encrypted before storing it on paper.
Even if it's encrypted already, like the passphrase-protected GPG keystore, you might still consider encrypting it once more just to hide any unencrypted metadata, e.g. the public keys and uids are not encrypted in passphrase-protected GPG keystores, only private keys are encrypted, so whoever scans your QR codes would know that it's a GPG keystore for those public keys and the person behind the uid identity, which might not be desirable.

You can use GPG to password-protect your file like this

```bash
gpg --symmetric --cipher-algo AES256 --s2k-digest-algo SH512 <file-to-encrypt>
```

This will encrypt the file with a symmetric AES256 cipher.
It will prompt you to come up with a passphrase, which is all you need to remember to decrypt the file in the future.
Make sure you select a good passphrase.
It should be at least 40 characters long and be hard to bruteforce, i.e. avoid using quotes of any kind, like book quotes, song lyrics, dates of birth, phone numbers, etc.

You could also encrypt it with your existing PGP key and your preferred ciphers with

```bash
gpg --encrypt <file-to-encrypt>
```

## License

MIT License
