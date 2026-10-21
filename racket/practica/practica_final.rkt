#lang racket
; =====================================================================
;  SISTEMA INTEGRAL DE GESTIÓN, CONCILIACIÓN Y LIQUIDACIÓN DE PEDIDOS
; =====================================================================
;  Cómo se guardan los datos:
;  - Cada registro (pedido o pago) es una LISTA DE PARES (campo valor).
;      Ejemplo: (list (list 'numero 101) (list 'ciudad "Medellín") ...)
;  - Un campo se consulta con (dato registro 'campo).
;  - Ninguna lista se modifica: cada etapa (validar, filtrar, liquidar,
;    agrupar, conciliar) construye una lista NUEVA a partir de la anterior.
;
;  Decisiones tomadas donde el enunciado no es explícito:
;  - Tipo de cliente, medio de pago, envío y estado del pago deben
;    escribirse exactamente como los define la empresa (string=? y member
;    distinguen mayúsculas: "aprobado" no es "Aprobado").
;  - Los valores en dinero se redondean a pesos enteros (sin centavos).
;  - Los duplicados se buscan entre los registros válidos y se conserva
;    la primera aparición.
;  - Un número de pedido puede tener varios productos (códigos distintos).
;    En la conciliación, el valor esperado de un pedido es la suma de sus
;    líneas facturadas.
;  - El top 5 se muestra cuando hay al menos cinco pedidos facturados.
; =====================================================================


; ---------------------------------------------------------------------
; 1. VALORES PERMITIDOS Y TARIFAS
; ---------------------------------------------------------------------
(define tipos-cliente (list "Normal" "Frecuente" "Premium"))             ; list: lista con las opciones válidas
(define medios-pago   (list "Efectivo" "Tarjeta" "PSE" "Transferencia"))
(define tipos-envio   (list "Normal" "Express"))
(define estados-pago  (list "Aprobado" "Pendiente" "Rechazado"))

(define descuento-por-tipo                      ; Diccionario: tipo de cliente -> porcentaje de descuento
  (make-hash (list (cons "Normal"    0)         ; cons arma cada par (clave . valor)
                   (cons "Frecuente" 5/100)     ; 5/100 = 5 % escrito como fracción exacta (sin errores de decimales)
                   (cons "Premium"   10/100)))) ; 10/100 = 10 %


; ---------------------------------------------------------------------
; 2. LECTURA DE DATOS POR TECLADO
; ---------------------------------------------------------------------
(define (leer-texto mensaje)                    ; Muestra un mensaje y retorna lo que escriba el usuario
  (display mensaje)                             ; display: imprime sin salto de línea
  (read-line))                                  ; read-line: lee la línea completa como texto

(define (leer-numero mensaje)                   ; Igual que leer-texto, pero convierte a número
  (string->number (leer-texto mensaje)))        ; string->number retorna #f si el texto no es numérico

(define (leer-pedido)                           ; Lee los 15 datos de UN pedido
  (displayln "\n--- Nuevo pedido ---")          ; displayln: imprime con salto de línea
  (list (list 'numero       (leer-numero "Número de pedido: "))     ; Racket evalúa los argumentos de izquierda
        (list 'cedula       (leer-texto  "Cédula del cliente: "))   ; a derecha, por eso las preguntas salen
        (list 'nombre       (leer-texto  "Nombre del cliente: "))   ; en este mismo orden
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

(define (leer-pago)                             ; Lee un registro de la colección de pagos
  (displayln "\n--- Nuevo pago ---")
  (list (list 'numero (leer-numero "Número de pedido: "))
        (list 'valor  (leer-numero "Valor recibido por la empresa: "))))

(define (registrar cantidad leer-registro)      ; Lee "cantidad" registros con la función que recibe (leer-pedido o leer-pago)
  (if (or (not (number? cantidad))              ; CASO BASE: la cantidad no es un número...
          (<= cantidad 0))                      ; ...o ya no faltan registros
      '()                                       ; retorna la lista vacía
      (cons (leer-registro)                     ; CASO RECURSIVO: lee un registro y lo pone al frente...
            (registrar (- cantidad 1) leer-registro)))) ; ...del resto, que se lee con uno menos


; ---------------------------------------------------------------------
; 3. CONSULTA DE CAMPOS Y SUMAS
; ---------------------------------------------------------------------
(define (dato registro campo)                   ; Retorna el valor de un campo del registro
  (second (assoc campo registro)))              ; assoc busca el par (campo valor); second toma el valor

(define (valor-final pedido)                    ; Atajo: valor definitivo de un pedido ya liquidado
  (dato pedido 'valor-final))

(define (sumar campo registros)                 ; Suma un campo en toda una lista de registros
  (apply + (map (lambda (r) (dato r campo)) registros))) ; map extrae los valores; apply + los suma (lista vacía -> 0)

(define (pesos valor)                           ; Redondea un valor de dinero a pesos enteros
  (round valor))


; ---------------------------------------------------------------------
; 4. VALIDACIÓN (detección de inconsistencias)
; ---------------------------------------------------------------------
(define (valor-permitido? valor opciones)       ; ¿El valor está entre las opciones definidas por la empresa?
  (if (member valor opciones) #t #f))           ; member retorna una sublista si lo encuentra, o #f si no

(define (pedido-valido? p)                      ; #t solo si el pedido NO tiene ninguna inconsistencia
  (and (number? (dato p 'numero))               ; and: TODAS las condiciones deben cumplirse
       (> (dato p 'numero) 0)                   ; número de pedido positivo
       (not (string=? (dato p 'cedula) ""))     ; cédula no vacía
       (number? (dato p 'cantidad))
       (> (dato p 'cantidad) 0)                 ; cantidad solicitada mayor que cero
       (number? (dato p 'precio))
       (> (dato p 'precio) 0)                   ; precio unitario mayor que cero
       (number? (dato p 'inventario))
       (>= (dato p 'inventario) 0)              ; inventario no negativo
       (number? (dato p 'distancia))            ; la distancia debe ser numérica para calcular el despacho
       (not (string=? (dato p 'categoria) ""))  ; categoría no vacía
       (valor-permitido? (dato p 'medio-pago)   medios-pago)
       (valor-permitido? (dato p 'tipo-cliente) tipos-cliente)
       (valor-permitido? (dato p 'envio)        tipos-envio)
       (valor-permitido? (dato p 'estado-pago)  estados-pago)))


; ---------------------------------------------------------------------
; 5. DUPLICADOS (mismo número de pedido y mismo código de producto)
; ---------------------------------------------------------------------
(define (clave p)                               ; Identificador de un registro: (número código)
  (list (dato p 'numero) (dato p 'codigo)))

(define (mismo-registro? a b)                   ; ¿Dos registros tienen la misma clave?
  (equal? (clave a) (clave b)))                 ; equal? compara las dos listas completas

(define (copias-de p lista)                     ; Registros de la lista iguales a p
  (filter (lambda (otro) (mismo-registro? otro p)) lista))

(define (sin-copias-de p lista)                 ; Registros de la lista distintos de p
  (filter (lambda (otro) (not (mismo-registro? otro p))) lista))

(define (registros-unicos pedidos)              ; Conserva la primera aparición de cada registro
  (if (null? pedidos)                           ; CASO BASE: lista vacía
      '()
      (cons (car pedidos)                       ; car: primer registro, se conserva...
            (registros-unicos (sin-copias-de (car pedidos) (cdr pedidos)))))) ; ...cdr: el resto, sin sus copias

(define (registros-repetidos pedidos)           ; Retorna las copias que se descartaron
  (if (null? pedidos)
      '()
      (append (copias-de (car pedidos) (cdr pedidos))    ; append une las copias del primero...
              (registros-repetidos (sin-copias-de (car pedidos) (cdr pedidos)))))) ; ...con las copias del resto


; ---------------------------------------------------------------------
; 6. CONDICIONES COMERCIALES
; ---------------------------------------------------------------------
(define (pago-aprobado? p)
  (string=? (dato p 'estado-pago) "Aprobado"))

(define (inventario-suficiente? p)              ; No se permiten despachos parciales
  (>= (dato p 'inventario) (dato p 'cantidad)))

(define (facturable? p)                         ; Pago aprobado Y inventario suficiente
  (and (pago-aprobado? p) (inventario-suficiente? p)))

(define (rechazado-por-inventario? p)           ; Pago aprobado pero SIN inventario suficiente
  (and (pago-aprobado? p) (not (inventario-suficiente? p))))


; ---------------------------------------------------------------------
; 7. LIQUIDACIÓN DE UN PEDIDO
; ---------------------------------------------------------------------
(define (descuento-adicional subtotal)          ; 3 % extra si el subtotal es >= $1.000.000
  (if (>= subtotal 1000000)
      (* subtotal 3/100)
      0))

(define (costo-despacho distancia envio)        ; Tarifa por distancia + recargo Express
  (let* ([tarifa (cond                          ; cond: varios rangos, se detiene en el primero verdadero
                   [(<= distancia 10) 8000]     ; hasta 10 km
                   [(<= distancia 30) 15000]    ; entre 11 y 30 km
                   [else (+ 25000 (* 1000 (- distancia 30)))])]) ; más de 30 km: $25.000 + $1.000 por km adicional
    (if (string=? envio "Express")
        (* tarifa 140/100)                      ; recargo del 40 %
        tarifa)))

(define (tasa-impuesto categoria)               ; 5 % para Alimentos, 19 % para lo demás
  (if (string=? categoria "Alimentos") 5/100 19/100))

(define (liquidar p)                            ; Retorna un registro NUEVO: el pedido + sus valores calculados
  (let* ([subtotal        (* (dato p 'cantidad) (dato p 'precio))]  ; let*: cada valor usa los anteriores
         [desc-cliente    (pesos (* subtotal (hash-ref descuento-por-tipo (dato p 'tipo-cliente))))] ; hash-ref busca el % del tipo
         [desc-adicional  (pesos (descuento-adicional subtotal))]   ; ambos descuentos sobre el subtotal original
         [valor-comercial (- subtotal desc-cliente desc-adicional)]
         [despacho        (pesos (costo-despacho (dato p 'distancia) (dato p 'envio)))]
         [impuesto        (pesos (* (+ valor-comercial despacho)   ; base = valor comercial + despacho
                                    (tasa-impuesto (dato p 'categoria))))]
         [total           (+ valor-comercial despacho impuesto)])
    (append p (list (list 'subtotal            subtotal)            ; append agrega los campos calculados
                    (list 'descuento-cliente   desc-cliente)        ; sin modificar el pedido original
                    (list 'descuento-adicional desc-adicional)
                    (list 'valor-comercial     valor-comercial)
                    (list 'despacho            despacho)
                    (list 'impuesto            impuesto)
                    (list 'valor-final         total)))))


; ---------------------------------------------------------------------
; 8. ORDENAMIENTO Y AGRUPACIÓN
; ---------------------------------------------------------------------
(define (ordenar-por-valor pedidos)             ; De mayor a menor valor definitivo
  (sort pedidos (lambda (a b) (> (valor-final a) (valor-final b))))) ; "a" va antes que "b" si vale más

(define (primeros n lista)                      ; Los primeros n elementos de una lista
  (if (or (= n 0) (null? lista))
      '()
      (cons (car lista) (primeros (- n 1) (cdr lista)))))

(define (sin-repetir valores)                   ; Deja una sola vez cada valor (ej: cada ciudad una vez)
  (cond
    [(null? valores) '()]
    [(member (car valores) (cdr valores))       ; si el valor vuelve a aparecer más adelante...
     (sin-repetir (cdr valores))]               ; ...se salta esta aparición
    [else (cons (car valores) (sin-repetir (cdr valores)))]))

(define (resumen-por campo medida pedidos)      ; Agrupa por "campo" y suma "medida" en cada grupo
  (map (lambda (valor)                          ; Por cada valor distinto del campo...
         (let* ([grupo (filter (lambda (p) (equal? (dato p campo) valor)) pedidos)]) ; ...toma sus pedidos
           (list valor (length grupo) (sumar medida grupo)))) ; fila: (valor  cantidad-de-pedidos  total)
       (sin-repetir (map (lambda (p) (dato p campo)) pedidos))))

(define (fila-mayor filas)                      ; Fila del resumen con el mayor total (tercer elemento)
  (let* ([mayor (apply max (map third filas))]) ; max recibe números sueltos; apply le pasa la lista
    (first (filter (lambda (fila) (= (third fila) mayor)) filas))))


; ---------------------------------------------------------------------
; 9. CONCILIACIÓN DE PAGOS
; ---------------------------------------------------------------------
(define (estado-conciliacion recibido esperado lineas)
  (cond
    [(not (number? recibido)) "Valor inválido"]
    [(null? lineas)           "Sin pedido facturado"] ; no hay pedido facturado con ese número
    [(= recibido esperado)    "Conciliado"]
    [(< recibido esperado)    "Saldo pendiente"]
    [else                     "Excedente"]))

(define (conciliar pago facturados)             ; Retorna un registro NUEVO: el pago + su resultado
  (let* ([lineas     (filter (lambda (p) (equal? (dato p 'numero) (dato pago 'numero))) facturados)]
         [esperado   (sumar 'valor-final lineas)]   ; suma de las líneas facturadas de ese pedido
         [recibido   (dato pago 'valor)]
         [estado     (estado-conciliacion recibido esperado lineas)]
         [diferencia (if (number? recibido)
                         (abs (- recibido esperado)) ; abs: diferencia siempre positiva
                         0)])
    (append pago (list (list 'esperado   esperado)
                       (list 'estado     estado)
                       (list 'diferencia diferencia)))))

(define (con-estado estado resultados)          ; Resultados de conciliación con un estado dado
  (filter (lambda (r) (string=? (dato r 'estado) estado)) resultados))


; ---------------------------------------------------------------------
; 10. VERIFICACIONES Y UTILIDADES DEL INFORME
; ---------------------------------------------------------------------
(define (datos-consistentes? p)                 ; Comprobación final de un pedido facturado
  (and (> (dato p 'subtotal) 0)
       (> (dato p 'valor-comercial) 0)
       (> (dato p 'despacho) 0)
       (> (dato p 'impuesto) 0)
       (> (valor-final p) 0)
       (>= (dato p 'distancia) 0)
       (pedido-valido? p)
       (facturable? p)))

(define (premium-express-alto? p)               ; Premium + Express + valor final > $2.000.000
  (and (string=? (dato p 'tipo-cliente) "Premium")
       (string=? (dato p 'envio) "Express")
       (> (valor-final p) 2000000)))

(define (todos-cumplen? condicion lista)        ; ¿Todos los elementos cumplen la condición?
  (= (length (filter condicion lista)) (length lista)))

(define (alguno-cumple? condicion lista)        ; ¿Al menos uno la cumple?
  (not (null? (filter condicion lista))))

(define (porcentaje parte total)                ; Porcentaje con 2 decimales
  (if (zero? total)                             ; zero?: evita dividir por cero
      0
      (exact->inexact (/ (round (* 10000 (/ parte total))) 100)))) ; exact->inexact: fracción -> decimal

(define (si-no condicion)
  (if condicion "Sí" "No"))

(define (titulo texto)
  (displayln (string-append "\n========== " texto " =========="))) ; string-append une textos

(define (mostrar-referencia p)                  ; Línea corta para identificar un pedido
  (printf "  - Pedido ~a | Producto ~a | Cliente: ~a\n"
          (dato p 'numero) (dato p 'codigo) (dato p 'nombre)))

(define (mostrar-referencias pedidos)
  (if (null? pedidos)
      (displayln "  (ninguno)")
      (for-each mostrar-referencia pedidos)))   ; for-each: aplica la función a cada uno (solo imprime)

(define (mostrar-liquidacion p)                 ; Detalle completo de un pedido facturado
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

(define (mostrar-resumen nombre filas etiqueta) ; Imprime un resumen (valor | pedidos | total)
  (printf "\n~a:\n" nombre)
  (for-each (lambda (fila)
              (printf "  ~a | pedidos: ~a | ~a~a\n" (first fila) (second fila) etiqueta (third fila)))
            filas))

(define (mostrar-pago r)                        ; Resultado de conciliación de un pago
  (printf "  Pedido ~a | recibido: $~a | esperado: $~a | ~a | diferencia: $~a\n"
          (dato r 'numero) (dato r 'valor) (dato r 'esperado) (dato r 'estado) (dato r 'diferencia)))


; =====================================================================
;                         PROGRAMA PRINCIPAL
; =====================================================================

; ---------- ENTRADA (la cantidad se conoce solo en ejecución) ----------
(displayln "REGISTRO DE PEDIDOS")
(define registros
  (registrar (leer-numero "Cantidad de pedidos a registrar: ") leer-pedido))

(displayln "\nREGISTRO DE PAGOS")
(define pagos
  (registrar (leer-numero "Cantidad de pagos a registrar: ") leer-pago))

; ---------- PROCESAMIENTO (cada paso crea una lista nueva) ----------
(define validos      (filter pedido-valido? registros))                       ; selección
(define invalidos    (filter (lambda (p) (not (pedido-valido? p))) registros))
(define unicos       (registros-unicos validos))                              ; sin duplicados
(define repetidos    (registros-repetidos validos))                           ; copias descartadas
(define rechazados   (filter rechazado-por-inventario? unicos))
(define no-aprobados (filter (lambda (p) (not (pago-aprobado? p))) unicos))
(define facturados   (ordenar-por-valor (map liquidar (filter facturable? unicos)))) ; transformación + ordenamiento
(define resultados-pagos (map (lambda (pago) (conciliar pago facturados)) pagos))     ; conciliación

; ---------- INFORME CONSOLIDADO ----------
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
    (let* ([mayor          (first facturados)]            ; la lista está ordenada de mayor a menor
           [menor          (first (reverse facturados))]  ; reverse: el último pasa a ser el primero
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
      (for ([i (in-range (length top))])          ; for: i toma los valores 0, 1, 2, 3, 4
        (printf "  ~a. Pedido ~a | ~a | $~a\n"
                (+ i 1)
                (dato (list-ref top i) 'numero)   ; list-ref: elemento en la posición i
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
           [cliente   (fila-mayor (resumen-por 'cedula 'valor-final facturados))] ; agrupa por cédula
           [nombre    (dato (first (filter (lambda (p) (equal? (dato p 'cedula) (first cliente)))
                                           facturados))
                            'nombre)])
      (printf "\nCategoría con mayor facturación: ~a ($~a)\n" (first categoria) (third categoria))
      (printf "Cliente con mayor valor acumulado: ~a, CC ~a ($~a en ~a pedido(s))\n"
              nombre (first cliente) (third cliente) (second cliente))))

(titulo "8. CONCILIACIÓN DE PAGOS")
(if (null? resultados-pagos)
    (displayln "No se registraron pagos.")
    (begin                                        ; begin: agrupa varias acciones en una rama del if
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


; =====================================================================
;  MAPA DE FUNCIONES (para la sustentación)
; =====================================================================
;  define ............ variables (registros, facturados...) y funciones
;  list .............. crear registros, filas de resumen y listas de opciones
;  cons .............. registrar (recursión), pares del diccionario, primeros
;  car / cdr ......... registros-unicos, registros-repetidos, sin-repetir, primeros
;  first ............. mayor pedido, fila-mayor, nombre del mejor cliente
;  second ............ dato (valor de un par), mostrar-resumen
;  third ............. total de una fila de resumen (fila-mayor)
;  list-ref .......... top 5 por posición
;  length ............ conteos del informe, promedio
;  reverse ........... pedido de menor valor
;  append ............ liquidar y conciliar (agregan campos), registros-repetidos
;  assoc ............. dato (buscar un campo por su nombre)
;  member ............ valor-permitido?, sin-repetir
;  equal? ............ mismo-registro?, agrupar por campo
;  map ............... sumar, resumen-por, liquidar todos, conciliar todos
;  filter ............ válidos, inválidos, facturables, grupos, estados
;  apply ............. sumar (apply +), fila-mayor (apply max)
;  for-each .......... imprimir listas de pedidos y pagos
;  for + in-range .... top 5 numerado
;  lambda ............ condiciones en filter/map y comparación de sort
;  if ................ decisiones de dos caminos
;  cond .............. tarifas de despacho, estado de conciliación, sin-repetir
;  and / or / not .... validación y condiciones comerciales
;  let* .............. liquidar (cada valor depende del anterior)
;  begin ............. varias acciones en una rama del if (conciliación)
;  make-hash/hash-ref  diccionario de descuentos por tipo de cliente
;  null? ............. casos base y listas vacías
;  number? ........... validar datos numéricos
;  zero? ............. evitar división por cero en porcentaje
;  string=? .......... comparar estados, categoría, envío, cédula vacía
;  string->number .... convertir lo digitado a número
;  string-append ..... títulos del informe
;  max ............... mayor total de un resumen
;  abs ............... diferencia de conciliación siempre positiva
;  round ............. pesos enteros y porcentaje con 2 decimales
;  exact->inexact .... mostrar el porcentaje en decimal
;  read-line ......... leer lo que escribe el usuario
;  display/displayln . mensajes y títulos
;  printf ............ líneas del informe con marcadores ~a
;  sort .............. ordenar facturados de mayor a menor (visto en la tarea anterior)
; =====================================================================
