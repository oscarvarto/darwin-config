;;; my-sql-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

(add-hook 'sql-mode-hook 'lsp)
(setq lsp-sqls-workspace-config-path nil)
;; Configure SQL connections using environment variables or defaults
(setq lsp-sqls-connections
      (list (list (cons 'driver "mysql") 
                  (cons 'dataSourceName 
                        (format "db_user:local@tcp(localhost:%s)/%s"
                                (or (getenv "WORK_DB_PORT") "3306")
                                (or (getenv "WORK_DB_NAME") "your_db"))))))
