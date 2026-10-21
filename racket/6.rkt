#lang racket
;Creamos una función que determina el descuento.
(define (calcular-descuento compra)

  (cond ;Dependiendo del valor retornamos un porcentaje.
    [(< compra 100000) 0]
    [(< compra 300000) 0.05]
    [(< compra 500000) 0.10]
    [else 0.15]))

(display "Ingrese el valor de la compra: $")
(define compra (string->number (read-line)))

; Llamamos la función que creamos arriba.
(define porcentaje
  (calcular-descuento compra))
;Se aplica el %.
(define descuento
  (* compra porcentaje))
(define total
  (- compra descuento))

(printf "\nValor compra: $~a\n" compra)
(printf "Descuento: $~a\n" descuento)
(printf "Total a pagar: $~a\n" total)
