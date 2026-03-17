; 1. Aquí solo definimos algunos valores que vamos a usar en todo el programa
; para no estar escribiendo números a cada rato

.equ N      = 100        ; básicamente el arreglo tendrá 100 números
.equ MODVAL = 101        ; esto se usa para que los números aleatorios queden entre 0 y 100

; 2. Aquí empieza la parte de memoria RAM
; básicamente se aparta espacio para guardar todos los arreglos y variables

.dseg

table_of_unsorted_numbers:      .byte N   ; aquí se guardan los 100 números aleatorios sin ordenar
table_of_sorted_numbers_alg1:   .byte N   ; aquí se guardará el arreglo ya ordenado con Bubble Sort
table_of_sorted_numbers_alg2:   .byte N   ; aquí se guardará el arreglo ordenado con Selection Sort

rng_state:                      .byte 1   ; esta variable guarda el estado del generador de números aleatorios

time_alg1_ticks:                .byte 2   ; aquí se guardará cuánto tiempo tardó Bubble Sort
time_alg2_ticks:                .byte 2   ; aquí se guardará cuánto tiempo tardó Selection Sort

; 3. A partir de aquí ya empieza el código que ejecuta el microcontrolador

.cseg
.org 0x0000
    rjmp RESET              ; cuando el micro arranca siempre empieza en 0x0000 y de una vez brinca a RESET


; 4. Aquí empieza el programa como tal
; primero se inicializan varias cosas importantes

RESET:

    ; esta parte configura el stack
    ; el stack sirve para guardar direcciones cuando se llaman funciones

    ldi r16, high(RAMEND)   ; carga en r16 la parte alta de la última dirección de RAM
    out SPH, r16            ; se guarda en el registro alto del stack pointer

    ldi r16, low(RAMEND)    ; carga la parte baja de la última dirección de RAM
    out SPL, r16            ; se guarda en el registro bajo del stack pointer

    clr r1                  ; limpia el registro r1 y lo deja en cero

    ; aquí configuramos el timer1
    ; este timer lo usamos para medir cuánto tardan los algoritmos

    ldi r16, 0x00           ; carga 0 en r16
    sts TCCR1A, r16         ; deja el Timer1 en modo normal

    ldi r16, (1<<CS11) | (1<<CS10)
                            ; activamos estos bits para configurar el prescaler
    sts TCCR1B, r16         ; el timer queda trabajando con prescaler de 64

    ; aquí inicializamos el generador de números aleatorios

    ldi r16, 0xA7           ; usamos este valor como semilla inicial
    sts rng_state, r16      ; se guarda en la variable rng_state

    ; ahora se generan los 100 números aleatorios

    rcall FILL_RANDOM_0_100 ; esta función llena el arreglo con números del 0 al 100

    ; ahora preparamos los punteros para copiar el arreglo

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)
                            ; el puntero Z apunta al arreglo original

    ldi YH, high(table_of_sorted_numbers_alg1)
    ldi YL, low(table_of_sorted_numbers_alg1)
                            ; el puntero Y apunta al arreglo destino

    rcall COPY_N_BYTES      ; copia el arreglo original al que usará el algoritmo 1

    ; ahora vamos a medir cuánto tarda Bubble Sort

    rcall TIMER1_RESET      ; primero se reinicia el timer

    ldi ZH, high(table_of_sorted_numbers_alg1)
    ldi ZL, low(table_of_sorted_numbers_alg1)
                            ; ahora Z apunta al arreglo que se va a ordenar

    rcall BUBBLE_SORT_N     ; aquí se ejecuta Bubble Sort

    rcall TIMER1_READ_TO_time_alg1
                            ; aquí se guarda el tiempo que tardó el algoritmo

    ; ahora se preparan los datos para el segundo algoritmo

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)

    ldi YH, high(table_of_sorted_numbers_alg2)
    ldi YL, low(table_of_sorted_numbers_alg2)

    rcall COPY_N_BYTES      ; vuelve a copiar el arreglo original

    ; ahora medimos Selection Sort

    rcall TIMER1_RESET      ; otra vez reiniciamos el timer

    ldi ZH, high(table_of_sorted_numbers_alg2)
    ldi ZL, low(table_of_sorted_numbers_alg2)

    rcall SELECTION_SORT_N  ; aquí corre Selection Sort

    rcall TIMER1_READ_TO_time_alg2
                            ; se guarda el tiempo que tardó

; aquí básicamente el programa ya terminó
; se queda en un loop infinito para que no avance más

DONE:
    rjmp DONE


; esta función solo reinicia el contador del timer

TIMER1_RESET:

    ldi r16, 0              ; cargamos 0
    sts TCNT1H, r16         ; limpiamos la parte alta del contador
    sts TCNT1L, r16         ; limpiamos la parte baja
    ret                     ; regresamos de la función


; aquí se lee el tiempo que tardó el primer algoritmo

TIMER1_READ_TO_time_alg1:

    lds r18, TCNT1L         ; lee la parte baja del timer
    lds r19, TCNT1H         ; lee la parte alta

    sts time_alg1_ticks,   r18
    sts time_alg1_ticks+1, r19
                            ; guarda el valor del timer en la variable
    ret


