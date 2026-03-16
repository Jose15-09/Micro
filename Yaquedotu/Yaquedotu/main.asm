; 1. Definimos algunos valores que vamos a usar en todo el programa

.equ N      = 100        ;arreglo de 100 números
.equ MODVAL = 101        ;limita los números aleatorios queden entre 0 y 100

; 2. Memoria RAM
; Aparta espacio para guardar todos los arreglos y variables

.dseg

table_of_unsorted_numbers:      .byte N   ; Guarda 100 números aleatorios sin ordenar
table_of_sorted_numbers_alg1:   .byte N   ; Guarda el arreglo ya ordenado con Bubble Sort
table_of_sorted_numbers_alg2:   .byte N   ; Guaerda el arreglo ordenado con Selection Sort

rng_state:                      .byte 1   ; Guarda el estado del generador de números aleatorios

time_alg1_ticks:                .byte 2   ; Guardará cuánto tiempo tardó Bubble Sort
time_alg2_ticks:                .byte 2   ; Guardará cuánto tiempo tardó Selection Sort

; 3. Comienza el código que ejecuta el microcontrolador

.cseg
.org 0x0000
    rjmp RESET              ; Inicia el micro en 0x0000 y de una vez brinca a RESET


; 4. Inicia el programa 
; Inicializan varias cosas importantes

RESET:

    ; Configuracion stack
    ;(guarda direcciones cuando se llaman funciones)

    ldi r16, high(RAMEND)   ; Carga en r16 la parte alta de la última dirección de RAM
    out SPH, r16            ; Guarda en el registro alto del stack pointer

    ldi r16, low(RAMEND)    ; Carga la parte baja de la última dirección de RAM
    out SPL, r16            ; Guarda en el registro bajo del stack pointer

    clr r1                  ; Limpia el registro r1 y lo deja en cero

    ; Configura timer1 (mide cuánto tardan los algoritmos)

    ldi r16, 0x00           ; Carga 0 en r16
    sts TCCR1A, r16         ; Deja Timer1 en modo normal

    ldi r16, (1<<CS11) | (1<<CS10)
                            ; Activa estos bits para configurar el prescaler
    sts TCCR1B, r16         ; Timer queda trabajando con prescaler de 64

    ; Inicializamos el generador de números aleatorios

    ldi r16, 0xA7           ; Usa este valor como semilla inicial
    sts rng_state, r16      ; Guarda en la variable rng_state

    ; Generan los 100 números aleatorios

    rcall FILL_RANDOM_0_100 ; Esta función llena el arreglo con números del 0 al 100

    ; Ahora preparamos los punteros para copiar el arreglo

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)
                            ; Z apunta al arreglo original

    ldi YH, high(table_of_sorted_numbers_alg1)
    ldi YL, low(table_of_sorted_numbers_alg1)
                            ; Y apunta al arreglo destino

    rcall COPY_N_BYTES      ; Copia arreglo original al que usará el algoritmo 1

    ; Mide cuánto tarda Bubble Sort

    rcall TIMER1_RESET      ;Reinicia el timer

    ldi ZH, high(table_of_sorted_numbers_alg1)
    ldi ZL, low(table_of_sorted_numbers_alg1)
                            ; Z apunta al arreglo que se va a ordenar

    rcall BUBBLE_SORT_N     ;Ejecuta Bubble Sort

    rcall TIMER1_READ_TO_time_alg1
                            ;Guarda el tiempo que tardó el algoritmo

    ; Preparan los datos para el segundo algoritmo

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)

    ldi YH, high(table_of_sorted_numbers_alg2)
    ldi YL, low(table_of_sorted_numbers_alg2)

    rcall COPY_N_BYTES      ; Copia el arreglo original

    ; ahora medimos Selection Sort

    rcall TIMER1_RESET      ;Reinicia el timer

    ldi ZH, high(table_of_sorted_numbers_alg2)
    ldi ZL, low(table_of_sorted_numbers_alg2)

    rcall SELECTION_SORT_N  ;Corre Selection Sort

    rcall TIMER1_READ_TO_time_alg2
                            ;Guarda el tiempo que tardó

