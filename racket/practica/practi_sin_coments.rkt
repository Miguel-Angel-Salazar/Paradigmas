#lang racket

(define tipos-cliente (list "Normal" "Frecuente" "Premium"))             
(define medios-pago   (list "Efectivo" "Tarjeta" "PSE" "Transferencia"))
(define tipos-envio   (list "Normal" "Express"))
(define estados-pago  (list "Aprobado" "Pendiente" "Rechazado"))

(define descuento-por-tipo                      
  (make-hash (list (cons "Normal"    0)        
                   (cons "Frecuente" 5/100)
                   (cons "Premium"   10/100))))

(define (leer-texto mensaje)
  (display mensaje)
  (read-line))

(define (leer-numero mensaje)
  (string->number (leer-texto mensaje)))

(define (leer-pedido)
  (displayln "\n--- Nuevo pedido ---")
  (list (list 'numero       (leer-numero "Número de pedido: "))
        (list 'cedula       (leer-texto  "Cédula del cliente: "))
        (list 'nombre       (leer-texto  "Nombre del cliente: "))
        (list 'ciudad       (leer-texto  "Ciudad: "))
        (list 'categoria    (leer-texto  "Categoría del producto: "))
        (list 'codigo       (leer-texto  "Código del producto: "))
        (list 'producto     (leer-texto  "Nombre del producto: "))
        (list 'cantidad     (leer-numero "Cantidad solicitada: "))
        (list 'precio       (leer-numero "Precio unitario: "))
        (list 'inventario   (leer-numero "Cantidad disponible en inventario: "))
        (list 'medio-pago   (leer-texto  "Medio de pago (Efectivo/Tarjeta/PSE/Transferencia): "))
        (list 'tipo-cliente (leer-texto  "Tipo de cliente (Normal/Frecuente/Premium): "))
        (list 'envio        (leer-texto  "Tipo de envío (Normal/Express): "))
        (list 'distancia    (leer-numero "Distancia del despacho en km: "))
        (list 'estado-pago  (leer-texto  "Estado del pago (Aprobado/Pendiente/Rechazado): "))))

(define (leer-pago)
  (displayln "\n--- Nuevo pago ---")
  (list (list 'numero (leer-numero "Número de pedido: "))
        (list 'valor  (leer-numero "Valor recibido por la empresa: "))))

(define (registrar cantidad leer-registro)
  (if (or (not (number? cantidad))
          (<= cantidad 0))
      '()
      (cons (leer-registro)
            (registrar (- cantidad 1) leer-registro))))

(define (dato registro campo)
  (second (assoc campo registro)))

(define (valor-final pedido)
  (dato pedido 'valor-final))

(define (sumar campo registros)
  (apply + (map (lambda (r) (dato r campo)) registros)))

(define (pesos valor)
  (round valor))

(define (valor-permitido? valor opciones)
  (if (member valor opciones) #t #f))

(define (pedido-valido? p)
  (and (number? (dato p 'numero))
       (> (dato p 'numero) 0)
       (not (string=? (dato p 'cedula) ""))
       (number? (dato p 'cantidad))
       (> (dato p 'cantidad) 0)
       (number? (dato p 'precio))
       (> (dato p 'precio) 0)
       (number? (dato p 'inventario))
       (>= (dato p 'inventario) 0)
       (number? (dato p 'distancia))
       (not (string=? (dato p 'categoria) ""))
       (valor-permitido? (dato p 'medio-pago)   medios-pago)
       (valor-permitido? (dato p 'tipo-cliente) tipos-cliente)
       (valor-permitido? (dato p 'envio)        tipos-envio)
       (valor-permitido? (dato p 'estado-pago)  estados-pago)))

(define (clave p)
  (list (dato p 'numero) (dato p 'codigo)))

(define (mismo-registro? a b)
  (equal? (clave a) (clave b)))

(define (copias-de p lista)
  (filter (lambda (otro) (mismo-registro? otro p)) lista))

(define (sin-copias-de p lista)
  (filter (lambda (otro) (not (mismo-registro? otro p))) lista))

(define (registros-unicos pedidos)
  (if (null? pedidos)
      '()
      (cons (car pedidos)
            (registros-unicos (sin-copias-de (car pedidos) (cdr pedidos))))))

(define (registros-repetidos pedidos)
  (if (null? pedidos)
      '()
      (append (copias-de (car pedidos) (cdr pedidos))
              (registros-repetidos (sin-copias-de (car pedidos) (cdr pedidos))))))

(define (pago-aprobado? p)
  (string=? (dato p 'estado-pago) "Aprobado"))

(define (inventario-suficiente? p)
  (>= (dato p 'inventario) (dato p 'cantidad)))

(define (facturable? p)
  (and (pago-aprobado? p) (inventario-suficiente? p)))

(define (rechazado-por-inventario? p)
  (and (pago-aprobado? p) (not (inventario-suficiente? p))))

(define (descuento-adicional subtotal)
  (if (>= subtotal 1000000)
      (* subtotal 3/100)
      0))

(define (costo-despacho distancia envio)
  (let* ([tarifa (cond
                   [(<= distancia 10) 8000]
                   [(<= distancia 30) 15000]
                   [else (+ 25000 (* 1000 (- distancia 30)))])])
    (if (string=? envio "Express")
        (* tarifa 140/100)
        tarifa)))

(define (tasa-impuesto categoria)
  (if (string=? categoria "Alimentos") 5/100 19/100))

(define (liquidar p)
  (let* ([subtotal        (* (dato p 'cantidad) (dato p 'precio))]
         [desc-cliente    (pesos (* subtotal (hash-ref descuento-por-tipo (dato p 'tipo-cliente))))]
         [desc-adicional  (pesos (descuento-adicional subtotal))]
         [valor-comercial (- subtotal desc-cliente desc-adicional)]
         [despacho        (pesos (costo-despacho (dato p 'distancia) (dato p 'envio)))]
         [impuesto        (pesos (* (+ valor-comercial despacho)
                                    (tasa-impuesto (dato p 'categoria))))]
         [total           (+ valor-comercial despacho impuesto)])
    (append p (list (list 'subtotal            subtotal)
                    (list 'descuento-cliente   desc-cliente)
                    (list 'descuento-adicional desc-adicional)
                    (list 'valor-comercial     valor-comercial)
                    (list 'despacho            despacho)
                    (list 'impuesto            impuesto)
                    (list 'valor-final         total)))))

(define (ordenar-por-valor pedidos)
  (sort pedidos (lambda (a b) (> (valor-final a) (valor-final b)))))

(define (primeros n lista)
  (if (or (= n 0) (null? lista))
      '()
      (cons (car lista) (primeros (- n 1) (cdr lista)))))

(define (sin-repetir valores)
  (cond
    [(null? valores) '()]
    [(member (car valores) (cdr valores))
     (sin-repetir (cdr valores))]
    [else (cons (car valores) (sin-repetir (cdr valores)))]))

(define (resumen-por campo medida pedidos)
  (map (lambda (valor)
         (let* ([grupo (filter (lambda (p) (equal? (dato p campo) valor)) pedidos)])
           (list valor (length grupo) (sumar medida grupo))))
       (sin-repetir (map (lambda (p) (dato p campo)) pedidos))))

(define (fila-mayor filas)
  (let* ([mayor (apply max (map third filas))])
    (first (filter (lambda (fila) (= (third fila) mayor)) filas))))

(define (estado-conciliacion recibido esperado lineas)
  (cond
    [(not (number? recibido)) "Valor inválido"]
    [(null? lineas)           "Sin pedido facturado"] 
    [(= recibido esperado)    "Conciliado"]
    [(< recibido esperado)    "Saldo pendiente"]
    [else                     "Excedente"]))

(define (conciliar pago facturados)             
  (let* ([lineas     (filter (lambda (p) (equal? (dato p 'numero) (dato pago 'numero))) facturados)]
         [esperado   (sumar 'valor-final lineas)]   
         [recibido   (dato pago 'valor)]
         [estado     (estado-conciliacion recibido esperado lineas)]
         [diferencia (if (number? recibido)
                         (abs (- recibido esperado)) 
                         0)])
    (append pago (list (list 'esperado   esperado)
                       (list 'estado     estado)
                       (list 'diferencia diferencia)))))

(define (con-estado estado resultados)       
  (filter (lambda (r) (string=? (dato r 'estado) estado)) resultados))

(define (datos-consistentes? p)                 
  (and (> (dato p 'subtotal) 0)
       (> (dato p 'valor-comercial) 0)
       (> (dato p 'despacho) 0)
       (> (dato p 'impuesto) 0)
       (> (valor-final p) 0)
       (>= (dato p 'distancia) 0)
       (pedido-valido? p)
       (facturable? p)))

(define (premium-express-alto? p)               
  (and (string=? (dato p 'tipo-cliente) "Premium")
       (string=? (dato p 'envio) "Express")
       (> (valor-final p) 2000000)))

(define (todos-cumplen? condicion lista)        
  (= (length (filter condicion lista)) (length lista)))

(define (alguno-cumple? condicion lista)        
  (not (null? (filter condicion lista))))

(define (porcentaje parte total)                
  (if (zero? total)                             
      0
      (exact->inexact (/ (round (* 10000 (/ parte total))) 100)))) 

(define (si-no condicion)
  (if condicion "Sí" "No"))

(define (titulo texto)
  (displayln (string-append "\n========== " texto " =========="))) 

(define (mostrar-referencia p)                  
  (printf "  - Pedido ~a | Producto ~a | Cliente: ~a\n"
          (dato p 'numero) (dato p 'codigo) (dato p 'nombre)))

(define (mostrar-referencias pedidos)
  (if (null? pedidos)
      (displayln "  (ninguno)")
      (for-each mostrar-referencia pedidos)))  

(define (mostrar-liquidacion p)               
  (printf "\nPedido ~a | Cliente: ~a (CC ~a) | Ciudad: ~a\n"
          (dato p 'numero) (dato p 'nombre) (dato p 'cedula) (dato p 'ciudad))
  (printf "  Producto: ~a [~a] | Categoría: ~a | ~a unidad(es) x $~a\n"
          (dato p 'producto) (dato p 'codigo) (dato p 'categoria) (dato p 'cantidad) (dato p 'precio))
  (printf "  Cliente ~a | Pago: ~a | Envío ~a a ~a km\n"
          (dato p 'tipo-cliente) (dato p 'medio-pago) (dato p 'envio) (dato p 'distancia))
  (printf "  Subtotal: $~a | Descuento cliente: $~a | Descuento adicional: $~a\n"
          (dato p 'subtotal) (dato p 'descuento-cliente) (dato p 'descuento-adicional))
  (printf "  Valor comercial: $~a | Despacho: $~a | Impuesto: $~a\n"
          (dato p 'valor-comercial) (dato p 'despacho) (dato p 'impuesto))
  (printf "  VALOR DEFINITIVO: $~a\n" (valor-final p)))

(define (mostrar-resumen nombre filas etiqueta) 
  (printf "\n~a:\n" nombre)
  (for-each (lambda (fila)
              (printf "  ~a | pedidos: ~a | ~a~a\n" (first fila) (second fila) etiqueta (third fila)))
            filas))

(define (mostrar-pago r)                     
  (printf "  Pedido ~a | recibido: $~a | esperado: $~a | ~a | diferencia: $~a\n"
          (dato r 'numero) (dato r 'valor) (dato r 'esperado) (dato r 'estado) (dato r 'diferencia)))

(displayln "REGISTRO DE PEDIDOS")
(define registros
  (registrar (leer-numero "Cantidad de pedidos a registrar: ") leer-pedido))

(displayln "\nREGISTRO DE PAGOS")
(define pagos
  (registrar (leer-numero "Cantidad de pagos a registrar: ") leer-pago))

(define validos      (filter pedido-valido? registros))                       
(define invalidos    (filter (lambda (p) (not (pedido-valido? p))) registros))
(define unicos       (registros-unicos validos))                              
(define repetidos    (registros-repetidos validos))                           
(define rechazados   (filter rechazado-por-inventario? unicos))
(define no-aprobados (filter (lambda (p) (not (pago-aprobado? p))) unicos))
(define facturados   (ordenar-por-valor (map liquidar (filter facturable? unicos)))) 
(define resultados-pagos (map (lambda (pago) (conciliar pago facturados)) pagos))     

(titulo "1. REGISTROS RECIBIDOS")
(printf "Registros recibidos: ~a\n" (length registros))
(printf "  Con inconsistencias: ~a\n" (length invalidos))
(printf "  Duplicados descartados: ~a\n" (length repetidos))
(printf "  Rechazados por inventario: ~a\n" (length rechazados))
(printf "  Con pago Pendiente o Rechazado: ~a\n" (length no-aprobados))
(printf "  Facturados: ~a\n" (length facturados))

(titulo "2. INCONSISTENCIAS")
(mostrar-referencias invalidos)

(titulo "3. DUPLICADOS")
(printf "Registros repetidos encontrados: ~a\n" (length repetidos))
(mostrar-referencias repetidos)
(printf "Registros únicos para procesar: ~a\n" (length unicos))

(titulo "4. PEDIDOS RECHAZADOS POR INVENTARIO")
(mostrar-referencias rechazados)
(displayln "No procesados por pago Pendiente o Rechazado:")
(mostrar-referencias no-aprobados)

(titulo "5. PEDIDOS FACTURADOS (de mayor a menor valor)")
(if (null? facturados)
    (displayln "No hay pedidos facturados.")
    (for-each mostrar-liquidacion facturados))

(titulo "6. VALORES ECONÓMICOS")
(printf "Total bruto antes de descuentos: $~a\n" (sumar 'subtotal facturados))
(printf "Total descontado: $~a\n" (+ (sumar 'descuento-cliente facturados)
                                   (sumar 'descuento-adicional facturados)))
(printf "Total cobrado por despachos: $~a\n" (sumar 'despacho facturados))
(printf "Total generado en impuestos: $~a\n" (sumar 'impuesto facturados))
(printf "Total definitivo facturado: $~a\n" (sumar 'valor-final facturados))

(if (null? facturados)
    (displayln "Sin pedidos facturados: no hay mayor, menor ni promedio.")
    (let* ([mayor          (first facturados)]            
           [menor          (first (reverse facturados))]  
           [promedio       (/ (sumar 'valor-final facturados) (length facturados))]
           [sobre-promedio (filter (lambda (p) (> (valor-final p) promedio)) facturados)])
      (printf "Pedido de mayor valor: ~a ($~a)\n" (dato mayor 'numero) (valor-final mayor))
      (printf "Pedido de menor valor: ~a ($~a)\n" (dato menor 'numero) (valor-final menor))
      (printf "Promedio por pedido facturado: $~a\n" (pesos promedio))
      (displayln "Pedidos por encima del promedio:")
      (mostrar-referencias sobre-promedio)))

(displayln "\nCinco pedidos de mayor valor:")
(if (>= (length facturados) 5)
    (let* ([top (primeros 5 facturados)])
      (for ([i (in-range (length top))])          
        (printf "  ~a. Pedido ~a | ~a | $~a\n"
                (+ i 1)
                (dato (list-ref top i) 'numero)   
                (dato (list-ref top i) 'nombre)
                (valor-final (list-ref top i)))))
    (displayln "  Se requieren al menos cinco pedidos facturados."))

(titulo "7. RESÚMENES POR AGRUPACIÓN")
(mostrar-resumen "Facturación por ciudad"
                 (resumen-por 'ciudad 'valor-final facturados) "total: $")
(mostrar-resumen "Facturación por categoría"
                 (resumen-por 'categoria 'valor-final facturados) "total: $")
(mostrar-resumen "Facturación por tipo de cliente"
                 (resumen-por 'tipo-cliente 'valor-final facturados) "total: $")
(mostrar-resumen "Pedidos procesados por medio de pago"
                 (resumen-por 'medio-pago 'valor-final facturados) "total: $")
(mostrar-resumen "Unidades a descontar del inventario por código"
                 (resumen-por 'codigo 'cantidad facturados) "unidades: ")

(if (null? facturados)
    (displayln "\nSin datos para categoría y cliente destacados.")
    (let* ([categoria (fila-mayor (resumen-por 'categoria 'valor-final facturados))]
           [cliente   (fila-mayor (resumen-por 'cedula 'valor-final facturados))]
           [nombre    (dato (first (filter (lambda (p) (equal? (dato p 'cedula) (first cliente)))
                                           facturados))
                            'nombre)])
      (printf "\nCategoría con mayor facturación: ~a ($~a)\n" (first categoria) (third categoria))
      (printf "Cliente con mayor valor acumulado: ~a, CC ~a ($~a en ~a pedido(s))\n"
              nombre (first cliente) (third cliente) (second cliente))))

(titulo "8. CONCILIACIÓN DE PAGOS")
(if (null? resultados-pagos)
    (displayln "No se registraron pagos.")
    (begin                                        
      (for-each mostrar-pago resultados-pagos)
      (printf "\nPagos conciliados: ~a\n" (length (con-estado "Conciliado" resultados-pagos)))
      (printf "Total de dinero pendiente: $~a\n"
              (sumar 'diferencia (con-estado "Saldo pendiente" resultados-pagos)))
      (printf "Total de excedentes recibidos: $~a\n"
              (sumar 'diferencia (con-estado "Excedente" resultados-pagos)))
      (printf "Números de pedido con diferencias: ~a\n"
              (map (lambda (r) (dato r 'numero))
                   (filter (lambda (r) (not (string=? (dato r 'estado) "Conciliado")))
                           resultados-pagos)))))

(titulo "9. MÉTRICAS GENERALES DE LA JORNADA")
(printf "Registros que terminaron en venta facturada: ~a%\n"
        (porcentaje (length facturados) (length registros)))
(printf "¿Todos los facturados tienen valores positivos y datos consistentes?: ~a\n"
        (si-no (todos-cumplen? datos-consistentes? facturados)))
(printf "¿Existe un pedido Premium con envío Express de más de $2.000.000?: ~a\n"
        (si-no (alguno-cumple? premium-express-alto? facturados)))
