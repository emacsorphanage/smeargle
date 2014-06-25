# smeargle.el

Highlighting regions by last updated time.
Older updated region is highlighted whity, newer region is highlighted blackly.

This is Emacs port of Vim's [smeargle](https://github.com/FriedSock/smeargle)

## Screenshot

![smeargle](image/smeargle.png)

## Support VCS

- [Git](http://git-scm.com/)
- [Mercurial](http://mercurial.selenic.com/)

## Command

#### `M-x smeargle`

Highlight regions


#### `M-x smeargle-clear`

Clear overlays in current buffer


## Customize

You can set highlighted colors by changing `smeargle-colors`.
For example

```lisp
(custom-set-variables
 '(smeargle-colors '((older-than-1day   . "red")
                     (older-than-3day   . "green")
                     (older-than-1week  . "yellow")
                     (older-than-2week  . nil)
                     (older-than-1month . "orange")
                     (older-than-3month . "pink")
                     (older-than-6month . "cyan")
                     (older-than-1year . "grey50"))))
```

If `color` parameter is `nil`, that part is not highlighted.


## Sample Configuration

```lisp
(global-set-key (kbd "C-x v s") 'smeargle)

;; Highlight regions at opening file
(add-hook 'find-file-hook 'smeargle)

;; Updating after save buffer
(add-hook 'after-save-hook 'smeargle)
```
