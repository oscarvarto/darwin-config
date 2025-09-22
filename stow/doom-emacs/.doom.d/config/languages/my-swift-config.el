;;; my-swift-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Configure Swift to use Apple's swift-format tool for on-demand formatting

(after! lsp-sourcekit
  ;; Configure LSP to use Apple's swift-format for formatting
  ;; The formatter expects stdin input and stdout output (no --in-place for buffer formatting)
  (set-formatter! 'swiftformat '("/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-format" "format")))

(provide 'my-swift-config)
