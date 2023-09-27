#!/bin/bash

# TODO
# - Order: extract index based on metadata, prepend index to filename?
# - Package in docker-image to aleviate dependencies
# - Index
# - Sexier chapter headings?
# - Multi-level structure (parts for software / hardware, chapters, ...)

# Clean slate
rm -rf _reader
mkdir -p _reader/img

incMdDirs="software hardware-interfacing"                 # Find MD files only in these directories, ignore global readme and meta-documentation

# Regexps for reuse
rePath='s/!\[([^]]*)\]\(.*\/(.*\..*)\)/![\1](img\/\2)/g'  # Change image paths to flat structure (_reader/img/...)
rePngSvg='s/svg/png/g'                                    # Change svg to png in file links / coverted file names
reSpace='s/ /_/g'                                         # Fork spaces in filenames
rePct20='s/%20/_/g'                                       # HTML entity for space
reAmp='s/&/amp/g'                                         # Ampersands in filenames fork up LaTeX

# Space-in-filename-safe loop over find results
find . \( -name "*.png" -or -name "*.jpg" -or -name "*.gif" -or -name "*.webp" \) -print0 |
  while IFS= read -r -d '' file; do
    target="_reader/img/$(echo $(basename "$file") | sed -e "$reSpace" -e "$rePct20" -e "$reAmp")" # Sanitise filenames, move all images to single directory
    cp "$file" "$target"
done

find . -name "*.svg" -print0 |
  while IFS= read -r -d '' file; do
    target="_reader/img/$(echo $(basename "$file") | sed -e "$reSpace" -e "$rePct20" -e "$reAmp" -e "$rePngSvg")" # Sanitise filenames, convert and move
    inkscape --export-type=png --export-filename="$target" "$file" 2>/dev/null # Not an ideal dependency, but much better results than svg2png
done

find $incMdDirs -name "*.md" -print0 |
  while IFS= read -r -d '' file; do
    target="_reader/$(echo $file | sed -e 's/\//_/g')"
    cat $file | sed -r -e "$rePath" -e "$rePngSvg" -e "$rePct20" -e "/^!/$reAmp" > $target
                                                                    # Only apply reAmp in image embeds
done

# Copy eisvogel if present in current directory, or else download from GitHub
cp eisvogel.tex _reader || curl https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/master/eisvogel.tex > _reader/eisvogel.tex

cp metadata.yaml _reader
echo "title: $(basename $PWD)" >> _reader/metadata.yaml
echo "date: $(date +"%e %B %Y")" >> _reader/metadata.yaml

# In _reader, concat all the files into a single PDF
cd _reader
pandoc $(find . -name "*.md" | sort) --metadata-file metadata.yaml -o result.pdf --template eisvogel.tex --listings

cp result.pdf ..
