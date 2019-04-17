## About
This script will attempt to scan input PDFs for OCR text. For use needs Ruby as well as the `pdf-reader`
ruby gem, which can be installed with the command `gem install pdf-reader` in a terminal.

## Usage
Example: `ocr_test.rb FOLDER-WITH-PDFS input2.pdf input3.pdf`

This script can accept either directories or files (or a combination of these) as inputs.
It will scan all input directories for PDFs and will attempt to find text in all PDFs discovered.

After running, the script will create a `.csv` file on the Desktop with results.
