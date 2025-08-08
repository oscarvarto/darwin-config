#!/usr/bin/env zsh

for file in /Users/oscarvarto/.emacs.d/.local/straight/build-31.0.50/tree-sitter-langs/bin/*.dylib; do
  lang=$(basename $file .dylib)
  ln -s $file /Users/oscarvarto/.emacs.d/.local/cache/tree-sitter/libtree-sitter-$lang.dylib
done
