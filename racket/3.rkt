#lang racket

(display "ingrese el primer numero:")
(define numero1 (string->number (read-line)))

(display "ingrese el segundo numero:")
(define numero2 (string->number (read-line)))

(define suma (+ numero1 numero2))
(define resta (- numero1 numero2))
(define multiplicacion (* numero1 numero2))

(printf "\nSuma: ~a\n" suma)
(printf "Resta: ~a\n" resta)
(printf "multiplicacion: ~a\n" multiplicacion)

(if (= numero2 0)
    (displayln "Division: no se puede dividir por cero")
    (printf "Division: ~a\n" (/ numero1 numero2)))




