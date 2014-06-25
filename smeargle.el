;;; smeargle.el --- Highlighting region by last updated time -*- lexical-binding: t; -*-

;; Copyright (C) 2014 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-smeargle
;; Version: 0.01
;; Package-Requires: ((cl-lib "0.5") (emacs "24"))

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

;;; Code:

(require 'cl-lib)

(defgroup smeargle nil
  "Highlight regions by last updated time."
  :group 'vc)

(defcustom smeargle-colors
  '((older-than-1day . nil)
    (older-than-3day . "grey5")
    (older-than-1week . "grey10")
    (older-than-2week . "grey15")
    (older-than-1month . "grey20")
    (older-than-3month . "grey25")
    (older-than-6month . "grey30")
    (older-than-1year . "grey35"))
  "Alist of last updated era and background color."
  :type '(repeat (cons (symbol :tag "How old")
                       (string :tag "Background color name")))
  :group 'smeargle)

(defun smeargle--updated-era (now updated-date)
  (let* ((delta (decode-time (time-subtract now updated-date)))
         (delta-year (- (nth 5 delta) 1970))
         (delta-month (nth 4 delta))
         (delta-day (nth 3 delta)))
    (cond ((>= delta-year 1) 'older-than-1year)
          ((> delta-month 6) 'older-than-6month)
          ((> delta-month 3) 'older-than-3month)
          ((> delta-month 1) 'older-than-1month)
          ((>= delta-day 14) 'older-than-2week)
          ((>= delta-day 7) 'older-than-1week)
          ((>= delta-day 3) 'older-than-3day))))

(defsubst smeargle--date-regexp (repo-type)
  (cl-case repo-type
    (git "\\(\\S-+ \\S-+ \\S-+\\)\\s-+[1-9][0-9]*)")
    (mercurial "^\\(.+?\\): ")))

(defun smeargle--parse-blame (proc repo-type)
  (with-current-buffer (process-buffer proc)
    (goto-char (point-min))
    (let ((update-date-regexp (smeargle--date-regexp repo-type))
          (now (current-time))
          (curline 1)
          start update-info last-update)
      (while (re-search-forward update-date-regexp nil t)
        (let* ((updated-date (date-to-time (match-string-no-properties 1)))
               (update-era (smeargle--updated-era now updated-date)))
          (when (and (not last-update) update-era)
            (setq start curline last-update update-era))
          (when (and last-update (not (eq last-update update-era)))
            (push (list :start start :end (1- curline) :type last-update)
                  update-info)
            (setq start curline last-update update-era))
          (cl-incf curline)
          (forward-line 1)))
      (push (list :start start :end curline :type last-update) update-info)
      (reverse update-info))))

(defun smeargle--highlight (update-info curbuf)
  (with-current-buffer curbuf
    (save-excursion
      (goto-char (point-min))
      (let ((curline 1))
        (dolist (info update-info)
          (let ((start-line (plist-get info :start))
                (end-line (1+ (plist-get info :end)))
                (color (assoc-default (plist-get info :type) smeargle-colors))
                start)
            (forward-line (- start-line curline))
            (setq start (point))
            (forward-line (- end-line start-line))
            (setq curline end-line)
            (let ((ov (make-overlay start (point))))
              (overlay-put ov 'face `(:background ,color))
              (overlay-put ov 'smeargle t))))))))

(defun smeargle--blame-command (repo-type)
  (let ((bufname (buffer-file-name)))
    (cl-case repo-type
      (git `("git" "--no-pager" "blame" ,bufname))
      (mercurial `("hg" "blame" "-d" ,bufname)))))

(defun smeargle--start-blame-process (repo-type proc-buf)
  (let* ((curbuf (current-buffer))
         (cmds (smeargle--blame-command repo-type))
         (proc (apply 'start-process "smeargle" proc-buf cmds)))
    (set-process-query-on-exit-flag proc nil)
    (set-process-sentinel
     proc
     (lambda (proc _event)
       (when (eq (process-status proc) 'exit)
         (let ((update-info (smeargle--parse-blame proc repo-type)))
           (smeargle--highlight update-info curbuf)
           (kill-buffer proc-buf)))))))

(defsubst smergle--process-buffer (bufname)
  (get-buffer-create (format " *smeargle-%s*" bufname)))

(defsubst smeargle--repo-type ()
  (cl-loop for (type . repo-dir) in '((git . ".git") (mercurial . ".hg"))
           when (locate-dominating-file default-directory repo-dir)
           return type))

;;;###autoload
(defun smeargle-clear ()
  (interactive)
  (dolist (ov (overlays-in (point-min) (point-max)))
    (when (overlay-get ov 'smeargle)
      (delete-overlay ov))))

;;;###autoload
(defun smeargle ()
  (interactive)
  (smeargle-clear)
  (let ((repo-type (smeargle--repo-type)))
    (unless repo-type
      (error "Here is not 'git' or 'mercurial' repository"))
    (smeargle--start-blame-process
     repo-type (smergle--process-buffer (buffer-file-name)))))

(provide 'smeargle)

;;; smeargle.el ends here
