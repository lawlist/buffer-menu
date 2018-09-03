;;; A port of the Xemacs buffers menu-bar feature that works with Emacs 26.

;;; REPOSITORY:
;;; https://github.com/lawlist/buffer-menu

;;; CLONE:
;;; git clone https://github.com/lawlist/buffer-menu.git

;;; QUESTION THAT INSPIRED THIS LIBRARY:
;;; https://emacs.stackexchange.com/q/44243/2287

;;; SCREENSHOTS:
;;;
;;; https://www.lawlist.com/images/buffer_menu_a.png
;;;
;;; https://www.lawlist.com/images/buffer_menu_b.png
;;;
;;; https://www.lawlist.com/images/buffer_menu_c.png
;;;
;;; https://www.lawlist.com/images/buffer_menu_d.png

;;; DESCRIPTION:
;;;
;;; The default setting of this library is a grouping of buffers by major-mode,
;;; which appear in a drop-down menu from the menu-bar.  The function
;;; `menu-bar-update-buffers-2' can also be used to generate the same menu in a
;;; custom setup (assembly required), e.g., a mouse pop-up menu.  The variable
;;; `buffers-menu-max-size' is defined in `menu-bar.el`, and this library uses it
;;; also in the same manner.  As in the stock version, the symbol % indicates the
;;; buffer is read-only.  Unlike the stock version, each buffer is numbered in
;;; the menu to help the user see how many buffers of that menu/submenu exist
;;; (within the buffer max limits, supra).
;;;
;;; -  The variable setting of:  (setq buffers-menu-submenus-for-groups-p t)
;;;    places the buffers of each major-mode into a submenu of buffers.
;;;
;;; -  The variable setting of:  (setq complex-buffers-menu-p t)
;;;    gives each buffer its own submenu of options:  save buffer (if modified),
;;;    save buffer as, kill buffer, switch to buffer, switch to buffer other
;;;    frame.  The user may set `buffers-menu-switch-to-buffer-function' to
;;;    something other than `switch-to-buffer' if so desired.

;;; F.A.Q. (Frequently Asked Questions):
;;;
;;; Q:  How is this different from what C-mouse-1 pops up?
;;;
;;; A:  As to the built-in function `mouse-buffer-menu', and a default setting
;;;     of 4 for the variable `mouse-buffer-menu-mode-mult', there is no obvious
;;;     grouping of buffers by major-mode.  Setting a value of 1 or 2 for the
;;;     variable `mouse-buffer-menu-mode-mult' causes buffers to be grouped by
;;;     major-mode and the buffers are available in submenus of the major-modes.
;;;
;;;     Xemacs buffers-menu plugs-in to the menu-bar mechanism at the top of the
;;;     screen. The default settings have no submenus, but nevertheless group
;;;     buffers by major-mode and alphabetically within that major-mode.
;;;     Major-modes are not identified as such, but the buffers within each
;;;     major-mode grouping are separated from other major-mode groups with a
;;;     divider line.  When `buffers-menu-submenus-for-groups-p' is set to t,
;;;     this is very similar to the built-in `mouse-buffer-menu' (when setting
;;;     `mouse-buffer-menu-mode-mult' to a value of 1 or 0), except that the
;;;     latter displays the path to file-visiting buffers.  When setting
;;;     `complex-buffers-menu-p' to t, each buffer gets its own submenu of
;;;     options:  `switch-to-buffer', `switch-to-buffer-other-frame',
;;;     `save-buffer' (if modified), `write-file' of the current buffer which
;;;     is referred to as Save As, and `kill-buffer'.  There is presently no
;;;     comparable submenu options when using the built-in `mouse-buffer-menu'.

