;;; app/twitter/config.el -*- lexical-binding: t; -*-

(def-package! twittering-mode
  :commands twit
  :init
  :config

  (defface twitter-divider
    `((t (:underline (:color ,(doom-blend 'vertical-bar 'bg 0.8)))))
    "test"
    :group 'twittering-mode)
  (defun twittering-make-fontified-tweet-text (str-expr regexp-hash regexp-atmark)
    (let ((regexp-str
           (mapconcat
            'identity
            (list
             ;; hashtag
             (concat regexp-hash "\\([[:alpha:]0-9_-]+\\)")
             ;; @USER/LIST
             (concat regexp-atmark
                     "\\(\\([a-zA-Z0-9_-]+\\)/\\([a-zA-Z0-9_-]+\\)\\)")
             ;; @USER
             (concat regexp-atmark "\\([a-zA-Z0-9_-]+\\)")
             ;; URI
             "\\(https?://[-_.!~*'()a-zA-Z0-9;/?:@&=+$,%#]+\\)")
            "\\|")))
      `(let ((pos 0)
             (str (copy-sequence ,str-expr)))
         (while (string-match ,regexp-str str pos)
           (let* ((beg (match-beginning 0))
                  (end (match-end 0))
                  (range-and-properties
                   (cond
                    ((get-text-property beg 'face str)
                     ;; The matched substring has been already fontified.
                     ;; The fontification with entities must fontify the
                     ;; head of the matched string.
                     nil)
                    ((match-string 1 str)
                     ;; hashtag
                     (let* ((hashtag (match-string 1 str))
                            (spec-string
                             (twittering-make-hashtag-timeline-spec-string-direct
                              hashtag))
                            (url (twittering-get-search-url
                                  (concat "#" hashtag))))
                       (list
                        beg end
                        'mouse-face 'highlight
                        'keymap twittering-mode-on-uri-map
                        'uri url
                        'goto-spec spec-string
                        'face 'twittering-username-face)))
                    ((match-string 2 str)
                     ;; @USER/LIST
                     (let ((owner (match-string 3 str))
                           (list-name (match-string 4 str))
                           ;; Properties are added to the matched part only.
                           ;; The prefixes `twittering-regexp-atmark' will not
                           ;; be highlighted.
                           (beg (match-beginning 2)))
                       (list
                        beg end
                        'mouse-face 'highlight
                        'keymap twittering-mode-on-uri-map
                        'uri (twittering-get-list-url owner list-name)
                        'goto-spec
                        (twittering-make-list-timeline-spec-direct owner
                                                                   list-name)
                        'face 'twittering-username-face)))
                    ((match-string 5 str)
                     ;; @USER
                     (let ((screen-name (match-string 5 str))
                           ;; Properties are added to the matched part only.
                           ;; The prefixes `twittering-regexp-atmark' will not
                           ;; be highlighted.
                           (beg (match-beginning 5)))
                       (list
                        beg end
                        'mouse-face 'highlight
                        'keymap twittering-mode-on-uri-map
                        'uri (twittering-get-status-url screen-name)
                        'screen-name-in-text screen-name
                        'goto-spec
                        (twittering-make-user-timeline-spec-direct screen-name)
                        'face 'twittering-uri-face)))
                    ((match-string 6 str)
                     ;; URI
                     (let ((uri (match-string 6 str)))
                       (list
                        beg end
                        'mouse-face 'highlight
                        'keymap twittering-mode-on-uri-map
                        'uri uri
                        'uri-origin 'explicit-uri-in-tweet
                        'face 'twittering-uri-face)))))
                  (beg (if range-and-properties
                           (car range-and-properties)
                         beg))
                  (end (if range-and-properties
                           (cadr range-and-properties)
                         end))
                  (properties
                   `(,@(cddr range-and-properties)
                     front-sticky nil
                     rear-nonsticky t)))
             (when range-and-properties
               (add-text-properties beg end properties str))
             (setq pos end)))
         (add-face-text-property 0 (length str) 'variable-pitch t str)
         str)))
  (setq twittering-use-master-password t
        twittering-private-info-file (expand-file-name "twittering-mode.gpg" doom-etc-dir)
        twittering-request-confirmation-on-posting t
        ;; twittering-icon-mode t
        ;; twittering-use-icon-storage t
        ;; twittering-icon-storage-file (concat doom-cache-dir "twittering-mode-icons.gz")
        ;; twittering-convert-fix-size 12
        twittering-connection-type-order '(wget curl urllib-http native urllib-https)
        twittering-timeline-header ""
        twittering-timeline-footer ""
        twittering-edit-skeleton 'inherit-any
        twittering-status-format "
%FACE[font-lock-function-name-face]{  @%s}  %FACE[italic]{%@}  %FACE[error]{%FIELD-IF-NONZERO[❤ %d]{favorite_count}}  %FACE[warning]{%FIELD-IF-NONZERO[↺ %d]{retweet_count}}

%FOLD[   ]{%FILL{%t}
%QT{
%FOLD[   ]{%FACE[font-lock-function-name-face]{@%s}\t%FACE[shadow]{%@}
%FOLD[ ]{%FILL{%t}}
}}}


%FACE[twitter-divider]{                                                                                                                                                                                  }
"
        twittering-timeline-spec-alias
        ;; '(("research" . "anshulkundaje+ChromatinHaiku+loops_enhancers+MarkGerstein+Gene_Regulation+Nucleosome_Bot+cohesin_papers+CTCF_Papers+TF_binding_bot+broadinstitute+eric_lander+manoliskellis"))
        '(("research" . ":search/from:anshulkundaje OR from:ChromatinHaiku OR from:loops_enhancers OR from:MarkGerstein OR from:Gene_Regulation OR from:Nucleosome_Bot OR from:cohesin_papers OR from:CTCF_Papers OR from:TF_binding_bot OR from:broadinstitute OR from:eric_lander OR from:manoliskellis/"))
        twittering-initial-timeline-spec-string
        '(
          ":home"
          "(#orgmode+#emacs)"
          "$research"))

  (def-hydra! +twitter@panel (:color pink :hint nil)
    "
 Tweets^^^^^^                                   User^^^^                Other^^
 ──────^^^^^^────────────────────────────────── ────^^^^─────────────── ─────^^───────────────────
 _j_/_k_ down/up        _r_ retweet         _d_^^ direct message  _a_ toggle auto-refresh
 _RET_^^ open or reply  _R_ retweet & edit  _f_^^ follow          _q_ quit
 _b_^^   heart          _n_ post new tweet  _F_^^ unfollow        _Q_ quit twitter
 _B_^^   unheart        _t_ show thread     _i_^^ profile         _u_ update
 _e_^^   edit mode      _X_ delete tweet    _J_/_K_ down/up       _/_ search
 _g_^^   first          _y_ yank url        ^^^^                  _I_ toggle images
 _G_^^   last           _Y_ yank tweet
 _o_^^   open url"
    ("?"          nil :exit t)
    ("RET"        twittering-enter :exit t)
    ("/"          twittering-search :exit t)
    ("a"          twittering-toggle-activate-buffer)
    ("b"          twittering-favorite)
    ("B"          twittering-unfavorite)
    ("d"          twittering-direct-message :exit t)
    ("e"          twittering-edit-mode :exit t)
    ("f"          twittering-follow)
    ("F"          twittering-unfollow)
    ("g"          beginning-of-buffer)
    ("G"          end-of-buffer)
    ("i"          twittering-view-user-page)
    ("q"          nil :exit t)
    ("Q"          twittering-kill-buffer :exit t)
    ("I"          twittering-icon-mode)
    ("j"          twittering-goto-next-status)
    ("J"          twittering-goto-next-status-of-user)
    ("k"          twittering-goto-previous-status)
    ("K"          twittering-goto-previous-status-of-user)
    ("n"          twittering-update-status-interactive :exit t)
    ("o"          twittering-click :exit t)
    ("r"          twittering-native-retweet :exit t)
    ("R"          twittering-organic-retweet :exit t)
    ("t"          twittering-toggle-or-retrieve-replied-statuses :exit t)
    ("u"          twittering-current-timeline)
    ("X"          twittering-delete-status)
    ("y"          twittering-push-uri-onto-kill-ring)
    ("Y"          twittering-push-tweet-onto-kill-ring))

  (add-hook! twittering-mode
    (setq header-line-format (or (doom-modeline 'twitter) mode-line-format)
          mode-line-format nil))

  (add-hook 'doom-real-buffer-functions #'+twitter-buffer-p)
  (when (featurep! :feature popup)
    (setq twittering-pop-to-buffer-function #'+twitter-display-buffer))

  (after! solaire-mode
    (add-hook 'twittering-mode-hook #'solaire-mode))

  (set! :popup "^\\*twittering-edit" nil '((transient) (quit) (select . t) (modeline . minimal)))
  (set! :evil-state 'twittering-mode 'normal)
  (map! :map twittering-mode-map
        [remap twittering-kill-buffer] #'+twitter/quit
        :n "q" #'+twitter/quit-all
        :n "f" #'twittering-visit-timeline
        :n "e" #'+twitter/rerender-all
        :n "o" #'ace-link-org
        :n "." #'+twitter@panel/body
        :n "h" #'evil-window-left
        :n "l" #'evil-window-right
        :n "j" #'twittering-goto-next-status
        :n "k" #'twittering-goto-previous-status)

  (def-modeline! twitter
    (bar matches " %b " selection-info)
    ()))
