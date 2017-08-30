;;; gitconfig-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "gitconfig-mode" "../../../../.emacs.d/elpa-25.2/gitconfig-mode-20170627.854/gitconfig-mode.el"
;;;;;;  "7ec52aaa33b806fa2c76b6c4f2df0e32")
;;; Generated autoloads from ../../../../.emacs.d/elpa-25.2/gitconfig-mode-20170627.854/gitconfig-mode.el

(autoload 'gitconfig-mode "gitconfig-mode" "\
A major mode for editing .gitconfig files.

\(fn)" t nil)

(dolist (pattern '("/\\.gitconfig\\'" "/\\.git/config\\'" "/modules/.*/config\\'" "/git/config\\'" "/\\.gitmodules\\'" "/etc/gitconfig\\'")) (add-to-list 'auto-mode-alist (cons pattern 'gitconfig-mode)))

;;;***

;;;### (autoloads nil nil ("../../../../.emacs.d/elpa-25.2/gitconfig-mode-20170627.854/gitconfig-mode-autoloads.el"
;;;;;;  "../../../../.emacs.d/elpa-25.2/gitconfig-mode-20170627.854/gitconfig-mode.el")
;;;;;;  (22950 47988 163913 47000))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; gitconfig-mode-autoloads.el ends here
