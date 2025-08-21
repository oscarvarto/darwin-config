# Snippets Directory

This directory contains custom YASnippet snippets for use in Doom Emacs.

## Structure

YASnippet expects directories named after major modes:
- `java-mode/` - Java snippets
- `python-mode/` - Python snippets  
- `nix-mode/` - Nix snippets
- `elisp-mode/` - Emacs Lisp snippets
- `org-mode/` - Org mode snippets

## Configuration

To make Doom Emacs use these snippets, add this to your Doom configuration:

```elisp
(after! yasnippet
  (add-to-list 'yas-snippet-dirs (expand-file-name "~/doom-extra-files/snippets")))
```

## Snippet Format

Each snippet is a file with this format:
```
# -*- mode: snippet -*-
# name: snippet-name
# key: trigger-key
# --
snippet content with $1 placeholders $0
```
