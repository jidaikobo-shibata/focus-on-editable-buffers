;;; focus-on-editable-buffers.el --- Focus on Editable Buffers at `switch-to-buffer' and `kill-buffer'.
;; Maintainer: jidaikobo-shibata
;; Supervise: rubikitch
;; Keywords: buffer switch switch-to-prev-buffer switch-to-next-buffer kill-buffer
;; Version: 0.1
;; for Emacs 25.1.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; [en]
;; This is a package for excludes buffers starting with *, blank, +,
;;
;; [ja]
;; *、空白、+などではじまるバッファを対象外としたswitch-to-prev-buffer/switch-to-next-bufferを
;; するためのpackageです。
;; kill-bufferの代わりにfoeb/kill-bufferを使うことで、
;; kill-bufferのあとに編集できない書類にswitchしなくなります。
;;
;;; Usage:
;; (require 'focus-on-editable-buffers)
;; You may use `foeb/kill-buffer' instaed of `kill-buffer' at C-x k

;;; Code:

;;; ------------------------------------------------------------
;;; defvar

(defvar foeb/is-use-advice-delete-window nil)

(defvar foeb/non-ignore-command-when-kill-buffer
      (rx
       (or
        "my-anything-for-files"
        "anything-for-files")))

(defvar foeb/non-ignore-mode-when-kill-buffer
      (rx
       (or
        "dired-mode")))

(defvar foeb/non-ignore-buffers
      (rx
       (or
        "*scratch*")))

(defvar foeb/ignore-buffers
      (rx
       (or
        ;; start with space / asterisk / plus
        (group bos " ")
        (group bos "*")
        (group bos "+"))))

(defvar foeb/ignore-modes
      (rx
       (or
        "dired-mode")))

;;; ------------------------------------------------------------
;;; switch to neighbour buffers

(defun foeb/switch-to-neighbour-buffer (&optional is-next)
  "Switch to next or previous buffer of `buffer-list'.
It will not change buffer order.
IS-NEXT is Non-nil switch to next buffer."
  (let* ((blist (if is-next (foeb/target-buffers) (reverse (foeb/target-buffers))))
         (last-buffer (car (reverse blist)))
         buffer)
    ;; (message "%s %s %s" blist last-buffer (current-buffer))
    ;; if `current-buffer' is last buffer,
    ;; or stuck to ignore buffer, return to fisrt buffer
    (if (or (eq (current-buffer) last-buffer)
            (foeb/ignore-buffer-name-p (buffer-name (current-buffer))))
        (switch-to-buffer (car blist) t)
      ;; search cuurent buffer
      (while blist
        (setq buffer (car blist))
        (setq blist (cdr blist))
        (when (eq (current-buffer) buffer)
          (switch-to-buffer (car blist) t)
          (setq blist nil))))))

(defun foeb/switch-to-prev-buffer ()
  "Switch to previous buffer of `buffer-list'."
  (interactive)
  (foeb/switch-to-neighbour-buffer))

(defun foeb/switch-to-next-buffer ()
  "Switch to next buffer of `buffer-list'."
  (interactive)
  (foeb/switch-to-neighbour-buffer t))

;;; ------------------------------------------------------------
;;; get target buffers

(defun foeb/target-buffers (&optional by-name)
  "Prepare target buffers.  Non-nil of BY-NAME then return `buffer-name'."
  (let ((blist (buffer-list))
        buffer
        (ret (list)))
    (while blist
      (setq buffer (car blist))
      (setq blist (cdr blist))
      (unless (with-current-buffer buffer
                (foeb/ignore-buffer-name-p (buffer-name buffer)))
        (when by-name (setq buffer (buffer-name buffer)))
        (add-to-list 'ret buffer t)))
    (if ret ret '("*scratch*"))))

(defun foeb/ignore-buffer-name-p (buffer)
  "If ignore buffer given return t.  BUFFER is buffer name."
  (let ((non-ignore-buffers foeb/non-ignore-buffers)
        (ignore-buffers foeb/ignore-buffers)
        (ignore-modes foeb/ignore-modes))
    (if (string-match non-ignore-buffers buffer)
        nil
      (or (string-match ignore-buffers buffer)
          (with-current-buffer buffer (string-match ignore-modes (format "%s" major-mode)))))))

;;; ------------------------------------------------------------
;;; buffers of dired

(defun foeb/dired-buffers (&optional by-name)
  "Prepare dired buffers.  Non-nil of BY-NAME then return `buffer-name'."
  (let ((blist (buffer-list))
        buffer
        (ret (list)))
    (while blist
      (setq buffer (car blist))
      (setq blist (cdr blist))
      (when (with-current-buffer buffer
              (string-match "\\(?:dired-mode\\)" (format "%s" major-mode)))
        (when by-name (setq buffer (buffer-name buffer)))
        (add-to-list 'ret buffer t)))
    ret))

;;; ------------------------------------------------------------
;;; switch to non ignore buffer.  to the first item of buffer list.

(defun foeb/switch-to-non-ignore-buffer ()
  "Switch to non ignore buffer after `kill-buffer' and so on."
  (when (foeb/ignore-buffer-name-p (buffer-name (current-buffer)))
    (switch-to-buffer (car (foeb/target-buffers)) t)))

;;; ------------------------------------------------------------
;; foeb/kill-buffer. to avoide chaotic situation.

(defun foeb/kill-buffer (&optional BUFFER-OR-NAME)
  "To avoide chaotic situation when give advice to native `kill-buffer'.
BUFFER-OR-NAME is compatible."
  (if BUFFER-OR-NAME
      (kill-buffer BUFFER-OR-NAME)
    (kill-buffer))
  (let ((non-ignore-command-when-kill-buffer foeb/non-ignore-command-when-kill-buffer)
        (non-ignore-mode-when-kill-buffer foeb/non-ignore-mode-when-kill-buffer))
    (unless (or (string-match non-ignore-command-when-kill-buffer (format "%s" this-command))
                (string-match non-ignore-mode-when-kill-buffer (format "%s" major-mode)))
      (foeb/switch-to-non-ignore-buffer))))

;;; ------------------------------------------------------------
;;; advice

(when foeb/is-use-advice-delete-window
  (defadvice delete-window (after delete-window-dont-switch-to-ignores activate)
    "After delete window, do not switch to ignore buffer."
    (foeb/switch-to-non-ignore-buffer)))

;;; ------------------------------------------------------------
;;; Provide

(provide 'focus-on-editable-buffers)

;;; focus-on-editable-buffers.el ends here
