# buffer-menu

A port of the Xemacs buffers menu-bar feature that works with Emacs 26.

DESCRIPTION:

The default setting of this library is a grouping of buffers by major-mode,
which appear in a drop-down menu from the menu-bar.  The function
`menu-bar-update-buffers-2` can also be used to generate the same menu in a
custom setup (assembly required), e.g., a mouse pop-up menu.  The variable
`buffers-menu-max-size` is defined in `menu-bar.el`, and this library uses it
also in the same manner.  As in the stock version, the symbol `%` indicates the
buffer is read-only.  Unlike the stock version, each buffer is numbered in
the menu to help the user see how many buffers of that menu/submenu exist
(within the buffer max limits, supra).

-  The variable setting of:  (setq buffers-menu-submenus-for-groups-p t)
   places the buffers of each major-mode into a submenu of buffers.

-  The variable setting of:  (setq complex-buffers-menu-p t)
   gives each buffer its own submenu of options:  save buffer (if modified),
   save buffer as, kill buffer, switch to buffer, switch to buffer other
   frame.  The user may set `buffers-menu-switch-to-buffer-function` to
   something other than `switch-to-buffer` if so desired.

F.A.Q. (Frequently Asked Questions):

**Q**:  How is this different from what `C-mouse-1` pops up?

**A**:  As to the built-in function `mouse-buffer-menu`, and a default setting of 4 for the variable `mouse-buffer-menu-mode-mult`, there is no obvious grouping of buffers by major-mode.  Setting a value of 1 or 2 for the variable `mouse-buffer-menu-mode-mult` causes buffers to be grouped by major-mode and the buffers are available in submenus of the major-modes.

Xemacs buffers-menu plugs-in to the menu-bar mechanism at the top of the screen. The default settings have no submenus, but nevertheless group buffers by major-mode and alphabetically within that major-mode.  Major-modes are not identified as such, but the buffers within each major-mode grouping are separated from other major-mode groups with a divider line.  When `buffers-menu-submenus-for-groups-p` is set to t, this is very similar to the built-in `mouse-buffer-menu` (when setting `mouse-buffer-menu-mode-mult` to a value of 1 or 0), except that the latter displays the path to file-visiting buffers.  When setting `complex-buffers-menu-p` to t, each buffer gets its own submenu of options:  `switch-to-buffer`, `switch-to-buffer-other-frame`, `save-buffer` (if modified), `write-file` of the current buffer which is referred to as Save As, and `kill-buffer`.  There is presently no comparable submenu options when using the built-in `mouse-buffer-menu`.

SETUP INSTRUCTIONS:

Let us assume that Emacs has created a folder called `.emacs.d` inside your HOME directory and we will refer to it as `~/.emacs.d`.  Now, let us suppose that we want to create a directory for beta testing Lisp libraries -- to that end, we will create the folder `beta-testing` inside the `~/.emacs.d` directory, and the path to that new directory that we just created will be `~/.emacs.d/beta-testing`.  We then place the file `buffer-menu.el` in the new directory we just created; i.e., `~/.emacs.d/beta-testing`.  The path to the file will now be `~/.emacs.d/beta-testing/buffer-menu.el`.  We must now add the new directory to our `load-path` by adding the following line to our `.emacs` or `init.el` file:  `(add-to-list 'load-path "~/.emacs.d/beta-testing/")`.  Somewhere after the line where we just added the folder `beta-testing` to our `load-path`, we can then put `(require 'buffer-menu)`.  There is no need to use a `.el` at the end.

SCREENSHOTS:

![buffer_menu_a.png](https://www.lawlist.com/images/buffer_menu_a.png)

![buffer_menu_b.png](https://www.lawlist.com/images/buffer_menu_b.png)

![buffer_menu_c.png](https://www.lawlist.com/images/buffer_menu_c.png)

![buffer_menu_d.png](https://www.lawlist.com/images/buffer_menu_d.png)