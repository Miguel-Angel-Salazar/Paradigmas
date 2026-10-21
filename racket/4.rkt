#lang racket
(display "Ingrese el nombre del estudiante: ")
(define nombre (read-line))

(display "Ingrese la nota definitiva: ")
(define nota (string->number (read-line)))

;Gente, cond sirve para varias decisiones, es mejor que un IF anidado.
(cond
  [(< nota 0)
   (displayln "Error: la nota no puede ser menor que 0.")]
  [(> nota 5)
   (displayln "Error: la nota no puede ser mayor que 5.")]
  [(< nota 3)
   (printf "~a reprobó la materia.\n" nombre)]

  [(< nota 4)
   (printf "~a aprobó la materia.\n" nombre)]

  [(<= nota 4.5)
   (printf "~a tuvo un rendimiento sobresaliente.\n" nombre)]

  [else
   (printf "~a tuvo un rendimiento excelente.\n" nombre)])
