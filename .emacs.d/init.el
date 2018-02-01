;;; package -- init

;;; Commentary:
;;; init.el --- Custom Emacs Configuration
;;; Author: Alamin Mahamud
;;; Version: 3.0.0
;;; Keywords: Configuration Emacs
;;; URL: https://github.com/AlaminMahamud/.emacs.d/init.el

;;; Code:

(package-initialize)

(require 'ob-tangle)
(org-babel-load-file
 (expand-file-name
  "README.org"
  user-emacs-directory))
;;; init.el ends here