;;; SETUP INSTRUCTIONS:
;;;
;;; Let us assume that Emacs has created a folder called .emacs.d inside your
;;; HOME directory and we will refer to it as "~/.emacs.d".  Now, let us suppose
;;; that we want to create a directory for beta testing Lisp libraries -- to
;;; that end, we will create the folder beta-testing inside the ~/.emacs.d
;;; directory, and the path to that new directory that we just created will be
;;; ~/.emacs.d/beta-testing.  Now, let us visit the Gist on the internet and we
;;; see a button "Download ZIP" and we go for it and download the zipped archive
;;; to a place such as our Desktop or other location of your choice.  We then
;;; extract the file buffer-menu.el to the new directory we just created in the
;;; previous comment; i.e., ~/.emacs.d/beta-testing.  The path to the file will
;;; now be ~/.emacs.d/beta-testing/buffer-menu.el.  Now we must add the new
;;; directory to our load-path by adding the following line to our .emacs or
;;; init.el file:  (add-to-list 'load-path "~/.emacs.d/beta-testing/")
;;; Somewhere after the line where we just added the folder beta-testing to our
;;; load-path, we can then put (require 'buffer-menu).  There is no need to use
;;; a .el at the end.

;;; needed for things like `delete-if'
(unless (fboundp 'delete-if)
  (require 'cl))

(defcustom buffers-menu-xemacs-style t
  "*If non-nil, use the Xemacs style of handling the buffer menu-bar menu.
*If nil, then use the plain-old default/stock way of handling this."
  :type 'boolean
  :group 'menu)

(defvar buffers-menu-omit-chars-list '(?b ?p ?l ?d))

;;; The variable `buffers-menu-max-size' already exists in `menu-bar.el`.

(defcustom buffers-menu-format-buffer-line-function 'format-buffers-menu-line
  "*The function to call to return a string to represent a buffer in
the buffers menu.  The function is passed a buffer and a number
(starting with 1) indicating which buffer line in the menu is being
processed and should return a string containing an accelerator
spec. (Check out `menu-item-generate-accelerator-spec' as a convenient
way of generating the accelerator specs.) The default value
`format-buffers-menu-line' just returns the name of the buffer and
uses the number as the accelerator.  Also check out
`slow-format-buffers-menu-line' which returns a whole bunch of info
about a buffer.
-  Note: Gross Compatibility Hack: Older versions of this function prototype
only expected one argument, not two.  We deal gracefully with such
functions by simply calling them with one argument and leaving out the
line number.  However, this may go away at any time, so make sure to
update all of your functions of this type."
  :type 'function
  :group 'menu)

(defcustom buffers-menu-sort-function
  'sort-buffers-menu-by-mode-then-alphabetically
  "*If non-nil, a function to sort the list of buffers in the buffers menu.
It will be passed two arguments (two buffers to compare) and should return
t if the first is \"less\" than the second.  One possible value is
`sort-buffers-menu-alphabetically'; another is
`sort-buffers-menu-by-mode-then-alphabetically'."
  :type '(choice (const :tag "None" nil)
     function)
  :group 'menu)

(defcustom buffers-menu-grouping-function
  'group-buffers-menu-by-mode-then-alphabetically
  "*If non-nil, a function to group buffers in the buffers menu together.
It will be passed two arguments, successive members of the sorted buffers
list after being passed through `buffers-menu-sort-function'.  It should
return non-nil if the second buffer begins a new group.  The return value
should be the name of the old group, which may be used in hierarchical
buffers menus.  The last invocation of the function contains nil as the
second argument, so that the name of the last group can be determined.
-  The sensible values of this function are dependent on the value specified
for `buffers-menu-sort-function'."
  :type '(choice (const :tag "None" nil)
     function)
  :group 'menu)

(defcustom complex-buffers-menu-p nil
  "*If non-nil, the buffers menu will contain several commands.
Commands will be presented as submenus of each buffer line.  If this
is false, then there will be only one command: select that buffer."
  :type 'boolean
  :group 'menu)

(defcustom buffers-menu-submenus-for-groups-p nil
  "*If non-nil, the buffers menu will contain one submenu per group of buffers.
The grouping function is specified in `buffers-menu-grouping-function'.
If this is an integer, do not build submenus if the number of buffers
is not larger than this value."
  :type '(choice (const :tag "No Subgroups" nil)
     (integer :tag "Max. submenus" 10)
     (sexp :format "%t\n" :tag "Allow Subgroups" :value t))
  :group 'menu)

(defcustom buffers-menu-switch-to-buffer-function 'switch-to-buffer
  "*The function to call to select a buffer from the buffers menu.
`switch-to-buffer' is a good choice, as is `pop-to-buffer'."
  :type '(radio (function-item switch-to-buffer)
    (function-item pop-to-buffer)
    (function :tag "Other"))
  :group 'menu)

(defcustom buffers-menu-omit-function 'buffers-menu-omit-invisible-buffers
  "*If non-nil, a function specifying the buffers to omit from the buffers menu.
This is passed a buffer and should return non-nil if the buffer should be
omitted.  The default value `buffers-menu-omit-invisible-buffers' omits
buffers that are normally considered \"invisible\" (those whose name
begins with a space)."
  :type '(choice (const :tag "None" nil)
     function)
  :group 'menu)

(defvar buffers-menu-read-only-string "%"
"The string that precedes the buffer name in the menu, which will be displayed
if the buffer is read-only.  There will be one (1) space between this string
and the buffer name, unless the user chooses to modify the function named
`format-buffers-menu-line', or assign a different function to the variable named
`buffers-menu-format-buffer-line-function', which defaults to the former.
-  To the extent the user wishes a simple underscore character that precedes the
the buffer name, this variable can be set to a pair of double-quotes with nothing
in between \"\".")

;;; http://jkorpela.fi/chars/spaces.html
;;; Figure Space -- 'Tabular width', the width of digits.
(defvar buffers-menu-read-write-string (char-to-string ?\u2007)
"The string that precedes the buffer name in the menu, which will be displayed
if the buffer is read-write.  There will be one (1) space between this string
and the buffer name, unless the user chooses to modify the function named
`format-buffers-menu-line', or assign a different function to the variable named
`buffers-menu-format-buffer-line-function', which defaults to the former.
-  To the extent the user wishes a simple underscore character that precedes the
the buffer name, this variable can be set to a pair of double-quotes with nothing
in between \"\".")

(defun buffer-menu-save-buffer (buffer)
  (with-current-buffer buffer
    (save-buffer)))

(defun buffer-menu-write-file (buffer)
  (with-current-buffer buffer
    (write-file (read-file-name
     (format "Write %s to file: "
       (buffer-name (current-buffer)))))))

;;; EXAMPLE -- NOT COMPLEX:
;;;  '([(*Messages*  *% lambda nil (interactive) (funcall menu-bar-select-buffer-function *Messages*))
;;;     (*scratch*  *% lambda nil (interactive) (funcall menu-bar-select-buffer-function *scratch*))])
;;;
;;; EXAMPLE -- COMPLEX:
;;;   '((%_1  *Messages*
;;;         menu-item
;;;         %_1  *Messages* (keymap
;;;       (unique-identifier-one
;;;         menu-item
;;;         Switch to *Messages*.
;;;         (lambda nil (interactive) (funcall buffers-menu-switch-to-buffer-function *Messages*))
;;;         :help Switch to *Messages*.)
;;;       (unique-identifier-two
;;;         menu-item
;;;         Switch to *Messages*, other frame.
;;;         (lambda nil (interactive) (funcall (quote switch-to-buffer-other-frame) *Messages*))
;;;         :help Switch to *Messages*, other frame.)))
;;;     (%_2  *scratch*
;;;         menu-item
;;;         %_2  *scratch* (keymap (unique-identifier-one
;;;         menu-item
;;;         Switch to *scratch*.
;;;         (lambda nil (interactive) (funcall buffers-menu-switch-to-buffer-function *scratch*))
;;;         :help Switch to *scratch*.)
;;;       (unique-identifier-two
;;;         menu-item
;;;         Switch to *scratch*, other frame.
;;;         (lambda nil (interactive) (funcall (quote switch-to-buffer-other-frame) *scratch*))
;;;         :help Switch to *scratch*, other frame.))))
;;;
(defsubst build-buffers-menu-internal (buffers)
  (let* ((n 0)
         (separator 0)
         line
         (lst
           (mapcar
             (lambda (buffer)
               (cond
                 ((eq buffer t)
                   (if complex-buffers-menu-p
                     (progn
                       ;;; The CAR of the separator must be unique.
                       (incf separator)
                       `(,separator "--"))
                     '("--")))
                 (t
                   (setq n (1+ n))
                   (setq line (funcall buffers-menu-format-buffer-line-function buffer n))
                   (if complex-buffers-menu-p
                     `(,line menu-item ,line
                       ,(cons 'keymap
                              (delq nil (list
                                (list
                                  'unique-identifier-one
                                  'menu-item
                                  (format "Switch to %s." buffer)
                                  `(lambda ()
                                    (interactive)
                                      (funcall buffers-menu-switch-to-buffer-function ,(buffer-name buffer)))
                                  :help (format "Switch to %s." buffer))
                                (if (eq buffers-menu-switch-to-buffer-function 'switch-to-buffer)
                                  (list
                                    'unique-identifier-two
                                    'menu-item
                                    (format "Switch to %s, other frame." buffer)
                                    `(lambda ()
                                      (interactive)
                                        (funcall 'switch-to-buffer-other-frame ,(buffer-name buffer)))
                                    :help (format "Switch to %s, other frame." buffer))
                                  nil)
                                (if (and (buffer-modified-p buffer)
                                         (buffer-file-name buffer))
                                  (list
                                    'unique-identifier-three
                                    'menu-item
                                    (format "Save %s" buffer)
                                    `(lambda ()
                                      (interactive)
                                        (funcall 'buffer-menu-save-buffer ,(buffer-name buffer)))
                                    :help (format "Save %s" buffer))
                                  nil)
                                (list
                                  'unique-identifier-four
                                  'menu-item
                                  (format "Save %s As..." buffer)
                                  `(lambda ()
                                    (interactive)
                                      (funcall 'buffer-menu-write-file ,(buffer-name buffer)))
                                  :help (format "Save %s As..." buffer))
                                (list
                                  'unique-identifier-five
                                  'menu-item
                                  (format "Kill %s." buffer)
                                  `(lambda ()
                                    (interactive)
                                      (funcall 'kill-buffer ,(buffer-name buffer)))
                                  :help (format "Kill %s." buffer))))))
                      (cons line
                            `(lambda ()
                              (interactive)
                                (funcall buffers-menu-switch-to-buffer-function ,(buffer-name buffer))))))))
           buffers)))
    (if complex-buffers-menu-p
      lst
      (let ((buffers-vec (make-vector (length lst) nil))
            (i (length lst)))
        (dolist (elt (nreverse lst))
          (setq i (1- i))
          (aset buffers-vec i elt))
        (list buffers-vec)))))

(defun buffers-menu-omit-invisible-buffers (buf)
  "For use as a value of `buffers-menu-omit-function'.
Omits normally invisible buffers (those whose name begins with a space)."
  (not (null (string-match "\\` " (buffer-name buf)))))

(defun group-buffers-menu-by-mode-then-alphabetically (buf1 buf2)
  "For use as a value of `buffers-menu-grouping-function'.
This groups buffers by major mode.  It only really makes sense if
`buffers-menu-sorting-function' is
`sort-buffers-menu-by-mode-then-alphabetically'."
  (cond ((string-match "\\`*" (buffer-name buf1))
   (and (null buf2) "*Misc*"))
  ((or (null buf2)
       (string-match "\\`*" (buffer-name buf2))
       (not (eq (with-current-buffer buf1
                  major-mode)
                (with-current-buffer buf2
                  major-mode))))
   (with-current-buffer buf1
     major-mode))
  (t nil)))

(defun sort-buffers-menu-alphabetically (buf1 buf2)
  "For use as a value of `buffers-menu-sort-function'.
Sorts the buffers in alphabetical order by name, but puts buffers beginning
with a star at the end of the list."
  (let* ((nam1 (buffer-name buf1))
   (nam2 (buffer-name buf2))
   (inv1p (not (null (string-match "\\` " nam1))))
   (inv2p (not (null (string-match "\\` " nam2))))
   (star1p (not (null (string-match "\\`*" nam1))))
   (star2p (not (null (string-match "\\`*" nam2)))))
    (cond ((not (eq inv1p inv2p))
     (not inv1p))
    ((not (eq star1p star2p))
     (not star1p))
    (t
     (string-lessp nam1 nam2)))))

(defun sort-buffers-menu-by-mode-then-alphabetically (buf1 buf2)
  "For use as a value of `buffers-menu-sort-function'.
Sorts first by major mode and then alphabetically by name, but puts buffers
beginning with a star at the end of the list."
  (let* ((nam1 (buffer-name buf1))
         (nam2 (buffer-name buf2))
         (inv1p (not (null (string-match "\\` " nam1))))
         (inv2p (not (null (string-match "\\` " nam2))))
         (star1p (not (null (string-match "\\`*" nam1))))
         (star2p (not (null (string-match "\\`*" nam2))))
         (mode1 (with-current-buffer buf1
                  major-mode))
         (mode2 (with-current-buffer buf2
                  major-mode)))
    (cond ((not (eq inv1p inv2p))
     (not inv1p))
    ((not (eq star1p star2p))
     (not star1p))
    ((and star1p star2p (string-lessp nam1 nam2)))
    ((string-lessp mode1 mode2)
     t)
    ((string-lessp mode2 mode1)
     nil)
    (t
     (string-lessp nam1 nam2)))))

(defun menu-item-generate-accelerator-spec (buffer n &optional omit-chars-list)
  "Return an accelerator specification for use with auto-generated menus.
This should be concat'd onto the beginning of each menu line.  The spec
allows the Nth line to be selected by the number N.  '0' is used for the
10th line, and 'a' through 'z' are used for the following 26 lines.
-  If OMIT-CHARS-LIST is given, it should be a list of lowercase characters,
which will not be used as accelerators."
  (let ((read-only (if (with-current-buffer buffer
                         buffer-read-only)
                     buffers-menu-read-only-string
                     buffers-menu-read-write-string)))
    (cond
      ((< n 10) (concat read-only "_" (int-to-string n) " "))
      ((= n 10) (concat read-only "_0 "))
      ((<= n 36)
       (setq n (- n 10))
       (let ((m 0))
         (while (> n 0)
           (setq m (1+ m))
           (while (memq (+ m (- ?a 1)) omit-chars-list)
             (setq m (1+ m)))
           (setq n (1- n)))
         (if (<= m 26)
           (concat
             read-only
             "_"
             (char-to-string (+ m (- ?a 1)))
             " ")
           "")))
      (t ""))))

;; this version is too slow on some machines.
;; (vintage 1990, that is)
(defun slow-format-buffers-menu-line (buffer n)
  "For use as a value of `buffers-menu-format-buffer-line-function'.
This returns a string containing a bunch of info about the buffer."
  (concat (menu-item-generate-accelerator-spec n buffers-menu-omit-chars-list)
    (format "%s%s %-19s %6s %-15s %s"
      (if (buffer-modified-p buffer) "*" " ")
      (if (with-current-buffer buffer
            buffer-read-only)
        buffers-menu-read-only-string
        buffers-menu-read-write-string)
      (buffer-name buffer)
      (buffer-size buffer)
      (with-current-buffer buffer
        major-mode)
      (or (buffer-file-name buffer) ""))))

(defun format-buffers-menu-line (buffer n)
  "For use as a value of `buffers-menu-format-buffer-line-function'.
This just returns the buffer's name."
  (concat (menu-item-generate-accelerator-spec buffer n buffers-menu-omit-chars-list)
          " "
          (buffer-name buffer)))

(defun menu-bar-update-buffers-2 ()
  "This is the menu filter for the top-level buffers \"Buffers\" menu.
It dynamically creates a list of buffers to use as the contents of the menu.
Only the most-recently-used few buffers will be listed on the menu, for
efficiency reasons.  You can control how many buffers will be shown by
setting `buffers-menu-max-size'.  You can control the text of the menu
items by redefining the function `format-buffers-menu-line'."
  (let ((buffers (delete-if buffers-menu-omit-function (buffer-list))))
    (and (integerp buffers-menu-max-size)
         (> buffers-menu-max-size 1)
         (> (length buffers) buffers-menu-max-size)
         ;; shorten list of buffers (not with submenus!)
         (not (and buffers-menu-grouping-function
                   buffers-menu-submenus-for-groups-p))
         (setcdr (nthcdr buffers-menu-max-size buffers) nil))
    (if buffers-menu-sort-function
      (setq buffers (sort buffers buffers-menu-sort-function)))
    (if (and buffers-menu-grouping-function
             buffers-menu-submenus-for-groups-p
             (or (not (integerp buffers-menu-submenus-for-groups-p))
                 (> (length buffers) buffers-menu-submenus-for-groups-p)))
      (let (groups groupnames current-group)
        (mapl
          (lambda (sublist)
            (let ((groupname (funcall buffers-menu-grouping-function
                                      (car sublist) (cadr sublist))))
              (setq current-group (cons (car sublist) current-group))
              (if groupname
                  (progn
                    (setq groups (cons (nreverse current-group)
                     groups))
                    (setq groupnames (cons groupname groupnames))
                    (setq current-group nil)))))
          buffers)
        (setq buffers
                (mapcar*
                  (lambda (groupname group)
                    `(,groupname menu-item ,(format "%s" groupname)
                      ,(cons 'keymap
                        (build-buffers-menu-internal group))))
                  (nreverse groupnames)
                  (nreverse groups))))
      (if buffers-menu-grouping-function
        (progn
          (setq buffers
                  (mapcon
                    (lambda (sublist)
                      (cond
                        ((funcall buffers-menu-grouping-function
                                  (car sublist) (cadr sublist))
                          (list (car sublist) t))
                        (t (list (car sublist)))))
                    buffers))
          ;; remove a trailing separator.
          (and (>= (length buffers) 2)
               (let ((lastcdr (nthcdr (- (length buffers) 2) buffers)))
                 (if (eq t (cadr lastcdr))
                   (setcdr lastcdr nil))))))
      (setq buffers (build-buffers-menu-internal buffers)))
    buffers))

(defun menu-bar-update-buffers (&optional force)
  ;; If user discards the Buffers item, play along.
  (and (lookup-key (current-global-map) [menu-bar buffer])
       (or force (frame-or-buffer-changed-p))
       (let ((buffers (buffer-list))
             (frames (frame-list))
             custom-entries
             buffers-menu)
   (if buffers-menu-xemacs-style
     (progn
       (setq custom-entries
         (list (list 'list-buffers
                     'menu-item
                     "List All Buffers"
                     'list-buffers
                     :help "Call the function `list-buffers'.")
               (list 'kill-this-buffer
                     'menu-item
                     (format "Delete Current Buffer:  %s" (current-buffer))
                     'kill-this-buffer
                     :help "Call the function `kill-this-buffer'.")
               '(separator-one "--")))
       (setq buffers-menu (nconc custom-entries (menu-bar-update-buffers-2))))
     ;;; ELSE, use the plain old default way of handling the buffers menu.
     ;;;
     ;; Make the menu of buffers proper.
     (setq buffers-menu
                 (let ((i 0)
                       (limit (if (and (integerp buffers-menu-max-size)
                                       (> buffers-menu-max-size 1))
                                  buffers-menu-max-size most-positive-fixnum))
                       alist)
       ;; Put into each element of buffer-list
       ;; the name for actual display,
       ;; perhaps truncated in the middle.
                   (while buffers
                     (let* ((buf (pop buffers))
                            (name (buffer-name buf)))
                       (unless (eq ?\s (aref name 0))
                         (push (menu-bar-update-buffers-1
                                (cons buf
              (if (and (integerp buffers-menu-buffer-name-length)
                 (> (length name) buffers-menu-buffer-name-length))
            (concat
             (substring
              name 0 (/ buffers-menu-buffer-name-length 2))
             "..."
             (substring
              name (- (/ buffers-menu-buffer-name-length 2))))
                name)))
                               alist)
                         ;; If requested, list only the N most recently
                         ;; selected buffers.
                         (when (= limit (setq i (1+ i)))
                           (setq buffers nil)))))
       (list (menu-bar-buffer-vector alist)))))
   ;; Make a Frames menu if we have more than one frame.
   (when (cdr frames)
     (let* ((frames-vec (make-vector (length frames) nil))
                  (frames-menu
                   (cons 'keymap
                         (list "Select Frame" frames-vec)))
                  (i 0))
             (dolist (frame frames)
               (aset frames-vec i
                     (cons
                      (frame-parameter frame 'name)
                      `(lambda ()
                         (interactive) (menu-bar-select-frame ,frame))))
               (setq i (1+ i)))
       ;; Put it after the normal buffers
       (setq buffers-menu
             (nconc buffers-menu
              `((frames-separator "--")
                (frames menu-item "Frames" ,frames-menu))))))
   ;; Add in some normal commands at the end of the menu.  We use
   ;; the copy cached in `menu-bar-buffers-menu-command-entries'
   ;; if it's been set already.  Note that we can't use constant
   ;; lists for the menu-entries, because the low-level menu-code
   ;; modifies them.
   (when (or force (null menu-bar-buffers-menu-command-entries))
     (setq menu-bar-buffers-menu-command-entries
             (delq nil
                (list
                  '(command-separator "--")
                  (list 'next-buffer
                        'menu-item
                        "Next Buffer"
                        'next-buffer
                        :help "Switch to the \"next\" buffer in a cyclic order")
                  (list 'previous-buffer
                        'menu-item
                        "Previous Buffer"
                        'previous-buffer
                        :help "Switch to the \"previous\" buffer in a cyclic order")
                  (list 'select-named-buffer
                        'menu-item
                        "Select Named Buffer..."
                        'switch-to-buffer
                        :help "Prompt for a buffer name, and select that buffer in the current window")
                  (if (null buffers-menu-xemacs-style)
                    (list 'list-all-buffers
                          'menu-item
                          "List All Buffers"
                          'list-buffers
                          :help "Pop up a window listing all Emacs buffers")
                    nil)))))
   (setq buffers-menu
         (nconc buffers-menu menu-bar-buffers-menu-command-entries))
         ;; We used to "(define-key (current-global-map) [menu-bar buffer]"
         ;; but that did not do the right thing when the [menu-bar buffer]
         ;; entry above had been moved (e.g. to a parent keymap).
   (setcdr global-buffers-menu-map (cons "Buffers" buffers-menu)))))

(menu-bar-update-buffers 'force)

(provide 'buffer-menu)