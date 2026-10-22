#lang racket
; ↑ LÍNEA 1: le dice a DrRacket en qué lenguaje está escrito el archivo.
;   #lang  → significa "el lenguaje de este archivo es...". Siempre va en la primera línea.
;   racket → Racket completo. Se usa este y no "Beginning Student" porque en ese nivel
;            no existen read-line, printf, let* ni begin, que este programa necesita.

; =====================================================================
;  GUÍA RÁPIDA DE SÍMBOLOS (léela antes del código)
; =====================================================================
;  ;         PUNTO Y COMA: todo lo que va después, hasta el final de la línea, es un
;            COMENTARIO. Racket lo ignora; solo sirve para explicar el código a quien lo lee.
;
;  ( )       PARÉNTESIS: cada par de paréntesis es UNA ORDEN.
;            Lo primero que va adentro dice QUÉ hacer; lo demás son los DATOS.
;              (+ 2 3)        → "suma 2 y 3" → 5
;              (* (+ 1 2) 4)  → primero se resuelve el de adentro (+ 1 2) = 3,
;                               luego (* 3 4) = 12
;            Cada "(" abre una orden y cada ")" la cierra. Siempre hay la misma cantidad
;            de "(" que de ")". Cuando una línea termina en ")))", cada ")" cierra una
;            orden abierta antes, empezando por la más interna.
;            En DrRacket, al poner el cursor junto a un paréntesis se resalta su pareja.
;
;  [ ]       CORCHETES: para Racket son IGUALES a los paréntesis. Por costumbre se usan
;            dentro de let*, cond y for para que el código se lea mejor.
;
;  espacio   Separa las partes de una orden. (- cantidad 1) = "resta 1 a cantidad".
;            Los espacios extra para alinear columnas no tienen ningún efecto.
;
;  sangría   Los espacios al inicio de cada línea solo ayudan a leer. Racket no los
;            tiene en cuenta; lo que manda son los paréntesis.
;
;  -         GUION DENTRO DE UN NOMBRE (leer-texto, valor-final): es solo una letra más,
;            NO resta. Solo resta cuando va solo y separado por espacios: (- 10 4) → 6.
;
;  ?         Al FINAL de un nombre (null?, pedido-valido?) indica, por costumbre, que la
;            función responde verdadero o falso. Es parte del nombre.
;
;  ->        DENTRO de un nombre (string->number, exact->inexact) se lee "convertir a".
;            string->number = "convertir texto a número". Es parte del nombre.
;
;  *         En let* es parte del nombre. Solo (* a b) significa multiplicar.
;
;  "texto"   COMILLAS DOBLES: un TEXTO (en programación se llama "string").
;            "Medellín" es un texto. "" es el texto vacío (sin ninguna letra).
;
;  \n        Dentro de un texto significa SALTO DE LÍNEA (bajar a la línea siguiente).
;
;  'nombre   COMILLA SIMPLE delante de una palabra: un SÍMBOLO, es decir, una etiqueta.
;            'ciudad no es una variable ni un texto; es un nombre usado como dato.
;            Aquí se usan como nombres de los campos de cada pedido.
;
;  '()       LISTA VACÍA: una lista sin ningún elemento.
;
;  #t  #f    VERDADERO (true) y FALSO (false). En Racket solo #f es falso;
;            cualquier otro valor (un número, un texto, una lista) cuenta como verdadero.
;
;  5/100     FRACCIÓN EXACTA: 5 dividido 100, es decir 5 %. Racket la simplifica y la
;            muestra como 1/20. Se usa en vez de 0.05 porque los decimales pueden
;            acumular errores pequeños (43000 × 1.4 da 60199.99999999999).
;
;  ~a        Dentro del texto de un printf significa "aquí va un valor". Cada ~a se
;            reemplaza por los valores que van después del texto, en el mismo orden.
;
;  $ % | :   Dentro de un texto son caracteres normales; se imprimen tal cual.
;
;  OPERADORES (siempre van ANTES de los números):
;    +  suma        -  resta        *  multiplica        /  divide
;    =  ¿iguales?   <  ¿menor?      >  ¿mayor?           <= ¿menor o igual?   >= ¿mayor o igual?
;    (> 5 3) se lee "¿5 es mayor que 3?" → #t
; =====================================================================


; ⚠ LÍNEA OPCIONAL, SOLO PARA PROBAR CON EL ARCHIVO datos_prueba.txt.
;   Así como está (con ";" al inicio) es un comentario: el programa lee del TECLADO.
;   Para probar con el archivo, borra el ";" del inicio de la línea de abajo.
;   VUELVE A PONERLO antes de entregar o sustentar: el enunciado exige leer por teclado.
;   open-input-file "datos_prueba.txt" → abre ese archivo para leerlo.
;   current-input-port → indica DE DÓNDE lee read-line. Normalmente es el teclado;
;     al darle el archivo abierto, read-line lee las líneas del archivo una por una.
; (current-input-port (open-input-file "datos_prueba.txt"))


; =====================================================================
;  RESUMEN DEL PROGRAMA
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
;    escribirse exactamente como los define la empresa ("aprobado" no es "Aprobado").
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

; define → crea un NOMBRE y le guarda un valor. Forma: (define nombre valor)
; tipos-cliente → el nombre que se crea (los guiones son parte del nombre).
; (list "Normal" "Frecuente" "Premium") → crea una LISTA con esos tres textos.
; Resultado: tipos-cliente vale '("Normal" "Frecuente" "Premium").
; El primer ")" cierra el list y el segundo cierra el define.
(define tipos-cliente (list "Normal" "Frecuente" "Premium"))

