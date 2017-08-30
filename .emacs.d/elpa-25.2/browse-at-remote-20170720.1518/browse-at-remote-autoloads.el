;;; browse-at-remote-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "browse-at-remote" "../../../../.emacs.d/elpa-25.2/browse-at-remote-20170720.1518/browse-at-remote.el"
;;;;;;  "bbaf81021ca7ee827b9f2daa47982492")
;;; Generated autoloads from ../../../../.emacs.d/elpa-25.2/browse-at-remote-20170720.1518/browse-at-remote.el

(autoload 'browse-at-remote "browse-at-remote" "\
Browse the current file with `browse-url'.

\(fn)" t nil)

(autoload 'browse-at-remote-kill "browse-at-remote" "\
Add the URL of the current file to the kill ring.

Works like `browse-at-remote', but puts the address in the
kill ring instead of opening it with `browse-url'.

\(fn)" t nil)

(defalias 'bar-browse 'browse-at-remote "\
Browse the current file with `browse-url'.")

(defalias 'bar-to-clipboard 'browse-at-remote-kill "\
Add the URL of the current file to the kill ring.

Works like `browse-at-remote', but puts the address in the
kill ring instead of opening it with `browse-url'.")

;;;***

;;;### (autoloads nil nil ("../../../../.emacs.d/elpa-25.2/browse-at-remote-20170720.1518/browse-at-remote-autoloads.el"
;;;;;;  "../../../../.emacs.d/elpa-25.2/browse-at-remote-20170720.1518/browse-at-remote.el")
;;;;;;  (22950 47979 455934 400000))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; browse-at-remote-autoloads.el ends here