; aquí se lee el tiempo del segundo algoritmo

TIMER1_READ_TO_time_alg2:

    lds r18, TCNT1L
    lds r19, TCNT1H

    sts time_alg2_ticks,   r18
    sts time_alg2_ticks+1, r19
                            ; guarda el tiempo del segundo algoritmo
    ret


; esta función copia N bytes de un arreglo a otro

COPY_N_BYTES:

    ldi r20, N              ; r20 será el contador de los 100 elementos

COPY_LOOP:

    ld  r16, Z+             ; lee un valor del arreglo origen
    st  Y+, r16             ; lo guarda en el arreglo destino

    dec r20                 ; reduce el contador
    brne COPY_LOOP          ; sigue hasta copiar los 100

    ret


; esta función llena el arreglo con números aleatorios

FILL_RANDOM_0_100:

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)
                            ; Z apunta al inicio del arreglo

    ldi r20, N              ; contador de los 100 números

FILL_LOOP:

    rcall RNG_NEXT_0_100    ; genera un número aleatorio
    st   Z+, r16            ; lo guarda en el arreglo

    dec  r20
    brne FILL_LOOP

    ret


; aquí está el generador de números pseudoaleatorios

RNG_NEXT_0_100:

    lds r16, rng_state      ; carga el estado actual

    mov r17, r16
    andi r17, 0x01          ; obtiene el último bit

    lsr r16                 ; mueve los bits a la derecha

    tst r17
    breq RNG_NOXOR

    ldi r18, 0xB8
    eor r16, r18            ; hace XOR para generar otro número

RNG_NOXOR:

    sts rng_state, r16      ; guarda el nuevo estado


REDUCE_MOD:

    cpi r16, MODVAL         ; compara con 101
    brlo RNG_DONE           ; si ya es menor ya quedó

    subi r16, MODVAL        ; si es mayor le resta 101
    rjmp REDUCE_MOD

RNG_DONE:
    ret


; aquí empieza Bubble Sort
; básicamente este algoritmo compara pares de números vecinos
; y si están al revés los intercambia hasta que todo quede ordenado

BUBBLE_SORT_N:

    ldi r21, N-1            ; r21 será el número de pasadas que hará el algoritmo

BS_OUTER:

    movw r28, r30           ; copiamos el puntero Z al puntero Y para empezar desde el inicio del arreglo
    clr  r22                ; r22 se usa como contador interno y lo empezamos en 0

BS_INNER:

    ld   r16, Y             ; carga en r16 el valor actual del arreglo
    ldd  r17, Y+1           ; carga en r17 el siguiente valor del arreglo

    cp   r17, r16           ; compara los dos números
    brsh BS_NOSWAP          ; si r17 es mayor o igual que r16 entonces ya están en orden

    st   Y,   r17           ; si estaban al revés aquí se intercambian
    std  Y+1, r16           ; guarda el valor anterior en la siguiente posición

BS_NOSWAP:

    adiw r28, 1             ; avanza el puntero para revisar el siguiente par de números
    inc  r22                ; aumenta el contador interno

    cp   r22, r21           ; revisa si ya terminó la pasada del arreglo
    brlo BS_INNER           ; si todavía faltan elementos sigue comparando

    dec r21                 ; reduce el número de pasadas que quedan
    brne BS_OUTER           ; si aún faltan pasadas vuelve a empezar desde el inicio

    ret                     ; cuando ya terminó todo regresa de la función

	; aquí está Selection Sort
; este algoritmo lo que hace es buscar el número más pequeño del arreglo
; y lo va colocando en su lugar poco a poco

SELECTION_SORT_N:

    movw r28, r30        ; Y = base del arreglo

    ldi r20, 0           ; i = 0

SS_OUTER:

    cpi r20, N-1
    brsh SS_DONE

    mov r21, r20         ; min_index = i

    ; Z = &arr[i]
    movw r30, r28
    add  r30, r20
    adc  r31, r1

    movw r26, r30        ; X = &arr[i]

    mov r22, r20
    inc r22              ; j = i+1

SS_INNER:

    cpi r22, N
    brsh SS_SWAP

    adiw r30,1           ; Z = &arr[j]
    ld r16, Z            ; r16 = arr[j]

    ; cargar arr[min_index]
    movw r26, r28
    add r26, r21
    adc r27, r1
    ld r17, X

    cp r16, r17
    brsh SS_NEXT_J

    mov r21, r22         ; nuevo min_index

SS_NEXT_J:

    inc r22
    rjmp SS_INNER


SS_SWAP:

    cp r21, r20
    breq SS_NEXT_I

    ; arr[i]
    movw r30, r28
    add r30, r20
    adc r31, r1
    ld r16, Z

    ; arr[min_index]
    movw r26, r28
    add r26, r21
    adc r27, r1
    ld r17, X

    st Z, r17
    st X, r16

SS_NEXT_I:

    inc r20
    rjmp SS_OUTER


SS_DONE:
    ret