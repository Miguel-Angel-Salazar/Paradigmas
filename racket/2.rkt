#lang racket
(display "ingrese el primer numero:")
(define numero1 (string -> number (read-line)))
(display "ingrese el segundo numero:")
(define numero2 (string -> number(read-line)))
(define suma (+ numero1 numero2))
(print "la suma de ~a +~a es: ~a\n"
        numero1
        numero2
        suma)