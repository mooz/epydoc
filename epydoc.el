;;; epydoc.el --- pydoc interface for emacs

;; Copyright (C) 2010  mooz

;; Author: mooz <stillpedant@gmail.com>
;; Keywords: python, anything, imenu

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Usage:

;;; Code:

(defvar epydoc--module-directories
  (list "/usr/lib/python2.6"
        "/usr/lib/pymodules/python2.6"))

(defun epydoc--get-all-modules ()
  (sort (loop for dir in epydoc--module-directories
              append (epydoc--get-modules dir))
        'string<))

(defun epydoc--get-modules (directory)
  (sort (loop for entry in (file-name-all-completions "" directory)
              if (and (string-match "\\(.*\\)\\(\\.py\\|/\\)$" entry)
                      (not (string-match-p "\\." entry)))
              collect (match-string-no-properties 1 entry))
        'string<))

(defun epydoc--view-doc (&rest args)
  (when args
    ;; XXX: with-current-buffer
    (switch-to-buffer (get-buffer-create "*Pydoc*"))
    (setq buffer-read-only nil)
    (delete-region (point-min) (point-max))
    (apply 'call-process (append '("pydoc" nil t nil) args))
    (unless (eq major-mode 'view-mode)
      (view-mode 1))
    (epydoc--setup-imenu)
    (setq buffer-read-only t)
    (goto-char (point-min))))

;; ============================================================ ;;
;; anything support
;; ============================================================ ;;

(defvar anything-c-source-python-modules
  '((name . "Pyhton Modules")
    (candidates . (lambda () (epydoc--get-all-modules)))
    (action . (("Show document" . (lambda (doc) (epydoc--view-doc doc))))))
  "Source for completing Python modules.")

(setq anything-c-source-python-modules
      '((name . "Pyhton Modules")
        (candidates . (lambda () (epydoc--get-all-modules)))
        (action . (("Show document" . (lambda (doc) (epydoc--view-doc doc)))))))

;; ============================================================ ;;
;; imenu support
;; ============================================================ ;;

(defun epydoc--imenu-create-function-index ()
  (cons "CLASSES"
        (let (index)
          (goto-char (point-min))
          (while (re-search-forward "^\s*class\s+\\([^(]+\\)" (point-max) t)
            (push (cons (match-string 1) (match-beginning 1)) index))
          (nreverse index))))

(defun epydoc--imenu-create-header-index ()
  (cons "HEADER"
        (let (index)
          (goto-char (point-min))
          (while (re-search-forward "^\\([A-Z][A-Z ]+\\)$" (point-max) t)
            (push (cons (match-string 1) (match-beginning 1)) index))
          (nreverse index))))

(defun epydoc--imenu-create-index ()
  (list
   (epydoc--imenu-create-header-index)
   (epydoc--imenu-create-function-index)))

(defun epydoc--setup-imenu ()
  (make-local-variable imenu-create-index-function)
  (setq imenu-create-index-function 'epydoc--imenu-create-index))

;; ============================================================ ;;
;; commands
;; ============================================================ ;;

(defun epydoc-view-module-anything ()
  "View documentaion of python with anything"
  (interactive)
  (anything :sources anything-c-source-python-modules))

(provide 'epydoc)
;;; epydoc.el ends here