; Igual que la anterior: lista con los 4 medios de pago permitidos.
; Los espacios antes de (list solo alinean el código; no hacen nada.
(define medios-pago   (list "Efectivo" "Tarjeta" "PSE" "Transferencia"))

; Lista con los 2 tipos de envío permitidos.
(define tipos-envio   (list "Normal" "Express"))

; Lista con los 3 estados de pago permitidos.
(define estados-pago  (list "Aprobado" "Pendiente" "Rechazado"))

; Crea el nombre descuento-por-tipo. Su valor ocupa las líneas siguientes.
; Será un DICCIONARIO: a cada tipo de cliente le corresponde su porcentaje de descuento.
(define descuento-por-tipo
  ; make-hash → crea un diccionario a partir de una lista de pares (clave, valor).
  ; (list → empieza la lista de pares.
  ; (cons "Normal" 0) → crea UN par: clave "Normal", valor 0 (sin descuento).
  ;   Racket muestra este par como ("Normal" . 0); el punto separa clave y valor.
  (make-hash (list (cons "Normal"    0)
                   ; Par: clave "Frecuente", valor 5/100 (5 %).
                   (cons "Frecuente" 5/100)
                   ; Par: clave "Premium", valor 10/100 (10 %).
                   ; Los 4 ")" finales cierran, en orden: cons, list, make-hash y define.
                   (cons "Premium"   10/100))))


; ---------------------------------------------------------------------
; 2. LECTURA DE DATOS POR TECLADO
; ---------------------------------------------------------------------

; FUNCIÓN leer-texto: muestra una pregunta y devuelve lo que escriba el usuario.
; Cuando después de define viene un paréntesis, se está creando una FUNCIÓN:
;   (define (nombre-de-la-función parámetro) cuerpo)
;   leer-texto → nombre de la función.
;   mensaje    → PARÁMETRO: el dato que la función recibe cada vez que se usa.
;   Ejemplo de uso: (leer-texto "Ciudad: ") → dentro de la función, mensaje vale "Ciudad: ".
(define (leer-texto mensaje)
  ; display → muestra el mensaje en pantalla SIN bajar de línea,
  ;   para que el usuario escriba en la misma línea de la pregunta.
  (display mensaje)
  ; read-line → espera a que el usuario escriba algo y presione Enter,
  ;   y devuelve lo escrito como TEXTO (aunque escriba un número, llega como texto: "12").
  ; Una función devuelve el valor de su ÚLTIMA línea: leer-texto devuelve lo que leyó read-line.
  ; El primer ")" cierra read-line y el segundo cierra el define.
  (read-line))

; FUNCIÓN leer-numero: igual que leer-texto, pero devuelve un NÚMERO.
(define (leer-numero mensaje)
  ; Se lee de adentro hacia afuera:
  ; 1. (leer-texto mensaje) → muestra la pregunta y devuelve el texto escrito, ej. "12".
  ; 2. string->number → convierte ese texto en número: "12" → 12, "12.5" → 12.5.
  ;    Si el texto no es un número ("abc" o vacío), devuelve #f (falso).
  ; Los 3 ")" cierran: leer-texto, string->number y define.
  (string->number (leer-texto mensaje)))

; FUNCIÓN leer-pedido: pregunta los 15 datos de UN pedido y devuelve el pedido.
; Los paréntesis después del nombre no tienen parámetros: la función no recibe datos.
(define (leer-pedido)
  ; displayln → muestra el texto y SÍ baja de línea al final.
  ; El "\n" al inicio del texto deja una línea en blanco antes del título.
  (displayln "\n--- Nuevo pedido ---")
  ; Aquí empieza la LISTA que forma el pedido. Cada elemento es un PAR (campo valor).
  ; (list 'numero (leer-numero "Número de pedido: ")) es un par de 2 elementos:
  ;   'numero          → símbolo que hace de nombre del campo.
  ;   (leer-numero ...) → hace la pregunta y lee el número.
  ;   Si el usuario escribe 101, el par queda: '(numero 101).
  ; Racket resuelve los datos de una orden de izquierda a derecha (aquí, de arriba abajo),
  ; por eso las preguntas salen exactamente en este orden.
  (list (list 'numero       (leer-numero "Número de pedido: "))
        ; Par 'cedula. Se lee como TEXTO porque con la cédula no se hacen cuentas.
        (list 'cedula       (leer-texto  "Cédula del cliente: "))
        ; Par 'nombre (texto).
        (list 'nombre       (leer-texto  "Nombre del cliente: "))
        ; Par 'ciudad (texto).
        (list 'ciudad       (leer-texto  "Ciudad: "))
        ; Par 'categoria (texto). Importa si es "Alimentos" (impuesto del 5 %).
        (list 'categoria    (leer-texto  "Categoría del producto: "))
        ; Par 'codigo (texto). Junto con el número de pedido identifica los duplicados.
        (list 'codigo       (leer-texto  "Código del producto: "))
        ; Par 'producto (texto).
        (list 'producto     (leer-texto  "Nombre del producto: "))
        ; Par 'cantidad (NÚMERO, porque se multiplica por el precio).
        (list 'cantidad     (leer-numero "Cantidad solicitada: "))
        ; Par 'precio (número).
        (list 'precio       (leer-numero "Precio unitario: "))
        ; Par 'inventario (número): unidades disponibles.
        (list 'inventario   (leer-numero "Cantidad disponible en inventario: "))
        ; Par 'medio-pago (texto). La "/" dentro del texto es un carácter normal.
        (list 'medio-pago   (leer-texto  "Medio de pago (Efectivo/Tarjeta/PSE/Transferencia): "))
        ; Par 'tipo-cliente (texto).
        (list 'tipo-cliente (leer-texto  "Tipo de cliente (Normal/Frecuente/Premium): "))
        ; Par 'envio (texto).
        (list 'envio        (leer-texto  "Tipo de envío (Normal/Express): "))
        ; Par 'distancia (número, en kilómetros).
        (list 'distancia    (leer-numero "Distancia del despacho en km: "))
        ; Último par: 'estado-pago (texto).
        ; Los 4 ")" finales cierran: leer-texto, el par, la lista del pedido y el define.
        (list 'estado-pago  (leer-texto  "Estado del pago (Aprobado/Pendiente/Rechazado): "))))

; FUNCIÓN leer-pago: pregunta los 2 datos de UN pago y devuelve el pago.
(define (leer-pago)
  ; Título del pago, con una línea en blanco antes.
  (displayln "\n--- Nuevo pago ---")
  ; Lista del pago. Primer par: 'numero (número del pedido que se está pagando).
  (list (list 'numero (leer-numero "Número de pedido: "))
        ; Segundo par: 'valor (dinero recibido).
        ; Los 4 ")" finales cierran: leer-numero, el par, la lista del pago y el define.
        (list 'valor  (leer-numero "Valor recibido por la empresa: "))))

; FUNCIÓN registrar: lee varios registros y los devuelve en una lista.
; Recibe 2 parámetros:
;   cantidad      → cuántos registros faltan por leer.
;   leer-registro → una FUNCIÓN que lee un registro (se le pasa leer-pedido o leer-pago).
; Es RECURSIVA: se llama a sí misma con un registro menos, hasta que no falte ninguno.
(define (registrar cantidad leer-registro)
  ; if → elige entre dos caminos. Forma: (if condición camino-si-es-verdad camino-si-es-falso)
  ; La condición es un (or ...): or es verdadero si AL MENOS UNA de sus partes es verdadera.
  ; Primera parte del or: (not (number? cantidad))
  ;   number? → ¿cantidad es un número?
  ;   not     → invierte la respuesta: #t pasa a #f y #f pasa a #t.
  ;   Juntas preguntan: "¿cantidad NO es un número?" (pasa si el usuario escribió letras).
  (if (or (not (number? cantidad))
          ; Segunda parte del or: <= es "menor o igual". ¿cantidad es 0 o menos?
          ;   Es decir: ¿ya no faltan registros por leer?
          ; Los 2 ")" cierran el <= y el or. Aquí termina la condición del if.
          (<= cantidad 0))
      ; Camino SI ES VERDAD (CASO BASE): devuelve '() = lista vacía. Aquí se detiene la recursión.
      '()
      ; Camino SI ES FALSO (CASO RECURSIVO):
      ; cons → pone un elemento AL INICIO de una lista: (cons 1 '(2 3)) → '(1 2 3).
      ; (leer-registro) → llama a la función recibida y lee UN registro: ese es el elemento.
      (cons (leer-registro)
            ; La lista a la que se agrega: lo que devuelva registrar con UN registro menos.
            ; (- cantidad 1) → resta 1 a cantidad.
            ; Los 4 ")" finales cierran: registrar, cons, if y define.
            (registrar (- cantidad 1) leer-registro))))


; ---------------------------------------------------------------------
; 3. CONSULTA DE CAMPOS Y SUMAS
; ---------------------------------------------------------------------

; FUNCIÓN dato: devuelve el valor de un campo de un registro.
;   registro → el pedido o pago (lista de pares).
;   campo    → el nombre del campo, por ejemplo 'cantidad.
;   Ejemplo de uso: (dato p 'cantidad) → 2
(define (dato registro campo)
  ; De adentro hacia afuera:
  ; 1. (assoc campo registro) → busca en la lista el par que EMPIEZA por campo
  ;    y lo devuelve completo: '(cantidad 2).
  ; 2. second → toma el SEGUNDO elemento de ese par: 2.
  ; Los 3 ")" cierran: assoc, second y define.
  (second (assoc campo registro)))

; FUNCIÓN valor-final: atajo para consultar el valor definitivo de un pedido ya liquidado.
(define (valor-final pedido)
  ; Es lo mismo que escribir (dato pedido 'valor-final), pero más corto.
  (dato pedido 'valor-final))

; FUNCIÓN sumar: suma un campo en toda una lista de registros.
;   Ejemplo de uso: (sumar 'despacho facturados) → total cobrado por despachos.
(define (sumar campo registros)
  ; De adentro hacia afuera:
  ; 1. (lambda (r) (dato r campo)) → una función SIN NOMBRE.
  ;    lambda = "función que recibe (r) y devuelve (dato r campo)".
  ;    Se usa lambda cuando la función se necesita una sola vez y no vale la pena nombrarla.
  ; 2. map → aplica esa función a CADA registro y arma una lista NUEVA con los resultados.
  ;    Ej: 3 pedidos → '(207900 108150 446250).
  ; 3. apply + → suma todos los números de esa lista: (apply + '(1 2 3)) = (+ 1 2 3) = 6.
  ;    Si la lista está vacía, el resultado es 0.
  (apply + (map (lambda (r) (dato r campo)) registros)))

; FUNCIÓN pesos: redondea un valor de dinero a pesos enteros.
(define (pesos valor)
  ; round → redondea al entero más cercano: 21469.6 → 21470.0.
  ;   Con un .5 exacto redondea al número PAR: 2.5 → 2.0.
  (round valor))


; ---------------------------------------------------------------------
; 4. VALIDACIÓN (detección de inconsistencias)
; ---------------------------------------------------------------------

; FUNCIÓN valor-permitido?: ¿el valor está entre las opciones definidas por la empresa?
;   valor    → lo que escribió el usuario, ej. "PSE".
;   opciones → la lista de valores permitidos, ej. medios-pago.
(define (valor-permitido? valor opciones)
  ; member → busca valor dentro de la lista opciones.
  ;   Si lo encuentra, devuelve la lista desde ese elemento hasta el final:
  ;     (member "PSE" medios-pago) → '("PSE" "Transferencia")
  ;   Si no lo encuentra, devuelve #f.
  ; El if convierte esa respuesta en #t o #f: si member encontró algo → #t; si no → #f.
  ; member distingue mayúsculas: "pse" no es igual a "PSE".
  (if (member valor opciones) #t #f))

; FUNCIÓN pedido-valido?: devuelve #t solo si el pedido p NO tiene ninguna inconsistencia.
(define (pedido-valido? p)
  ; and → es verdadero solo si TODAS sus partes son verdaderas.
  ;   Revisa las partes en orden y se DETIENE en la primera falsa (no revisa las siguientes).
  ; Parte 1: number? → ¿el número de pedido es un número? (si escribieron letras, es #f)
  (and (number? (dato p 'numero))
       ; Parte 2: > es "mayor que". ¿El número de pedido es mayor que 0?
       ;   Va DESPUÉS de number? porque comparar #f con > produce un error y detiene el programa;
       ;   si la parte 1 es falsa, and se detiene antes de llegar aquí.
       (> (dato p 'numero) 0)
       ; Parte 3: string=? → ¿dos textos son iguales? "" es el texto vacío.
       ;   (string=? cedula "") pregunta "¿la cédula está vacía?";
       ;   not lo invierte: "¿la cédula NO está vacía?".
       (not (string=? (dato p 'cedula) ""))
       ; Parte 4: ¿la cantidad es un número?
       (number? (dato p 'cantidad))
       ; Parte 5: ¿la cantidad es mayor que 0?
       (> (dato p 'cantidad) 0)
       ; Parte 6: ¿el precio es un número?
       (number? (dato p 'precio))
       ; Parte 7: ¿el precio es mayor que 0?
       (> (dato p 'precio) 0)
       ; Parte 8: ¿el inventario es un número?
       (number? (dato p 'inventario))
       ; Parte 9: >= es "mayor o igual". ¿El inventario es 0 o más? (no puede ser negativo)
       (>= (dato p 'inventario) 0)
       ; Parte 10: ¿la distancia es un número? Sin esto, el cálculo del despacho fallaría.
       (number? (dato p 'distancia))
       ; Parte 11: ¿la categoría NO está vacía?
       (not (string=? (dato p 'categoria) ""))
       ; Parte 12: ¿el medio de pago está en la lista medios-pago?
       (valor-permitido? (dato p 'medio-pago)   medios-pago)
       ; Parte 13: ¿el tipo de cliente está en la lista tipos-cliente?
       (valor-permitido? (dato p 'tipo-cliente) tipos-cliente)
       ; Parte 14: ¿el tipo de envío está en la lista tipos-envio?
       (valor-permitido? (dato p 'envio)        tipos-envio)
       ; Parte 15: ¿el estado del pago está en la lista estados-pago?
       ; Los 3 ")" finales cierran: valor-permitido?, and y define.
       (valor-permitido? (dato p 'estado-pago)  estados-pago)))


; ---------------------------------------------------------------------
; 5. DUPLICADOS (mismo número de pedido y mismo código de producto)
; ---------------------------------------------------------------------

; FUNCIÓN clave: reduce un registro a lo que lo identifica: su número y su código.
(define (clave p)
  ; Crea una lista de 2 elementos, ej. '(101 "TEC-01").
  ; Los 2 ")" finales cierran el list y el define.
  (list (dato p 'numero) (dato p 'codigo)))

; FUNCIÓN mismo-registro?: ¿los registros a y b tienen la misma clave?
(define (mismo-registro? a b)
  ; equal? → ¿dos valores tienen el mismo CONTENIDO? Sirve para comparar listas completas:
  ;   (equal? '(101 "TEC-01") '(101 "TEC-01")) → #t
  (equal? (clave a) (clave b)))

; FUNCIÓN copias-de: devuelve los registros de la lista que tienen la misma clave que p.
(define (copias-de p lista)
  ; filter → recorre la lista y deja SOLO los elementos para los que la función da verdadero.
  ;   Devuelve una lista NUEVA; la original no cambia.
  ; (lambda (otro) (mismo-registro? otro p)) → "¿este elemento (otro) tiene la misma clave que p?"
  (filter (lambda (otro) (mismo-registro? otro p)) lista))

; FUNCIÓN sin-copias-de: devuelve los registros de la lista con clave DISTINTA a la de p.
(define (sin-copias-de p lista)
  ; Igual que copias-de, pero con not: deja los que NO tienen la misma clave.
  (filter (lambda (otro) (not (mismo-registro? otro p))) lista))

; FUNCIÓN registros-unicos: deja un solo registro por clave (conserva el primero que llegó).
; Es recursiva.
(define (registros-unicos pedidos)
  ; null? → ¿la lista está vacía?
  (if (null? pedidos)
      ; Si está vacía (CASO BASE): devuelve la lista vacía.
      '()
      ; Si no está vacía (CASO RECURSIVO): cons pone al inicio...
      ; car → el PRIMER elemento de la lista (el primer registro). Este se conserva.
      (cons (car pedidos)
            ; ...el resultado de procesar el resto:
            ; cdr → la lista SIN su primer elemento.
            ; (sin-copias-de (car pedidos) (cdr pedidos)) → el resto, quitando las copias del primero.
            ; registros-unicos se llama a sí misma con esa lista más corta.
            ; Los ")" finales cierran: cdr, sin-copias-de, registros-unicos, cons, if y define.
            (registros-unicos (sin-copias-de (car pedidos) (cdr pedidos))))))

; FUNCIÓN registros-repetidos: devuelve las copias que se descartaron. Es recursiva.
(define (registros-repetidos pedidos)
  ; ¿La lista está vacía?
  (if (null? pedidos)
      ; Sí (CASO BASE): no hay copias; lista vacía.
      '()
      ; No (CASO RECURSIVO):
      ; append → une dos listas en una sola: (append '(1 2) '(3)) → '(1 2 3).
      ; Primera lista: las copias del primer registro dentro del resto.
      (append (copias-de (car pedidos) (cdr pedidos))
              ; Segunda lista: las copias que se encuentren en el resto, ya sin las del primero.
              ; Los ")" finales cierran: cdr, sin-copias-de, registros-repetidos, append, if y define.
              (registros-repetidos (sin-copias-de (car pedidos) (cdr pedidos))))))


; ---------------------------------------------------------------------
; 6. CONDICIONES COMERCIALES
; ---------------------------------------------------------------------

; FUNCIÓN pago-aprobado?: ¿el estado del pago es exactamente "Aprobado"?
(define (pago-aprobado? p)
  ; string=? compara los dos textos y devuelve #t o #f.
  (string=? (dato p 'estado-pago) "Aprobado"))

; FUNCIÓN inventario-suficiente?: ¿hay unidades para despachar TODO el pedido?
(define (inventario-suficiente? p)
  ; ¿inventario >= cantidad? No se permiten despachos parciales:
  ;   inventario 2 y cantidad 4 → #f (no se despachan 2 de 4).
  (>= (dato p 'inventario) (dato p 'cantidad)))

; FUNCIÓN facturable?: el pedido se puede facturar si el pago está aprobado Y hay inventario.
(define (facturable? p)
  ; and: las dos condiciones deben ser verdaderas.
  (and (pago-aprobado? p) (inventario-suficiente? p)))

; FUNCIÓN rechazado-por-inventario?: pago aprobado pero SIN inventario suficiente.
(define (rechazado-por-inventario? p)
  ; and: el pago está aprobado y NO (not) hay inventario suficiente.
  (and (pago-aprobado? p) (not (inventario-suficiente? p))))


; ---------------------------------------------------------------------
; 7. LIQUIDACIÓN DE UN PEDIDO
; ---------------------------------------------------------------------

; FUNCIÓN descuento-adicional: 3 % extra si el subtotal es de $1.000.000 o más.
(define (descuento-adicional subtotal)
  ; ¿El subtotal es mayor o igual a 1000000?
  (if (>= subtotal 1000000)
      ; Sí: el descuento es subtotal × 3/100 (3 %). Ej: 3000000 × 3/100 = 90000.
      (* subtotal 3/100)
      ; No: no hay descuento adicional.
      ; Los 2 ")" cierran el if y el define.
      0))

; FUNCIÓN costo-despacho: tarifa según la distancia, con recargo si el envío es Express.
(define (costo-despacho distancia envio)
  ; let* → crea nombres LOCALES: solo existen dentro de esta función.
  ;   Forma: (let* ([nombre1 valor1] [nombre2 valor2] ...) cuerpo)
  ;   Aquí crea un solo nombre: tarifa. Su valor lo calcula el cond.
  ; cond → elige entre VARIOS casos. Cada caso tiene la forma [condición resultado].
  ;   Revisa los casos en orden y usa el PRIMERO cuya condición sea verdadera.
  (let* ([tarifa (cond
                   ; Caso 1: si la distancia es 10 km o menos → 8000.
                   [(<= distancia 10) 8000]
                   ; Caso 2: solo se revisa si el caso 1 fue falso (más de 10 km).
                   ;   Si la distancia es 30 km o menos → 15000.
                   [(<= distancia 30) 15000]
                   ; else → "en cualquier otro caso" (más de 30 km). De adentro hacia afuera:
                   ;   (- distancia 30)     → kilómetros por encima de 30. Ej: 40 − 30 = 10.
                   ;   (* 1000 ...)         → $1.000 por cada uno: 10000.
                   ;   (+ 25000 ...)        → más los $25.000 base: 35000.
                   ; Al final, "])])" : ] cierra el caso else, ) cierra el cond,
                   ;   ] cierra [tarifa ...] y ) cierra la lista de nombres del let*.
                   [else (+ 25000 (* 1000 (- distancia 30)))])])
    ; Cuerpo del let* (lo que se calcula usando tarifa): ¿el envío es "Express"?
    (if (string=? envio "Express")
        ; Sí: tarifa × 140/100 = tarifa + 40 %. Ej: 35000 → 49000.
        (* tarifa 140/100)
        ; No: la tarifa sin recargo.
        ; Los 3 ")" finales cierran: if, let* y define.
        tarifa)))

; FUNCIÓN tasa-impuesto: 5 % para la categoría "Alimentos" y 19 % para todas las demás.
(define (tasa-impuesto categoria)
  ; if: si la categoría es "Alimentos" devuelve 5/100; si no, 19/100.
  (if (string=? categoria "Alimentos") 5/100 19/100))

; FUNCIÓN liquidar: calcula todos los valores de un pedido.
; Devuelve un registro NUEVO: el pedido original + 7 campos calculados.
; Ejemplo de referencia: pedido 101 (Premium, Express, 40 km, Tecnología, 2 × 1500000).
(define (liquidar p)
  ; let* crea 7 nombres locales EN ORDEN; cada uno puede usar los anteriores.
  ; subtotal = cantidad × precio. Ej: 2 × 1500000 = 3000000.
  (let* ([subtotal        (* (dato p 'cantidad) (dato p 'precio))]
         ; desc-cliente, de adentro hacia afuera:
         ;   (dato p 'tipo-cliente) → ej. "Premium".
         ;   hash-ref → busca esa clave en el diccionario descuento-por-tipo → 10/100.
         ;   (* subtotal ...)       → 3000000 × 10/100 = 300000.
         ;   pesos                  → redondea a pesos enteros.
         [desc-cliente    (pesos (* subtotal (hash-ref descuento-por-tipo (dato p 'tipo-cliente))))]
         ; desc-adicional: 3 % si el subtotal es >= 1000000; si no, 0. Ej: 90000.
         ;   Se calcula sobre el subtotal ORIGINAL, igual que desc-cliente.
         [desc-adicional  (pesos (descuento-adicional subtotal))]
         ; valor-comercial = subtotal − desc-cliente − desc-adicional.
         ;   (- a b c) resta b y luego c a a: 3000000 − 300000 − 90000 = 2610000.
         [valor-comercial (- subtotal desc-cliente desc-adicional)]
         ; despacho: costo según distancia y tipo de envío, redondeado. Ej: 49000.
         [despacho        (pesos (costo-despacho (dato p 'distancia) (dato p 'envio)))]
         ; impuesto (esta línea y la siguiente forman UNA sola orden):
         ;   (+ valor-comercial despacho) → la base del impuesto: 2610000 + 49000 = 2659000.
         ;   (* base tasa)                → base × tasa de la categoría.
         [impuesto        (pesos (* (+ valor-comercial despacho)
                                    ; tasa-impuesto → 19/100 (o 5/100 si es Alimentos).
                                    ;   2659000 × 19/100 = 505210.
                                    ; "))))]" cierra: dato, tasa-impuesto, *, pesos y el par [impuesto ...].
                                    (tasa-impuesto (dato p 'categoria))))]
         ; total = valor comercial + despacho + impuesto = 2610000 + 49000 + 505210 = 3164210.
         ; "])" : ] cierra este par y ) cierra la lista de nombres del let*.
         [total           (+ valor-comercial despacho impuesto)])
    ; Cuerpo del let*.
    ; append → une dos listas: p (los 15 pares del pedido) + una lista con 7 pares nuevos.
    ;   Resultado: un registro de 22 pares. p NO se modifica; append crea una lista nueva.
    (append p (list (list 'subtotal            subtotal)
                    ; Cada línea es un par nuevo (nombre-del-campo valor-calculado).
                    (list 'descuento-cliente   desc-cliente)
                    ; Par del descuento adicional.
                    (list 'descuento-adicional desc-adicional)
                    ; Par del valor comercial.
                    (list 'valor-comercial     valor-comercial)
                    ; Par del despacho.
                    (list 'despacho            despacho)
                    ; Par del impuesto.
                    (list 'impuesto            impuesto)
                    ; Par del valor definitivo.
                    ; Los 5 ")" finales cierran: el par, la lista de pares nuevos, append, let* y define.
                    (list 'valor-final         total)))))


; ---------------------------------------------------------------------
; 8. ORDENAMIENTO Y AGRUPACIÓN
; ---------------------------------------------------------------------

; FUNCIÓN ordenar-por-valor: ordena los pedidos de MAYOR a MENOR valor definitivo.
(define (ordenar-por-valor pedidos)
  ; sort → ordena una lista. Recibe la lista y una función que compara dos elementos.
  ;   (lambda (a b) ...) responde "¿a debe ir antes que b?".
  ;   (> (valor-final a) (valor-final b)) → sí, si a vale más que b. Por eso queda de mayor a menor.
  ; Devuelve una lista NUEVA ordenada; la original no cambia.
  ; Los ")" finales cierran: valor-final, >, lambda, sort y define.
  (sort pedidos (lambda (a b) (> (valor-final a) (valor-final b)))))

; FUNCIÓN primeros: devuelve los primeros n elementos de una lista. Es recursiva.
(define (primeros n lista)
  ; = → ¿dos números son iguales? La condición es: ¿ya se tomaron n (n llegó a 0)
  ;   O (or) la lista se acabó?
  (if (or (= n 0) (null? lista))
      ; Si es así (CASO BASE): lista vacía.
      '()
      ; Si no: pone el primer elemento (car) al inicio de los primeros (n − 1) del resto (cdr).
      ; Los ")" finales cierran: cdr, primeros, cons, if y define.
      (cons (car lista) (primeros (- n 1) (cdr lista)))))

; FUNCIÓN sin-repetir: deja cada valor una sola vez. Ej: '("Med" "Bog" "Med") → '("Bog" "Med").
(define (sin-repetir valores)
  ; cond con 3 casos, revisados en orden.
  (cond
    ; Caso 1: si la lista está vacía → lista vacía.
    [(null? valores) '()]
    ; Caso 2: ¿el primer valor (car) vuelve a aparecer en el resto (cdr)?
    [(member (car valores) (cdr valores))
     ; Sí: se salta esta aparición y se sigue con el resto (la otra aparición se conservará después).
     (sin-repetir (cdr valores))]
    ; Caso 3 (else): no se repite → se conserva al inicio y se sigue con el resto.
    ; Al final, "]))" : ] cierra el caso else, ) cierra el cond, ) cierra el define.
    [else (cons (car valores) (sin-repetir (cdr valores)))]))

; FUNCIÓN resumen-por: agrupa los pedidos y devuelve UNA FILA por grupo.
;   campo   → por qué se agrupa, ej. 'ciudad.
;   medida  → qué se suma en cada grupo, ej. 'valor-final o 'cantidad.
;   pedidos → la lista de pedidos.
;   Resultado ej: '(("Medellín" 3 5132225) ("Bogotá" 3 762300))
;                  cada fila = (valor  cantidad-de-pedidos  total)
; Conviene leerla empezando por su ÚLTIMA línea, que es la lista que recorre el map.
(define (resumen-por campo medida pedidos)
  ; map aplica la lambda a cada valor distinto del campo (esa lista está en la última línea).
  ; (lambda (valor) ...) → función sin nombre; valor será "Medellín", luego "Bogotá", etc.
  (map (lambda (valor)
         ; let* crea el nombre grupo:
         ;   filter deja solo los pedidos cuyo campo es igual a valor.
         ;   (lambda (p) (equal? (dato p campo) valor)) → "¿el campo de p es igual a valor?"
         ;   Ej: valor = "Medellín" → grupo = los 3 pedidos de Medellín.
         ; Al final, "])" : ] cierra [grupo ...] y ) cierra la lista de nombres del let*.
         (let* ([grupo (filter (lambda (p) (equal? (dato p campo) valor)) pedidos)])
           ; Cuerpo del let*: arma la fila (valor cantidad total):
           ;   length → cuántos elementos tiene una lista (cuántos pedidos hay en el grupo).
           ;   (sumar medida grupo) → suma la medida dentro del grupo.
           ; Los ")" finales cierran: sumar, list, let* y lambda.
           (list valor (length grupo) (sumar medida grupo))))
       ; Segundo dato del map: la lista de valores distintos del campo.
       ;   (map (lambda (p) (dato p campo)) pedidos) → el campo de cada pedido,
       ;     ej. '("Medellín" "Medellín" "Medellín" "Bogotá" "Bogotá" "Bogotá").
       ;   sin-repetir → deja cada uno una vez: '("Medellín" "Bogotá").
       ; Los 4 ")" finales cierran: el map interno, sin-repetir, el map externo y el define.
       (sin-repetir (map (lambda (p) (dato p campo)) pedidos))))

; FUNCIÓN fila-mayor: de las filas de un resumen, devuelve la que tiene el mayor total.
(define (fila-mayor filas)
  ; let* crea el nombre mayor, de adentro hacia afuera:
  ;   third → el TERCER elemento de una lista (en cada fila, el total).
  ;   (map third filas) → los totales de todas las filas: '(3164210 1113840 1616475).
  ;   max → el mayor de VARIOS números sueltos. NO acepta una lista: (max '(1 2)) da error.
  ;   apply max → le entrega los números de la lista como sueltos: (max 3164210 1113840 1616475).
  (let* ([mayor (apply max (map third filas))])
    ; filter → deja las filas cuyo total es igual (=) al mayor.
    ; first  → toma la primera de ellas (si hay empate, la primera).
    ; Los 4 ")" finales cierran: filter, first, let* y define.
    (first (filter (lambda (fila) (= (third fila) mayor)) filas))))


; ---------------------------------------------------------------------
; 9. CONCILIACIÓN DE PAGOS
; ---------------------------------------------------------------------

; FUNCIÓN estado-conciliacion: devuelve el estado de un pago como texto.
;   recibido → dinero que llegó.   esperado → valor facturado.
;   lineas   → los pedidos facturados con ese número (puede estar vacía).
(define (estado-conciliacion recibido esperado lineas)
  ; cond: se usa el primer caso verdadero. El orden importa.
  (cond
    ; Caso 1: si lo recibido no es un número, no se puede comparar.
    [(not (number? recibido)) "Valor inválido"]
    ; Caso 2: no existe un pedido facturado con ese número.
    [(null? lineas)           "Sin pedido facturado"]
    ; Caso 3: lo recibido es igual a lo esperado.
    [(= recibido esperado)    "Conciliado"]
    ; Caso 4: < es "menor que". Llegó menos de lo esperado.
    [(< recibido esperado)    "Saldo pendiente"]
    ; Caso 5 (else): llegó más de lo esperado.
    ; Al final, "]))" : ] cierra el caso, ) el cond, ) el define.
    [else                     "Excedente"]))

; FUNCIÓN conciliar: compara UN pago con la facturación.
; Devuelve un registro NUEVO: el pago + esperado, estado y diferencia.
(define (conciliar pago facturados)
  ; let* crea 5 nombres en orden.
  ; lineas: filter deja los facturados cuyo número de pedido es igual (equal?) al del pago.
  ;   Pueden ser varias líneas si el pedido tiene varios productos.
  ;   Se usa equal? y no = porque = da error si alguno de los dos no es un número.
  (let* ([lineas     (filter (lambda (p) (equal? (dato p 'numero) (dato pago 'numero))) facturados)]
         ; esperado: la suma de los valores finales de esas líneas.
         [esperado   (sumar 'valor-final lineas)]
         ; recibido: el valor que trae el pago.
         [recibido   (dato pago 'valor)]
         ; estado: el texto que devuelve estado-conciliacion.
         [estado     (estado-conciliacion recibido esperado lineas)]
         ; diferencia: si lo recibido es un número...
         [diferencia (if (number? recibido)
                         ; ...abs da el valor absoluto (siempre positivo) de la resta:
                         ;   (abs (- 300000 316050)) → (abs -16050) → 16050.
                         (abs (- recibido esperado))
                         ; ...si no es un número, la diferencia queda en 0.
                         ; Al final, ")])" : ) cierra el if, ] cierra [diferencia ...],
                         ;   ) cierra la lista de nombres del let*.
                         0)])
    ; Cuerpo del let*: append une el pago con 3 pares nuevos.
    (append pago (list (list 'esperado   esperado)
                       ; Par del estado.
                       (list 'estado     estado)
                       ; Par de la diferencia.
                       ; Los 5 ")" finales cierran: el par, la lista de pares, append, let* y define.
                       (list 'diferencia diferencia)))))

; FUNCIÓN con-estado: de los resultados de conciliación, deja los que tienen cierto estado.
;   Ejemplo de uso: (con-estado "Conciliado" resultados-pagos)
(define (con-estado estado resultados)
  ; filter con una lambda que pregunta si el estado de r es igual al buscado.
  (filter (lambda (r) (string=? (dato r 'estado) estado)) resultados))


; ---------------------------------------------------------------------
; 10. VERIFICACIONES Y UTILIDADES DEL INFORME
; ---------------------------------------------------------------------

; FUNCIÓN datos-consistentes?: comprobación final de un pedido facturado.
(define (datos-consistentes? p)
  ; and: todas las partes deben ser verdaderas.
  ; ¿El subtotal es mayor que 0?
  (and (> (dato p 'subtotal) 0)
       ; ¿El valor comercial es mayor que 0?
       (> (dato p 'valor-comercial) 0)
       ; ¿El despacho es mayor que 0?
       (> (dato p 'despacho) 0)
       ; ¿El impuesto es mayor que 0?
       (> (dato p 'impuesto) 0)
       ; ¿El valor final es mayor que 0?
       (> (valor-final p) 0)
       ; ¿La distancia es 0 o más?
       (>= (dato p 'distancia) 0)
       ; ¿Sigue cumpliendo todas las validaciones del pedido?
       (pedido-valido? p)
       ; ¿Sigue cumpliendo las condiciones para facturarse?
       ; Los 3 ")" finales cierran: facturable?, and y define.
       (facturable? p)))

; FUNCIÓN premium-express-alto?: ¿es Premium, con envío Express y valor final > $2.000.000?
(define (premium-express-alto? p)
  ; ¿El tipo de cliente es "Premium"?
  (and (string=? (dato p 'tipo-cliente) "Premium")
       ; ¿El envío es "Express"?
       (string=? (dato p 'envio) "Express")
       ; ¿El valor final es mayor que 2000000?
       (> (valor-final p) 2000000)))

; FUNCIÓN todos-cumplen?: ¿TODOS los elementos de la lista cumplen la condición?
;   condicion → una función que responde #t o #f (ej. datos-consistentes?).
(define (todos-cumplen? condicion lista)
  ; Compara dos números con =:
  ;   (length (filter condicion lista)) → cuántos cumplen.
  ;   (length lista)                    → cuántos hay en total.
  ;   Si son iguales, todos cumplen. Con una lista vacía da #t (0 = 0).
  (= (length (filter condicion lista)) (length lista)))

; FUNCIÓN alguno-cumple?: ¿AL MENOS UNO cumple la condición?
(define (alguno-cumple? condicion lista)
  ; filter deja los que cumplen; null? pregunta si quedó vacía; not lo invierte:
  ;   "¿la lista de los que cumplen NO está vacía?"
  (not (null? (filter condicion lista))))

; FUNCIÓN porcentaje: qué porcentaje es parte de total, con 2 decimales.
(define (porcentaje parte total)
  ; zero? → ¿el número es 0? Si total es 0 no se puede dividir.
  (if (zero? total)
      ; Si total es 0: el porcentaje es 0.
      0
      ; Si no, de adentro hacia afuera (ej. parte 6, total 12):
      ;   (/ parte total)   → 6/12 = 1/2 (fracción exacta).
      ;   (* 10000 ...)     → 5000.   (Multiplicar por 10000 = ×100 del porcentaje y ×100 de los 2 decimales.)
      ;   round             → redondea al entero más cercano.
      ;   (/ ... 100)       → 50 (deshace el ×100 de los decimales).
      ;   exact->inexact    → convierte la fracción exacta en decimal para mostrarla: 50.0.
      ; Los 4 ")" finales cierran: la división entre 100, exact->inexact, if y define.
      (exact->inexact (/ (round (* 10000 (/ parte total))) 100))))

; FUNCIÓN si-no: convierte #t en "Sí" y #f en "No" para el informe.
(define (si-no condicion)
  ; Si condicion es verdadera devuelve "Sí"; si no, "No".
  (if condicion "Sí" "No"))

; FUNCIÓN titulo: imprime el encabezado de una sección del informe.
(define (titulo texto)
  ; string-append → une varios textos en uno solo:
  ;   "\n========== " + "1. REGISTROS RECIBIDOS" + " =========="
  ; displayln muestra el resultado y baja de línea.
  (displayln (string-append "\n========== " texto " ==========")))

; FUNCIÓN mostrar-referencia: imprime una línea corta que identifica un pedido.
(define (mostrar-referencia p)
  ; printf → imprime un texto reemplazando cada ~a por los valores que siguen, en orden.
  ;   Hay 3 ~a: el 1.º se reemplaza por el número, el 2.º por el código y el 3.º por el nombre.
  ;   \n al final baja de línea.
  (printf "  - Pedido ~a | Producto ~a | Cliente: ~a\n"
          ; Los 3 valores, en el orden de los ~a. Los 2 ")" finales cierran printf y define.
          (dato p 'numero) (dato p 'codigo) (dato p 'nombre)))

; FUNCIÓN mostrar-referencias: imprime una línea por cada pedido de la lista.
(define (mostrar-referencias pedidos)
  ; ¿La lista está vacía?
  (if (null? pedidos)
      ; Sí: imprime "(ninguno)". Los paréntesis dentro del texto son solo caracteres.
      (displayln "  (ninguno)")
      ; No: for-each aplica mostrar-referencia a CADA pedido.
      ;   for-each sirve para ACCIONES (imprimir); a diferencia de map, no arma una lista.
      ;   mostrar-referencia va SIN paréntesis: se entrega la función, no se ejecuta aquí.
      (for-each mostrar-referencia pedidos)))

; FUNCIÓN mostrar-liquidacion: imprime el detalle completo de un pedido facturado.
; Tiene varios printf seguidos; se ejecutan en orden, de arriba abajo.
(define (mostrar-liquidacion p)
  ; Línea 1 del detalle: 4 ~a → número, nombre, cédula y ciudad.
  (printf "\nPedido ~a | Cliente: ~a (CC ~a) | Ciudad: ~a\n"
          ; Valores de los 4 ~a, en orden.
          (dato p 'numero) (dato p 'nombre) (dato p 'cedula) (dato p 'ciudad))
  ; Línea 2: 5 ~a → producto, código, categoría, cantidad y precio. "$" se imprime tal cual.
  (printf "  Producto: ~a [~a] | Categoría: ~a | ~a unidad(es) x $~a\n"
          ; Valores de los 5 ~a.
          (dato p 'producto) (dato p 'codigo) (dato p 'categoria) (dato p 'cantidad) (dato p 'precio))
  ; Línea 3: 4 ~a → tipo de cliente, medio de pago, tipo de envío y distancia.
  (printf "  Cliente ~a | Pago: ~a | Envío ~a a ~a km\n"
          ; Valores de los 4 ~a.
          (dato p 'tipo-cliente) (dato p 'medio-pago) (dato p 'envio) (dato p 'distancia))
  ; Línea 4: 3 ~a → subtotal y los dos descuentos.
  (printf "  Subtotal: $~a | Descuento cliente: $~a | Descuento adicional: $~a\n"
          ; Valores de los 3 ~a.
          (dato p 'subtotal) (dato p 'descuento-cliente) (dato p 'descuento-adicional))
  ; Línea 5: 3 ~a → valor comercial, despacho e impuesto.
  (printf "  Valor comercial: $~a | Despacho: $~a | Impuesto: $~a\n"
          ; Valores de los 3 ~a.
          (dato p 'valor-comercial) (dato p 'despacho) (dato p 'impuesto))
  ; Línea 6: el valor definitivo. Los 3 ")" finales cierran: valor-final, printf y define.
  (printf "  VALOR DEFINITIVO: $~a\n" (valor-final p)))

; FUNCIÓN mostrar-resumen: imprime un resumen con una línea por fila.
;   nombre   → título del resumen.
;   filas    → lo que devuelve resumen-por.
;   etiqueta → texto antes del total: "total: $" (dinero) o "unidades: ".
(define (mostrar-resumen nombre filas etiqueta)
  ; Imprime el título seguido de ":".
  (printf "\n~a:\n" nombre)
  ; for-each recorre las filas; la lambda imprime cada una.
  (for-each (lambda (fila)
              ; 4 ~a: valor (first), cantidad de pedidos (second), etiqueta y total (third).
              ;   "~a~a" juntos: la etiqueta queda pegada al total → "total: $5132225".
              (printf "  ~a | pedidos: ~a | ~a~a\n" (first fila) (second fila) etiqueta (third fila)))
            ; Lista que recorre for-each. Los 2 ")" cierran for-each y define.
            filas))

; FUNCIÓN mostrar-pago: imprime el resultado de conciliación de un pago.
(define (mostrar-pago r)
  ; 5 ~a: número, recibido, esperado, estado y diferencia.
  (printf "  Pedido ~a | recibido: $~a | esperado: $~a | ~a | diferencia: $~a\n"
          ; Valores de los 5 ~a, en orden.
          (dato r 'numero) (dato r 'valor) (dato r 'esperado) (dato r 'estado) (dato r 'diferencia)))


; =====================================================================
;                         PROGRAMA PRINCIPAL
; =====================================================================
; Hasta aquí solo se DEFINIERON funciones; ninguna se había ejecutado.
; Desde aquí el programa se ejecuta de arriba abajo, en orden.

; ---------- ENTRADA (la cantidad se conoce solo en ejecución) ----------

; Muestra el título de la entrada de pedidos.
(displayln "REGISTRO DE PEDIDOS")
; Crea registros: la lista con TODOS los pedidos digitados. Nunca se modifica.
(define registros
  ; registrar recibe 2 datos:
  ;   1. (leer-numero "...") → pregunta cuántos pedidos hay; ese número es la cantidad.
  ;   2. leer-pedido → SIN paréntesis: se entrega la función misma para que registrar la use.
  ;      Con paréntesis, (leer-pedido), se ejecutaría aquí una sola vez.
  ; Los 2 ")" finales cierran registrar y define.
  (registrar (leer-numero "Cantidad de pedidos a registrar: ") leer-pedido))

; Título de la entrada de pagos, con una línea en blanco antes.
(displayln "\nREGISTRO DE PAGOS")
; Crea pagos: la lista con todos los pagos digitados.
(define pagos
  ; Igual que arriba, pero entregando la función leer-pago.
  (registrar (leer-numero "Cantidad de pagos a registrar: ") leer-pago))

; ---------- PROCESAMIENTO (cada paso crea una lista nueva) ----------

; validos: filter deja los registros para los que pedido-valido? responde #t.
(define validos      (filter pedido-valido? registros))
; invalidos: los registros para los que pedido-valido? responde #f (not lo invierte).
(define invalidos    (filter (lambda (p) (not (pedido-valido? p))) registros))
; unicos: los válidos, dejando un solo registro por clave (número + código).
(define unicos       (registros-unicos validos))
; repetidos: las copias que se descartaron.
(define repetidos    (registros-repetidos validos))
; rechazados: de los únicos, los que tienen pago aprobado pero no tienen inventario.
(define rechazados   (filter rechazado-por-inventario? unicos))
; no-aprobados: de los únicos, los que tienen pago Pendiente o Rechazado.
(define no-aprobados (filter (lambda (p) (not (pago-aprobado? p))) unicos))
; facturados, de adentro hacia afuera:
;   (filter facturable? unicos) → los que se pueden facturar.
;   (map liquidar ...)          → a cada uno le calcula sus valores.
;   ordenar-por-valor           → los ordena de mayor a menor valor final.
(define facturados   (ordenar-por-valor (map liquidar (filter facturable? unicos))))
; resultados-pagos: map aplica conciliar a cada pago, comparándolo con los facturados.
(define resultados-pagos (map (lambda (pago) (conciliar pago facturados)) pagos))

; ---------- INFORME CONSOLIDADO ----------

; Encabezado de la sección 1.
(titulo "1. REGISTROS RECIBIDOS")
; length → cuántos elementos tiene la lista. ~a se reemplaza por ese número.
(printf "Registros recibidos: ~a\n" (length registros))
; Cuántos tienen inconsistencias.
(printf "  Con inconsistencias: ~a\n" (length invalidos))
; Cuántas copias duplicadas se descartaron.
(printf "  Duplicados descartados: ~a\n" (length repetidos))
; Cuántos se rechazaron por inventario.
(printf "  Rechazados por inventario: ~a\n" (length rechazados))
; Cuántos no se procesaron por el estado del pago.
(printf "  Con pago Pendiente o Rechazado: ~a\n" (length no-aprobados))
; Cuántos se facturaron.
(printf "  Facturados: ~a\n" (length facturados))

; Encabezado de la sección 2.
(titulo "2. INCONSISTENCIAS")
; Imprime una línea por cada registro inválido (o "(ninguno)").
(mostrar-referencias invalidos)

; Encabezado de la sección 3.
(titulo "3. DUPLICADOS")
; Cantidad de copias encontradas.
(printf "Registros repetidos encontrados: ~a\n" (length repetidos))
; Una línea por cada copia.
(mostrar-referencias repetidos)
; Cantidad de registros únicos que siguen en el proceso.
(printf "Registros únicos para procesar: ~a\n" (length unicos))

; Encabezado de la sección 4.
(titulo "4. PEDIDOS RECHAZADOS POR INVENTARIO")
; Una línea por cada rechazado por inventario.
(mostrar-referencias rechazados)
; Subtítulo.
(displayln "No procesados por pago Pendiente o Rechazado:")
; Una línea por cada pedido con pago no aprobado.
(mostrar-referencias no-aprobados)

; Encabezado de la sección 5.
(titulo "5. PEDIDOS FACTURADOS (de mayor a menor valor)")
; ¿No hay facturados?
(if (null? facturados)
    ; Sí: se avisa.
    (displayln "No hay pedidos facturados.")
    ; No: for-each imprime el detalle de cada facturado (ya vienen ordenados).
    (for-each mostrar-liquidacion facturados))

; Encabezado de la sección 6.
(titulo "6. VALORES ECONÓMICOS")
; Suma de los subtotales.
(printf "Total bruto antes de descuentos: $~a\n" (sumar 'subtotal facturados))
; Total descontado = suma de descuentos por cliente + suma de descuentos adicionales.
(printf "Total descontado: $~a\n" (+ (sumar 'descuento-cliente facturados)
                                   ; Segundo número del +. Los 3 ")" cierran sumar, + y printf.
                                   (sumar 'descuento-adicional facturados)))
; Suma de los despachos.
(printf "Total cobrado por despachos: $~a\n" (sumar 'despacho facturados))
; Suma de los impuestos.
(printf "Total generado en impuestos: $~a\n" (sumar 'impuesto facturados))
; Suma de los valores definitivos.
(printf "Total definitivo facturado: $~a\n" (sumar 'valor-final facturados))

; ¿No hay facturados? (sin pedidos no existe mayor, menor ni promedio, y se dividiría por 0)
(if (null? facturados)
    ; Sí: se avisa.
    (displayln "Sin pedidos facturados: no hay mayor, menor ni promedio.")
    ; No: let* crea 4 nombres y luego imprime.
    ; mayor: first toma el primero; como la lista va de mayor a menor, es el de mayor valor.
    (let* ([mayor          (first facturados)]
           ; menor: reverse invierte la lista (el último pasa a ser el primero); first lo toma.
           [menor          (first (reverse facturados))]
           ; promedio: total facturado dividido (/) entre la cantidad de facturados.
           [promedio       (/ (sumar 'valor-final facturados) (length facturados))]
           ; sobre-promedio: los facturados cuyo valor final es mayor (>) que el promedio.
           ; Al final, "])" : ] cierra este par y ) cierra la lista de nombres del let*.
           [sobre-promedio (filter (lambda (p) (> (valor-final p) promedio)) facturados)])
      ; Imprime número y valor del mayor.
      (printf "Pedido de mayor valor: ~a ($~a)\n" (dato mayor 'numero) (valor-final mayor))
      ; Imprime número y valor del menor.
      (printf "Pedido de menor valor: ~a ($~a)\n" (dato menor 'numero) (valor-final menor))
      ; Imprime el promedio redondeado a pesos.
      (printf "Promedio por pedido facturado: $~a\n" (pesos promedio))
      ; Subtítulo.
      (displayln "Pedidos por encima del promedio:")
      ; Una línea por cada pedido sobre el promedio.
      ; Los 3 ")" finales cierran: mostrar-referencias, let* e if.
      (mostrar-referencias sobre-promedio)))

; Subtítulo del top 5.
(displayln "\nCinco pedidos de mayor valor:")
; ¿Hay 5 o más facturados?
(if (>= (length facturados) 5)
    ; Sí: let* crea top = los 5 primeros (los de mayor valor, porque la lista está ordenada).
    (let* ([top (primeros 5 facturados)])
      ; for → repite el bloque varias veces.
      ;   [i (in-range (length top))] → i toma los valores 0, 1, 2, 3, 4.
      ;   in-range n → los números desde 0 hasta n − 1.
      (for ([i (in-range (length top))])
        ; Imprime una línea con 4 ~a.
        (printf "  ~a. Pedido ~a | ~a | $~a\n"
                ; 1.er ~a: i + 1, para numerar desde 1 y no desde 0.
                (+ i 1)
                ; 2.º ~a: list-ref → el elemento en la posición i de la lista (se cuenta desde 0).
                ;   De ese pedido se toma el número.
                (dato (list-ref top i) 'numero)
                ; 3.er ~a: el nombre del cliente de ese pedido.
                (dato (list-ref top i) 'nombre)
                ; 4.º ~a: el valor final de ese pedido.
                ; Los ")" finales cierran: list-ref, valor-final, printf, for y let*.
                (valor-final (list-ref top i)))))
    ; No hay 5: se avisa. Los 2 ")" cierran displayln e if.
    (displayln "  Se requieren al menos cinco pedidos facturados."))

; Encabezado de la sección 7.
(titulo "7. RESÚMENES POR AGRUPACIÓN")
; Resumen por ciudad: 3 datos → título, filas agrupadas por 'ciudad sumando 'valor-final, etiqueta.
(mostrar-resumen "Facturación por ciudad"
                 ; Filas del resumen y etiqueta. El ")" final cierra mostrar-resumen.
                 (resumen-por 'ciudad 'valor-final facturados) "total: $")
; Resumen por categoría.
(mostrar-resumen "Facturación por categoría"
                 ; Agrupa por 'categoria.
                 (resumen-por 'categoria 'valor-final facturados) "total: $")
; Resumen por tipo de cliente.
(mostrar-resumen "Facturación por tipo de cliente"
                 ; Agrupa por 'tipo-cliente.
                 (resumen-por 'tipo-cliente 'valor-final facturados) "total: $")
; Resumen por medio de pago (la columna "pedidos" responde cuántos se procesaron con cada medio).
(mostrar-resumen "Pedidos procesados por medio de pago"
                 ; Agrupa por 'medio-pago.
                 (resumen-por 'medio-pago 'valor-final facturados) "total: $")
; Unidades a descontar del inventario por código de producto.
(mostrar-resumen "Unidades a descontar del inventario por código"
                 ; Agrupa por 'codigo y suma 'cantidad (unidades), no dinero.
                 (resumen-por 'codigo 'cantidad facturados) "unidades: ")

; ¿No hay facturados? (fila-mayor fallaría con una lista vacía)
(if (null? facturados)
    ; Sí: se avisa.
    (displayln "\nSin datos para categoría y cliente destacados.")
    ; No: let* crea 3 nombres.
    ; categoria: la fila de mayor total del resumen por categoría, ej. '("Tecnología" 1 3164210).
    (let* ([categoria (fila-mayor (resumen-por 'categoria 'valor-final facturados))]
           ; cliente: la fila de mayor total del resumen por CÉDULA, ej. '("1001" 2 3831800).
           ;   Se agrupa por cédula porque una misma cédula puede aparecer en varios pedidos.
           [cliente   (fila-mayor (resumen-por 'cedula 'valor-final facturados))]
           ; nombre: el nombre de ese cliente, de adentro hacia afuera:
           ;   (first cliente) → la cédula (primer elemento de la fila).
           ;   filter → los facturados con esa cédula.   first → el primero de ellos.
           [nombre    (dato (first (filter (lambda (p) (equal? (dato p 'cedula) (first cliente)))
                                           ; Lista que recorre el filter. Los 2 ")" cierran filter y first.
                                           facturados))
                            ; Campo que se pide a dato. Al final: ) cierra dato, ] cierra [nombre ...],
                            ;   ) cierra la lista de nombres del let*.
                            'nombre)])
      ; Imprime la categoría: first = nombre de la categoría, third = total.
      (printf "\nCategoría con mayor facturación: ~a ($~a)\n" (first categoria) (third categoria))
      ; Imprime el cliente: 4 ~a → nombre, cédula (first), total (third), cantidad de pedidos (second).
      (printf "Cliente con mayor valor acumulado: ~a, CC ~a ($~a en ~a pedido(s))\n"
              ; Los 4 valores. Los ")" finales cierran: second, printf, let* e if.
              nombre (first cliente) (third cliente) (second cliente))))

; Encabezado de la sección 8.
(titulo "8. CONCILIACIÓN DE PAGOS")
; ¿No se registraron pagos?
(if (null? resultados-pagos)
    ; Sí: se avisa.
    (displayln "No se registraron pagos.")
    ; No: begin agrupa varias acciones en un solo camino del if.
    ;   Cada camino de un if admite UNA sola orden; begin junta varias y las ejecuta en orden.
    (begin
      ; Una línea por cada pago.
      (for-each mostrar-pago resultados-pagos)
      ; Cuántos pagos quedaron "Conciliado".
      (printf "\nPagos conciliados: ~a\n" (length (con-estado "Conciliado" resultados-pagos)))
      ; Suma de las diferencias de los pagos con "Saldo pendiente".
      (printf "Total de dinero pendiente: $~a\n"
              ; Valor del ~a.
              (sumar 'diferencia (con-estado "Saldo pendiente" resultados-pagos)))
      ; Suma de las diferencias de los pagos con "Excedente".
      (printf "Total de excedentes recibidos: $~a\n"
              ; Valor del ~a.
              (sumar 'diferencia (con-estado "Excedente" resultados-pagos)))
      ; Números de pedido de los pagos que NO quedaron conciliados.
      (printf "Números de pedido con diferencias: ~a\n"
              ; map toma el número de pedido de cada resultado. ~a imprime la lista: (102 108 999 106).
              (map (lambda (r) (dato r 'numero))
                   ; Lista que recorre el map: filter deja los que NO (not) son "Conciliado".
                   (filter (lambda (r) (not (string=? (dato r 'estado) "Conciliado")))
                           ; Lista que recorre el filter.
                           ; Los ")" finales cierran: filter, map, printf, begin e if.
                           resultados-pagos)))))

; Encabezado de la sección 9.
(titulo "9. MÉTRICAS GENERALES DE LA JORNADA")
; Porcentaje de registros que terminaron facturados. El "%" del texto se imprime tal cual.
(printf "Registros que terminaron en venta facturada: ~a%\n"
        ; Valor del ~a: porcentaje de facturados sobre registros recibidos.
        (porcentaje (length facturados) (length registros)))
; ¿Todos los facturados son consistentes? si-no convierte #t/#f en "Sí"/"No".
(printf "¿Todos los facturados tienen valores positivos y datos consistentes?: ~a\n"
        ; Se entrega la función datos-consistentes? (sin paréntesis) a todos-cumplen?.
        (si-no (todos-cumplen? datos-consistentes? facturados)))
; ¿Hay al menos un Premium + Express de más de $2.000.000?
(printf "¿Existe un pedido Premium con envío Express de más de $2.000.000?: ~a\n"
        ; Se entrega la función premium-express-alto? a alguno-cumple?.
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
