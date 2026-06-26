(define-library (c0c lexer)
  (import (scheme base) (scheme char) (scheme write) (srfi 69))
  (export make-lexer lexer-next lexer-peek
          tok-tag tok-val tok-line tok-col)
  (begin

    (define (tok-tag t) (list-ref t 0))
    (define (tok-val t) (list-ref t 1))
    (define (tok-line t) (list-ref t 2))
    (define (tok-col t) (list-ref t 3))

    (define keyword-table
      (let ((ht (make-hash-table string=? string-hash)))
        (for-each
          (lambda (pair)
            (hash-table-set! ht (car pair) (cdr pair)))
          '(("int" . kw-int) ("bool" . kw-bool) ("char" . kw-char)
            ("string" . kw-string) ("void" . kw-void)
            ("struct" . kw-struct) ("typedef" . kw-typedef)
            ("if" . kw-if) ("else" . kw-else)
            ("while" . kw-while) ("for" . kw-for)
            ("return" . kw-return) ("break" . kw-break)
            ("continue" . kw-continue)
            ("true" . kw-true) ("false" . kw-false)
            ("NULL" . kw-NULL)
            ("alloc" . kw-alloc) ("alloc_array" . kw-alloc-array)))
        ht))

    (define (make-lexer port filename)
      (let ((line 1) (col 0) (peeked #f))

        (define (peek) (peek-char port))

        (define (advance!)
          (let ((ch (read-char port)))
            (cond
              ((eof-object? ch) ch)
              ((char=? ch #\newline)
               (set! line (+ line 1))
               (set! col 0)
               ch)
              (else
               (set! col (+ col 1))
               ch))))

        (define (make-tok tag val ln cl) (list tag val ln cl))

        (define (scan-ident first-ch start-ln start-col)
          (let loop ((chars (list first-ch)))
            (let ((ch (peek)))
              (if (and (not (eof-object? ch))
                       (or (char-alphabetic? ch)
                           (char-numeric? ch)
                           (char=? ch #\_)))
                  (begin (advance!) (loop (cons ch chars)))
                  (let ((name (list->string (reverse chars))))
                    (if (hash-table-exists? keyword-table name)
                        (make-tok (hash-table-ref keyword-table name)
                                  #f start-ln start-col)
                        (make-tok 'ident name start-ln start-col)))))))

        (define (scan-number first-ch start-ln start-col)
          (if (and (char=? first-ch #\0)
                   (not (eof-object? (peek)))
                   (or (char=? (peek) #\x) (char=? (peek) #\X)))
              (begin
                (advance!)
                (let loop ((chars '()))
                  (let ((ch (peek)))
                    (if (and (not (eof-object? ch))
                             (or (char-numeric? ch)
                                 (and (char>=? ch #\a) (char<=? ch #\f))
                                 (and (char>=? ch #\A) (char<=? ch #\F))))
                        (begin (advance!) (loop (cons ch chars)))
                        (let ((hex-str (list->string (reverse chars))))
                          (if (= (string-length hex-str) 0)
                              (error "c0c: expected hex digits after 0x"
                                     filename start-ln start-col)
                              (make-tok 'int-lit
                                        (string->number hex-str 16)
                                        start-ln start-col)))))))
              (if (and (char=? first-ch #\0)
                       (not (eof-object? (peek)))
                       (char-numeric? (peek)))
                  (error "c0c: leading zeros in decimal literal"
                         filename start-ln start-col)
                  (let loop ((chars (list first-ch)))
                    (let ((ch (peek)))
                      (if (and (not (eof-object? ch)) (char-numeric? ch))
                          (begin (advance!) (loop (cons ch chars)))
                          (make-tok 'int-lit
                                    (string->number
                                      (list->string (reverse chars)))
                                    start-ln start-col)))))))

        (define (scan-escape)
          (let ((ch (advance!)))
            (cond
              ((eof-object? ch) (error "c0c: unexpected EOF in escape"))
              ((char=? ch #\n) #\newline)
              ((char=? ch #\t) #\tab)
              ((char=? ch #\r) #\return)
              ((char=? ch #\0) #\null)
              ((char=? ch #\\) #\\)
              ((char=? ch #\') #\')
              ((char=? ch #\") #\")
              ((char=? ch #\b) (integer->char 8))
              ((char=? ch #\v) (integer->char 11))
              ((char=? ch #\f) (integer->char 12))
              ((char=? ch #\a) (integer->char 7))
              ((char=? ch #\?) #\?)
              (else (error "c0c: unknown escape" ch)))))

        (define (scan-string start-ln start-col)
          (let loop ((chars '()))
            (let ((ch (advance!)))
              (cond
                ((eof-object? ch)
                 (error "c0c: unterminated string" filename start-ln))
                ((char=? ch #\")
                 (make-tok 'string-lit
                           (list->string (reverse chars))
                           start-ln start-col))
                ((char=? ch #\\)
                 (loop (cons (scan-escape) chars)))
                (else
                 (loop (cons ch chars)))))))

        (define (scan-char-lit start-ln start-col)
          (let* ((ch (advance!))
                 (val (if (and (not (eof-object? ch)) (char=? ch #\\))
                          (scan-escape)
                          ch))
                 (close (advance!)))
            (when (or (eof-object? close) (not (char=? close #\')))
              (error "c0c: unterminated character literal"
                     filename start-ln))
            (make-tok 'char-lit val start-ln start-col)))

        (define (skip-line-comment start-ln start-col)
          (let ((ch (peek)))
            (if (and (not (eof-object? ch)) (char=? ch #\@))
                (begin (advance!) (scan-annotation start-ln start-col))
                (let loop ()
                  (let ((ch (peek)))
                    (unless (or (eof-object? ch) (char=? ch #\newline))
                      (advance!) (loop)))
                  #f))))

        (define (scan-annotation start-ln start-col)
          (let loop ((chars '()))
            (let ((ch (peek)))
              (if (and (not (eof-object? ch))
                       (or (char-alphabetic? ch) (char=? ch #\_)))
                  (begin (advance!) (loop (cons ch chars)))
                  (let ((kw (list->string (reverse chars))))
                    (cond
                      ((string=? kw "assert")
                       (make-tok 'anno-assert #f start-ln start-col))
                      ((string=? kw "requires")
                       (make-tok 'anno-requires #f start-ln start-col))
                      ((string=? kw "ensures")
                       (make-tok 'anno-ensures #f start-ln start-col))
                      ((string=? kw "loop_invariant")
                       (make-tok 'anno-loop-invariant #f
                                 start-ln start-col))
                      (else
                       (let loop ()
                         (let ((ch (peek)))
                           (unless (or (eof-object? ch)
                                       (char=? ch #\newline))
                             (advance!) (loop)))
                         #f))))))))

        (define (skip-block-comment start-ln start-col)
          (let loop ()
            (let ((ch (advance!)))
              (cond
                ((eof-object? ch)
                 (error "c0c: unterminated block comment"
                        filename start-ln))
                ((and (char=? ch #\*)
                      (not (eof-object? (peek)))
                      (char=? (peek) #\/))
                 (advance!))
                (else (loop))))))

        (define (scan-token)
          (let loop ()
            (let ((ch (advance!)))
              (cond
                ((eof-object? ch)
                 (make-tok 'eof #f line col))

                ((char-whitespace? ch) (loop))

                ((or (char-alphabetic? ch) (char=? ch #\_))
                 (scan-ident ch line col))

                ((char-numeric? ch)
                 (scan-number ch line col))

                ((char=? ch #\")
                 (scan-string line col))

                ((char=? ch #\')
                 (scan-char-lit line col))

                ((char=? ch #\()
                 (make-tok 'lparen #f line col))
                ((char=? ch #\))
                 (make-tok 'rparen #f line col))
                ((char=? ch #\[)
                 (make-tok 'lbracket #f line col))
                ((char=? ch #\])
                 (make-tok 'rbracket #f line col))
                ((char=? ch #\{)
                 (make-tok 'lbrace #f line col))
                ((char=? ch #\})
                 (make-tok 'rbrace #f line col))
                ((char=? ch #\;)
                 (make-tok 'semi #f line col))
                ((char=? ch #\,)
                 (make-tok 'comma #f line col))

                ((char=? ch #\+)
                 (let ((nxt (peek)))
                   (cond
                     ((and (not (eof-object? nxt)) (char=? nxt #\+))
                      (advance!) (make-tok 'op-plus-plus #f line col))
                     ((and (not (eof-object? nxt)) (char=? nxt #\=))
                      (advance!) (make-tok 'op-plus-eq #f line col))
                     (else (make-tok 'op-plus #f line col)))))

                ((char=? ch #\-)
                 (let ((nxt (peek)))
                   (cond
                     ((and (not (eof-object? nxt)) (char=? nxt #\-))
                      (advance!) (make-tok 'op-minus-minus #f line col))
                     ((and (not (eof-object? nxt)) (char=? nxt #\=))
                      (advance!) (make-tok 'op-minus-eq #f line col))
                     ((and (not (eof-object? nxt)) (char=? nxt #\>))
                      (advance!) (make-tok 'op-arrow #f line col))
                     (else (make-tok 'op-minus #f line col)))))

                ((char=? ch #\*)
                 (let ((nxt (peek)))
                   (if (and (not (eof-object? nxt)) (char=? nxt #\=))
                       (begin (advance!) (make-tok 'op-star-eq #f line col))
                       (make-tok 'op-star #f line col))))

                ((char=? ch #\/)
                 (let ((nxt (peek)))
                   (cond
                     ((and (not (eof-object? nxt)) (char=? nxt #\/))
                      (advance!)
                      (let ((anno (skip-line-comment line col)))
                        (if anno anno (loop))))
                     ((and (not (eof-object? nxt)) (char=? nxt #\*))
                      (advance!) (skip-block-comment line col) (loop))
                     ((and (not (eof-object? nxt)) (char=? nxt #\=))
                      (advance!) (make-tok 'op-slash-eq #f line col))
                     (else (make-tok 'op-slash #f line col)))))

                ((char=? ch #\%)
                 (let ((nxt (peek)))
                   (if (and (not (eof-object? nxt)) (char=? nxt #\=))
                       (begin (advance!) (make-tok 'op-percent-eq #f line col))
                       (make-tok 'op-percent #f line col))))

                ((char=? ch #\&)
                 (let ((nxt (peek)))
                   (cond
                     ((and (not (eof-object? nxt)) (char=? nxt #\&))
                      (advance!) (make-tok 'op-amp-amp #f line col))
                     ((and (not (eof-object? nxt)) (char=? nxt #\=))
                      (advance!) (make-tok 'op-amp-eq #f line col))
                     (else (make-tok 'op-amp #f line col)))))

                ((char=? ch #\|)
                 (let ((nxt (peek)))
                   (cond
                     ((and (not (eof-object? nxt)) (char=? nxt #\|))
                      (advance!) (make-tok 'op-pipe-pipe #f line col))
                     ((and (not (eof-object? nxt)) (char=? nxt #\=))
                      (advance!) (make-tok 'op-pipe-eq #f line col))
                     (else (make-tok 'op-pipe #f line col)))))

                ((char=? ch #\^)
                 (let ((nxt (peek)))
                   (if (and (not (eof-object? nxt)) (char=? nxt #\=))
                       (begin (advance!) (make-tok 'op-caret-eq #f line col))
                       (make-tok 'op-caret #f line col))))

                ((char=? ch #\~)
                 (make-tok 'op-tilde #f line col))

                ((char=? ch #\!)
                 (let ((nxt (peek)))
                   (if (and (not (eof-object? nxt)) (char=? nxt #\=))
                       (begin (advance!) (make-tok 'op-ne #f line col))
                       (make-tok 'op-bang #f line col))))

                ((char=? ch #\=)
                 (let ((nxt (peek)))
                   (cond
                     ((and (not (eof-object? nxt)) (char=? nxt #\=))
                      (advance!) (make-tok 'op-eq-eq #f line col))
                     ((and (not (eof-object? nxt)) (char=? nxt #\>))
                      (advance!) (make-tok 'op-implies #f line col))
                     (else (make-tok 'op-assign #f line col)))))

                ((char=? ch #\<)
                 (let ((nxt (peek)))
                   (cond
                     ((and (not (eof-object? nxt)) (char=? nxt #\<))
                      (advance!)
                      (let ((nxt2 (peek)))
                        (if (and (not (eof-object? nxt2)) (char=? nxt2 #\=))
                            (begin (advance!)
                                   (make-tok 'op-lshift-eq #f line col))
                            (make-tok 'op-lshift #f line col))))
                     ((and (not (eof-object? nxt)) (char=? nxt #\=))
                      (advance!) (make-tok 'op-le #f line col))
                     (else (make-tok 'op-lt #f line col)))))

                ((char=? ch #\>)
                 (let ((nxt (peek)))
                   (cond
                     ((and (not (eof-object? nxt)) (char=? nxt #\>))
                      (advance!)
                      (let ((nxt2 (peek)))
                        (if (and (not (eof-object? nxt2)) (char=? nxt2 #\=))
                            (begin (advance!)
                                   (make-tok 'op-rshift-eq #f line col))
                            (make-tok 'op-rshift #f line col))))
                     ((and (not (eof-object? nxt)) (char=? nxt #\=))
                      (advance!) (make-tok 'op-ge #f line col))
                     (else (make-tok 'op-gt #f line col)))))

                ((char=? ch #\?)
                 (make-tok 'op-question #f line col))
                ((char=? ch #\:)
                 (make-tok 'op-colon #f line col))
                ((char=? ch #\.)
                 (make-tok 'op-dot #f line col))

                ((char=? ch #\#)
                 (let ((start-ln line) (start-col col))
                   (let kw-loop ((chars '()))
                     (let ((c (peek)))
                       (if (and (not (eof-object? c)) (char-alphabetic? c))
                           (begin (advance!) (kw-loop (cons c chars)))
                           (let ((kw (list->string (reverse chars))))
                             (unless (string=? kw "use")
                               (error "c0c: unknown directive"
                                      kw filename start-ln start-col))
                             (let ws ()
                               (when (and (not (eof-object? (peek)))
                                          (char-whitespace? (peek))
                                          (not (char=? (peek) #\newline)))
                                 (advance!) (ws)))
                             (let ((open (advance!)))
                               (unless (and (not (eof-object? open))
                                            (char=? open #\<))
                                 (error "c0c: expected < after #use"
                                        filename start-ln start-col))
                               (let lib-loop ((chars '()))
                                 (let ((c (advance!)))
                                   (cond
                                     ((or (eof-object? c) (char=? c #\newline))
                                      (error "c0c: unterminated #use directive"
                                             filename start-ln start-col))
                                     ((char=? c #\>)
                                      (make-tok 'use-lib
                                                (list->string (reverse chars))
                                                start-ln start-col))
                                     (else
                                      (lib-loop (cons c chars)))))))))))))

                ((char=? ch #\\)
                 (let lp ((cs '()))
                   (let ((c (peek)))
                     (if (and (not (eof-object? c)) (char-alphabetic? c))
                         (begin (advance!) (lp (cons c cs)))
                         (let ((w (list->string (reverse cs))))
                           (cond ((string=? w "result") (make-tok 'bs-result #f line col))
                                 ((string=? w "length") (make-tok 'bs-length #f line col))
                                 ((string=? w "old") (make-tok 'bs-old #f line col))
                                 (else (error "c0c: unknown \\keyword" w))))))))
                (else
                 (error "c0c: unexpected character"
                        ch filename line col))))))

        (define (peek-token)
          (unless peeked (set! peeked (scan-token)))
          peeked)

        (define (next-token)
          (if peeked
              (let ((t peeked)) (set! peeked #f) t)
              (scan-token)))

        (list next-token peek-token)))

    (define (lexer-next lex) ((car lex)))
    (define (lexer-peek lex) ((cadr lex)))))
