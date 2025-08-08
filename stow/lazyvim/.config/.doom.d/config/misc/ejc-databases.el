;;; ejc-databases.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Load the secure credential retrieval functions
(require 'my-auth-helpers)

;; SECURITY NOTE:
;; Database credentials are retrieved securely using either:
;; 1. ~/.authinfo.gpg - Create entries in this encrypted file using the format:
;;    machine DATABASE-NAME-db login USERNAME password PASSWORD
;;    Example: machine sqlnovel-db login oscarvarto password your_secure_password
;;
;; 2. 1Password CLI - Create items in 1Password with the database name as the item name
;;    and standard username/password fields
;;
;; For 1Password CLI to work, make sure to run `op signin` in terminal if your session expires

;; MySQL example with secure credential retrieval
(my/ejc-create-connection-with-auth
 "SQLNovel"
 :classpath (concat "~/.m2/repository/mysql/mysql-connector-java/8.0.26/"
                    "mysql-connector-java-8.0.26.jar")
 :subprotocol "mysql"
 :subname "//localhost:3306/SQLNovel?autoReconnect=true&useSSL=false"
 :auth-source-user "oscarvarto"
 :op-item "SQLNovel")

(provide 'ejc-databases)

;;; ejc-databases.el ends here
