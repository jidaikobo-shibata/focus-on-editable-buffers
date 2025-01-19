;;; anything-focus-on-editable-buffers.el --- use `focus-on-editable-buffers' at `anything'.
;; maintainer: jidaikobo-shibata
;; supervise: rubikitch
;; keywords: buffer switch switch-to-prev-buffer switch-to-next-buffer kill-buffer anything
;; version: 0.1
;; for emacs 25.1.1
;; Dependencies: `focus-on-editable-buffers.el'

;; this program is free software; you can redistribute it and/or modify
;; it under the terms of the gnu general public license as published by
;; the free software foundation, either version 3 of the license, or
;; (at your option) any later version.
;;
;; this program is distributed in the hope that it will be useful,
;; but without any warranty; without even the implied warranty of
;; merchantability or fitness for a particular purpose.  see the
;; gnu general public license for more details.
;;
;; you should have received a copy of the gnu general public license
;; along with this program.  if not, see <http://www.gnu.org/licenses/>.

;;; commentary:
;; part of focus-on-editable-buffers.el

;;; usage:
;; (require 'anything-focus-on-editable-buffers)
;; foeb/anything-execute-persistent-action-2 is kill-buffer
;; (define-key anything-map "\C-d" 'foeb/anything-execute-persistent-action-2)

;;; code:

;;; ------------------------------------------------------------
;;; defvar

(require 'anything)

(defvar foeb/is-use-anything-execute-persistent-action nil)

;;; ------------------------------------------------------------
;;; auto follow mode

(unless (boundp 'anything-use-follow-mode)
  (defvar anything-use-follow-mode nil)
  (defun anything-after-initialize-hook--use-follow-mode ()
    "anything-after-initialize-hook--use-follow-mode."
    (when anything-use-follow-mode
      (with-current-buffer anything-buffer
        (setq-local anything-follow-mode t))))
  (add-hook 'anything-after-initialize-hook 'anything-after-initialize-hook--use-follow-mode))

;;; ------------------------------------------------------------
;; source of anything - target buffers

(defvar foeb/anything-c-source-buffers
  '((name . "Buffers")
    (candidates . (lambda () (foeb/target-buffers t)))
    (persistent-action . (lambda (candidate) (anything-c-switch-to-buffer candidate)))
    (persistent-action-2 . (lambda (candidate) (anything-c-buffers-persistent-kill candidate)))
    (action . (lambda (candidate) (anything-c-switch-to-buffer candidate)))))

(defvar foeb/anything-c-source-dired-buffers
  '((name . "Dired Buffers")
    (candidates . (lambda () (foeb/dired-buffers t)))
    (persistent-action . (lambda (candidate) (anything-c-switch-to-buffer candidate)))
    (persistent-action-2 . (lambda (candidate) (anything-c-buffers-persistent-kill candidate)))
    (action . (lambda (candidate) (anything-c-switch-to-buffer candidate)))))

;; foeb/anything-for-buffers
(defun foeb/anything-for-buffers ()
  "Anything command for files and commands."
  (interactive)
  (if foeb/is-use-anything-execute-persistent-action
      (anything :sources '(foeb/anything-c-source-buffers
                           foeb/anything-c-source-dired-buffers)
                :use-follow-mode t)
    (anything :sources '(foeb/anything-c-source-buffers
                         foeb/anything-c-source-dired-buffers))))

;; foeb/anything-execute-persistent-kill
;; thx http://d.hatena.ne.jp/rubikitch/20081007/1223388391

(defun foeb/anything-execute-persistent-kill ()
  "Execute additional persistent kill action."
  (interactive)
  (anything-execute-persistent-action 'persistent-action-2))

;;; ------------------------------------------------------------
;;; Provide

(provide 'anything-focus-on-editable-buffers)

;;; anything-focus-on-editable-buffers.el ends here
