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


## Sample Configuration

```lisp
(global-set-key (kbd "C-x v s") 'smeargle)

;; Updating after save buffer
(add-hook 'after-save-hook 'smeargle)
```
