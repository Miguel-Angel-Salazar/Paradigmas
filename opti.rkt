#lang racket

(struct servicio (codigo cliente horas valor-hora estado)
  #:transparent)

(define (leer-texto mensaje)
  (display mensaje)
  (read-line))

(define (leer-numero mensaje)
  (display mensaje)
  (string->number (read-line)))

(define (registrar-servicio)
  (servicio
   (leer-numero "Código del servicio: ")
   (leer-texto "Nombre del cliente: ")
   (leer-numero "Horas trabajadas: ")
   (leer-numero "Valor de la hora: ")
   (leer-texto "Estado (Abierto/Cerrado): ")))

(define (registrar-servicios cantidad)
  (if (<= cantidad 0)
      '()
      (cons (registrar-servicio)
            (registrar-servicios (- cantidad 1)))))

(define (servicio-cerrado? s)
  (string-ci=? (servicio-estado s) "Cerrado"))

(define (subtotal-servicio s)
  (* (servicio-horas s)
     (servicio-valor-hora s)))

(define (porcentaje-descuento s)
  (if (>= (subtotal-servicio s) 300000)
      0.08
      0))

(define (descuento-servicio s)
  (* (subtotal-servicio s)
     (porcentaje-descuento s)))

(define (total-servicio s)
  (- (subtotal-servicio s)
     (descuento-servicio s)))

(define (servicios-cerrados servicios)
  (filter servicio-cerrado? servicios))

(define (total-facturado servicios)
  (foldl + 0 (map total-servicio (servicios-cerrados servicios))))

(define (ordenar-por-total servicios)
  (sort servicios
        (lambda (a b)
          (> (total-servicio a)
             (total-servicio b)))))

(define (mostrar-servicio s)
  (printf "\nCódigo: ~a\n" (servicio-codigo s))
  (printf "Cliente: ~a\n" (servicio-cliente s))
  (printf "Horas trabajadas: ~a\n" (servicio-horas s))
  (printf "Subtotal: $~a\n" (subtotal-servicio s))
  (printf "Descuento: $~a\n" (descuento-servicio s))
  (printf "Total: $~a\n" (total-servicio s)))

(display "Cantidad de servicios a registrar: ")
(define cantidad (string->number (read-line)))

(define servicios (registrar-servicios cantidad))
(define cerrados (servicios-cerrados servicios))
(define ordenados (ordenar-por-total cerrados))

(displayln "\nSERVICIOS CERRADOS")
(for-each mostrar-servicio ordenados)

(printf "\nTotal general facturado: $~a\n" (total-facturado servicios))

(if (null? ordenados)
    (displayln "No existen servicios cerrados.")
    (begin
      (displayln "\nSERVICIO DE MAYOR VALOR")
      (mostrar-servicio (first ordenados))))
