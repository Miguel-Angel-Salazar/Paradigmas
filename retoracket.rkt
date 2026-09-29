#lang racket

(define (vehiculo-valido? vehiculo)
	(or (string-ci=? vehiculo "bicicleta")
			(string-ci=? vehiculo "moto")
			(string-ci=? vehiculo "carro")))

(define (calcular-tarifa-base vehiculo)
	(cond
		[(string-ci=? vehiculo "bicicleta") 4000]
		[(string-ci=? vehiculo "moto") 6000]
		[(string-ci=? vehiculo "carro") 10000]
		[else 0]))

(define (calcular-km-adicionales distancia)
	(if (> distancia 5)
			(- distancia 5)
			0))

(define (calcular-costo-por-km vehiculo)
	(cond
		[(string-ci=? vehiculo "bicicleta") 800]
		[(string-ci=? vehiculo "moto") 1200]
		[(string-ci=? vehiculo "carro") 2000]
		[else 0]))

(define (calcular-costo-adicionales vehiculo kilometros-adicionales)
	(* kilometros-adicionales
		 (calcular-costo-por-km vehiculo)))

(define (calcular-recargo-horario subtotal hora)
	(cond
		[(< hora 20) 0]
		[(< hora 22) (* subtotal (/ 10 100))]
		[else (* subtotal (/ 20 100))]))

(define (calcular-descuento subtotal domicilios)
	(if (>= domicilios 10)
	(* subtotal (/ 5 100))
			0))

(define (calcular-total tarifa-base costo-adicionales recargo descuento)
	(- (+ tarifa-base costo-adicionales recargo)
		 descuento))

(display "Nombre del cliente: ")
(define nombre (read-line))

(display "Tipo de vehículo (bicicleta, moto o carro): ")
(define vehiculo (read-line))

(display "Distancia recorrida en kilómetros: ")
(define distancia (string->number (read-line)))

(display "Hora del servicio (0 a 23): ")
(define hora (string->number (read-line)))

(display "Domicilios realizados durante el mes: ")
(define domicilios (string->number (read-line)))

(define tarifa-base (calcular-tarifa-base vehiculo))
(define kilometros-adicionales (calcular-km-adicionales distancia))
(define costo-adicionales
  (calcular-costo-adicionales vehiculo kilometros-adicionales))
(define subtotal (+ tarifa-base costo-adicionales))
(define recargo (calcular-recargo-horario subtotal hora))
(define descuento
  (calcular-descuento (+ subtotal recargo) domicilios))
(define total
  (calcular-total tarifa-base costo-adicionales recargo descuento))

(printf "\n--- Liquidación del domicilio ---\n")
(printf "Cliente: ~a\n" nombre)
(printf "Vehículo: ~a\n" vehiculo)
(printf "Distancia recorrida: ~a km\n" distancia)
(printf "Tarifa base: $~a\n" tarifa-base)
(printf "Kilómetros adicionales: ~a km\n" kilometros-adicionales)
(printf "Costo por kilómetros adicionales: $~a\n" costo-adicionales)
(printf "Recargo por horario: $~a\n" recargo)
(printf "Descuento obtenido: $~a\n" descuento)
(printf "Total a pagar: $~a\n" total)