; Loop infinito para que no avance más

DONE:
    rjmp DONE


; Reinicia el contador del timer

TIMER1_RESET:

    ldi r16, 0              ; Carga 0
    sts TCNT1H, r16         ; Limpia la parte alta del contador
    sts TCNT1L, r16         ; Limpia la parte baja
    ret                     ; Regresa a la función


;Lee el tiempo que tardó el primer algoritmo

TIMER1_READ_TO_time_alg1:

    lds r18, TCNT1L         ; Lee la parte baja del timer
    lds r19, TCNT1H         ; Lee la parte alta

    sts time_alg1_ticks,   r18
    sts time_alg1_ticks+1, r19
                            ; Guarda valor del timer en la variable
    ret

; Lee el tiempo del segundo algoritmo

TIMER1_READ_TO_time_alg2:

    lds r18, TCNT1L
    lds r19, TCNT1H

    sts time_alg2_ticks,   r18
    sts time_alg2_ticks+1, r19
                            ; Guarda el tiempo del segundo algoritmo
    ret


; Copia N bytes de un arreglo a otro

COPY_N_BYTES:

    ldi r20, N              ; r20 Contador de los 100 elementos

COPY_LOOP:

    ld  r16, Z+             ; Lee un valor del arreglo origen
    st  Y+, r16             ; Guarda en el arreglo destino

    dec r20                 ; Reduce el contador
    brne COPY_LOOP          ; Sigue hasta copiar los 100

    ret


; Esta función llena el arreglo con números aleatorios

FILL_RANDOM_0_100:

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)
                            ; Z apunta al inicio del arreglo

    ldi r20, N              ; contador de los 100 números

FILL_LOOP:

    rcall RNG_NEXT_0_100    ; Genera un número aleatorio
    st   Z+, r16            ; Lo guarda en el arreglo

    dec  r20
    brne FILL_LOOP

    ret


; Generador de números pseudoaleatorios

RNG_NEXT_0_100:

    lds r16, rng_state      ; Carga el estado actual

    mov r17, r16
    andi r17, 0x01          ; Obtiene el último bit

    lsr r16                 ; Mueve los bits a la derecha

    tst r17
    breq RNG_NOXOR

    ldi r18, 0xB8
    eor r16, r18            ; Hace XOR para generar otro número

RNG_NOXOR:

    sts rng_state, r16      ; Guarda el nuevo estado


REDUCE_MOD:

    cpi r16, MODVAL         ; Compara con 101
    brlo RNG_DONE           ; Si es menor lo conserva

    subi r16, MODVAL        ; Si es mayor le resta 101
    rjmp REDUCE_MOD

RNG_DONE:
    ret


; Aquí empieza Bubble Sort
; Este algoritmo compara pares de números vecinos
; Si están al revés los intercambia hasta que todo quede ordenado

BUBBLE_SORT_N:

    ldi r21, N-1            ; r21 será el número de pasadas que hará el algoritmo

BS_OUTER:

    movw r28, r30           ; Copia el puntero Z al puntero Y para empezar desde el inicio del arreglo
    clr  r22                ; r22 se usa como contador interno y lo empezamos en 0

BS_INNER:

    ld   r16, Y             ; Carga en r16 el valor actual del arreglo
    ldd  r17, Y+1           ; Carga en r17 el siguiente valor del arreglo

    cp   r17, r16           ; Compara los dos números
    brsh BS_NOSWAP          ; Si r17 es mayor o igual que r16 entonces ya están en orden

    st   Y,   r17           ; Intercambian
    std  Y+1, r16           ; Guarda el valor anterior en la siguiente posición

