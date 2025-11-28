(setq org-latex-compiler "xelatex")

(setq org-latex-default-packages-alist
      '(("" "fontspec" t ("xelatex" "lualatex"))
        ("" "graphicx" t)
        ("" "longtable" nil)
        ("" "float" nil)
        ("" "wrapfig" nil)
        ("" "rotating" nil)
        ("normalem" "ulem" t)
        ("" "amsmath" t)
        ("" "amssymb" t)
        ("" "hyperref" nil)
        "\\tolerance=1000"))

(require 'rx)
(require 'ox-latex)
(require 'ox-beamer)
(require 'ob-diagrams)

(setq org-plantuml-jar-path
      (expand-file-name "lib/plantuml.jar"
                        (concat
                         (file-name-directory
                          (executable-find "plantuml"))
                         "/..")))
(setq org-ditaa-jar-path
      (expand-file-name "lib/ditaa.jar"
                        (concat
                         (file-name-directory
                          (executable-find "ditaa"))
                         "/..")))
(setq org-diagrams-executable "diagrams-builder-svg")

(org-babel-do-load-languages
 'org-babel-load-languages
 '((python     . t)
   (emacs-lisp . t)
   (haskell    . t)
   (calc       . t)
   (ditaa      . t)
   (plantuml   . t)
   (diagrams   . t)
   (sql        . t)
   (dot        . t)))

(setq org-beamer-frame-default-options "fragile")

;; Convert @text@ to \alert{text} for Beamer highlighting
(defun my/beamer-alert-filter (text backend info)
  "Convert @text@ to \\alert{text} in Beamer export."
  (when (org-export-derived-backend-p backend 'beamer)
    (replace-regexp-in-string "@\\([^@]+\\)@" "\\\\alert{\\1}" text)))

(add-to-list 'org-export-filter-plain-text-functions
             #'my/beamer-alert-filter)

(setq org-confirm-babel-evaluate nil)
(setq org-export-babel-evaluate t)

(setq org-latex-listings 'minted)

(setq org-latex-minted-options
      '(("fontsize" "\\footnotesize")
        ("linenos" "true")
        ("xleftmargin" "2em")
        ("breaklines" "true")))


(setq org-latex-pdf-process
      '("xelatex -shell-escape -interaction nonstopmode -output-directory %o %f"
        "xelatex -shell-escape -interaction nonstopmode -output-directory %o %f"
        "xelatex -shell-escape -interaction nonstopmode -output-directory %o %f"))

(setq org-export-latex-classes
      '(("beamer" "\\documentclass{beamer}" org-beamer-sectioning)))

(defun extract-code (name)
  "Where name has the form foo.bar.baz"
  (with-temp-buffer
    (insert-file-contents-literally "Main.hs")

    (let ((parts (split-string name "\\.")))
      (while parts
        (re-search-forward
         (rx-to-string `(: word-start ,(if (cdr parts) "describe" "it")
                           space ?\" ,(car parts) ?\")))
        (forward-line)
        (setq parts (cdr parts))))

    (let ((beg (point)))
      (forward-paragraph)
      (let ((str (buffer-substring-no-properties beg (point))))
        (with-temp-buffer
          (insert str)
          (goto-char (point-min))
          (let ((width (skip-chars-forward " ")))
            (goto-char (point-min))
            (while (not (eobp))
              (delete-char width)
              (forward-line)))
          (buffer-string))))))

(defun extract-code-blocks ()
  (goto-char (point-min))
  (while (re-search-forward "^### \\(.+\\)$" nil t)
    (let ((name (match-string 1))
          (line (line-number-at-pos (match-end 0))))
      (delete-region (match-beginning 0) (match-end 0))
      (insert "#+begin_src haskell" ?\n)
      (condition-case err
          (insert (extract-code name))
        (error
         (error "Failed to locate test for %s: %s" name err)))
      (insert "#+end_src"))))

(defun perform-extraction ()
  (find-file (car command-line-args-left))
  (extract-code-blocks)
  (org-beamer-export-to-latex))

(provide 'support)
