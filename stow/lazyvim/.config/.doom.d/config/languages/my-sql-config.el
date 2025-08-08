;;; my-sql-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

(add-hook 'sql-mode-hook 'lsp)
(setq lsp-sqls-workspace-config-path nil)
(setq lsp-sqls-connections
    '(((driver . "mysql") (dataSourceName . "sqa_automation:local@tcp(localhost:3318)/irhythmd"))))