BS_NOSWAP:

    adiw r28, 1             ; Avanza el puntero para revisar el siguiente par de números
    inc  r22                ; Aumenta el contador interno

    cp   r22, r21           ; Revisa si ya terminó la pasada del arreglo
    brlo BS_INNER           ; si faltan elementos sigue comparando

    dec r21                 ; Reduce el número de pasadas que quedan
    brne BS_OUTER           ; si aún faltan vuelve a empezar

    ret                     ; cuando termina todo regresa de la función

	; Selection Sort
; busca el número más pequeño del arreglo
; y lo coloca en su lugar poco a poco

SELECTION_SORT_N:

    ldi r21, 0              ; r21 es el índice i

SS_OUTER:

    mov r22, r21            ; r22 Guarda la posición donde está el valor mínimo

    movw r28, r30           ; Copia el puntero base del arreglo
    mov r23, r21            ; r23 Avanza hasta la posición i

SS_ADV_I:

    tst r23                 ; Revisa si ya llega a la posición i
    breq SS_GOT_I           ; si es cero entonces esta en esa posición

    adiw r28,1              ; Avanza el puntero una posición en el arreglo
    dec r23                 ; Reduce el contador
    rjmp SS_ADV_I           ; Sigue avanzando

SS_GOT_I:

    ld r17, Y               ; r17 Guarda el valor actual que toma como mínimo

    mov r24, r21            ; copia i en r24
    inc r24                 ; j = i + 1 inicia buscando el mínimo

SS_INNER:

    cpi r24, N              ; Revisa si llega al final del arreglo
    brsh SS_SWAP            ; si llegó entonces hace el intercambio

    movw r28, r30           ; Regresa al inicio del arreglo
    mov r23, r24            ; r23 Avanza hasta la posición j

SS_ADV_J:

    tst r23                 ; Revisa si ya llegó a j
    breq SS_GOT_J           ; Si sí entonces lee el valor

    adiw r28,1              ; Avanza el puntero en el arreglo
    dec r23
    rjmp SS_ADV_J

SS_GOT_J:

    ld r18, Y               ; Carga el valor que está en la posición j

    cp r18, r17             ; Compara el valor actual con el mínimo guardado
    brsh SS_NEXT_J          ; si no es menor entonces segue buscando

    mov r17, r18            ; si encuentra uno más pequeño lo guarda como nuevo mínimo
    mov r22, r24            ; también su posición

SS_NEXT_J:

    inc r24                 ; Avanza j a la siguiente posición
    rjmp SS_INNER           ; Sigue buscando el mínimo


SS_SWAP:

    cp r22, r21             ; Revisa si el mínimo estaba en la posición correcta
    breq SS_NEXT_I          ; si sí no lo intercambia

    movw r28, r30           ; Vuelve al inicio del arreglo
    mov r23, r21            ; Avanza hasta la posicion i

SS_ADV_I2:

    tst r23                 ; Revisa si se llego a i
    breq SS_I_READY

    adiw r28,1              ; Avanza en el arreglo
    dec r23
    rjmp SS_ADV_I2

SS_I_READY:

    ld r18, Y               ; r18 Guarda el valor de la posición i

    movw r26, r30           ; Usa el puntero X para moverse al mínimo encontrado
    mov r23, r22

SS_ADV_MIN:

    tst r23                 ; Revisa si llegó a la posición del mínimo
    breq SS_MIN_READY

    adiw r26,1              ; Avanza el puntero
    dec r23
    rjmp SS_ADV_MIN

SS_MIN_READY:

    ld r19, X               ; r19 Guarda el valor mínimo encontrado

    st Y, r19               ; Pone el mínimo en la posición i
    st X, r18               ; Pone el valor que estaba en i en la posición del mínimo

SS_NEXT_I:

    inc r21                 ; i Avanza a la siguiente posición
    cpi r21, N-1            ; Revisa si terminó el arreglo
    brlo SS_OUTER           ; si no, repite el proceso

    ret                     ; Termina la función
