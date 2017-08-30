;;; diff-hl-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "diff-hl" "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl.el"
;;;;;;  "c68f458cea3212e064d0f96a85625002")
;;; Generated autoloads from ../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl.el

(autoload 'diff-hl-mode "diff-hl" "\
Toggle VC diff highlighting.

\(fn &optional ARG)" t nil)

(autoload 'turn-on-diff-hl-mode "diff-hl" "\
Turn on `diff-hl-mode' or `diff-hl-dir-mode' in a buffer if appropriate.

\(fn)" nil nil)

(defvar global-diff-hl-mode nil "\
Non-nil if Global Diff-Hl mode is enabled.
See the `global-diff-hl-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-diff-hl-mode'.")

(custom-autoload 'global-diff-hl-mode "diff-hl" nil)

(autoload 'global-diff-hl-mode "diff-hl" "\
Toggle Diff-Hl mode in all buffers.
With prefix ARG, enable Global Diff-Hl mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Diff-Hl mode is enabled in all buffers where
`turn-on-diff-hl-mode' would do it.
See `diff-hl-mode' for more information on Diff-Hl mode.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil "diff-hl-amend" "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-amend.el"
;;;;;;  "1d6e113a9bd0373b5859246f916f9f93")
;;; Generated autoloads from ../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-amend.el

(autoload 'diff-hl-amend-mode "diff-hl-amend" "\
Show changes against the second-last revision in `diff-hl-mode'.
Most useful with backends that support rewriting local commits,
and most importantly, 'amending' the most recent one.
Currently only supports Git, Mercurial and Bazaar.

\(fn &optional ARG)" t nil)

(defvar global-diff-hl-amend-mode nil "\
Non-nil if Global Diff-Hl-Amend mode is enabled.
See the `global-diff-hl-amend-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-diff-hl-amend-mode'.")

(custom-autoload 'global-diff-hl-amend-mode "diff-hl-amend" nil)

(autoload 'global-diff-hl-amend-mode "diff-hl-amend" "\
Toggle Diff-Hl-Amend mode in all buffers.
With prefix ARG, enable Global Diff-Hl-Amend mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Diff-Hl-Amend mode is enabled in all buffers where
`turn-on-diff-hl-amend-mode' would do it.
See `diff-hl-amend-mode' for more information on Diff-Hl-Amend mode.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil "diff-hl-dired" "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-dired.el"
;;;;;;  "a5f517561fc9162cbb044308275549f8")
;;; Generated autoloads from ../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-dired.el

(autoload 'diff-hl-dired-mode "diff-hl-dired" "\
Toggle VC diff highlighting on the side of a Dired window.

\(fn &optional ARG)" t nil)

(autoload 'diff-hl-dired-mode-unless-remote "diff-hl-dired" "\


\(fn)" nil nil)

;;;***

;;;### (autoloads nil "diff-hl-flydiff" "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-flydiff.el"
;;;;;;  "735aff02a443c01a51771f3ba0118568")
;;; Generated autoloads from ../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-flydiff.el

(defvar diff-hl-flydiff-mode nil "\
Non-nil if Diff-Hl-Flydiff mode is enabled.
See the `diff-hl-flydiff-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `diff-hl-flydiff-mode'.")

(custom-autoload 'diff-hl-flydiff-mode "diff-hl-flydiff" nil)

(autoload 'diff-hl-flydiff-mode "diff-hl-flydiff" "\
Perform highlighting on-the-fly.
This is a global minor mode.  It alters how `diff-hl-mode' works.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil "diff-hl-margin" "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-margin.el"
;;;;;;  "5eeebde69878ea3a0efa7a748da419da")
;;; Generated autoloads from ../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-margin.el

(defvar diff-hl-margin-mode nil "\
Non-nil if Diff-Hl-Margin mode is enabled.
See the `diff-hl-margin-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `diff-hl-margin-mode'.")

(custom-autoload 'diff-hl-margin-mode "diff-hl-margin" nil)

(autoload 'diff-hl-margin-mode "diff-hl-margin" "\
Toggle displaying `diff-hl-mode' highlights on the margin.

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-amend.el"
;;;;;;  "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-autoloads.el"
;;;;;;  "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-dired.el"
;;;;;;  "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-flydiff.el"
;;;;;;  "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-margin.el"
;;;;;;  "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl-pkg.el"
;;;;;;  "../../../../.emacs.d/elpa-25.2/diff-hl-20170709.2000/diff-hl.el")
;;;;;;  (22950 47899 684035 418000))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; diff-hl-autoloads.el ends here
