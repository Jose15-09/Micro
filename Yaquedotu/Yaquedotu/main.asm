; 1. Aquí solo definimos algunos valores que vamos a usar en todo el programa
; para no estar escribiendo números a cada rato

.equ N      = 100        ; básicamente el arreglo tendrá 100 números
.equ MODVAL = 101        ; esto se usa para que los números aleatorios queden entre 0 y 100
; 2. Empieza la parte de memoria RAM
; Se aparta espacio para guardar todos los arreglos y variables

.dseg

table_of_unsorted_numbers:      .byte N   ; Se guardan los 100 números aleatorios sin ordenar
table_of_sorted_numbers_alg1:   .byte N   ; Se guardará el arreglo ya ordenado con Bubble Sort
table_of_sorted_numbers_alg2:   .byte N   ; Se guardará el arreglo ordenado con Selection Sort

rng_state:                      .byte 1   ; Variable que guarda el estado del generador de números aleatorios

time_alg1_ticks:                .byte 2   ; Se guarda el tiempo de Bubble Sort
time_alg2_ticks:                .byte 2   ; Se guarda el tiempo de Selection Sort

; 3. A partir de aquí ya empieza el código que ejecuta el microcontrolador

.cseg
.org 0x0000
    rjmp RESET              ; cuando el micro arranca siempre empieza en 0x0000 y de una vez brinca a RESET

; 4. Empieza el programa 
; Se inicializa varias cosas importantes

RESET:

    ; Esta parte configura el stack
    ; el stack sirve para guardar direcciones cuando se llaman funciones

    ldi r16, high(RAMEND)   ; Carga en r16 la parte alta de la última dirección de RAM
    out SPH, r16            ; Guarda en el registro alto del stack pointer

    ldi r16, low(RAMEND)    ; Carga la parte baja de la última dirección de RAM
    out SPL, r16            ; Guarda en el registro bajo del stack pointer

    clr r1                  ; Limpia el registro r1 y lo deja en cero

    ; Configuramos el timer1
    ; Timer se usa para medir cuánto tardan los algoritmos

    ldi r16, 0x00           ; Carga 0 en r16
    sts TCCR1A, r16         ; Deja el Timer1 en modo normal

    ldi r16, (1<<CS11) | (1<<CS10)
                            ; Activa esos bits para configurar el prescaler
    sts TCCR1B, r16         ; Timer queda trabajando con prescaler de 64

    ; Inicializamos el generador de números aleatorios

    ldi r16, 0xA7           ; Usamos como valor inicial
    sts rng_state, r16      ; Se guarda en la variable rng_state

    ; Generan los 100 números aleatorios

    rcall FILL_RANDOM_0_100 ; La función llena el arreglo con números del 0 al 100

    ; Preparamos los punteros para copiar el arreglo

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)
                            ; el puntero Z apunta al arreglo original

    ldi YH, high(table_of_sorted_numbers_alg1)
    ldi YL, low(table_of_sorted_numbers_alg1)
                            ; el puntero Y apunta al arreglo destino

    rcall COPY_N_BYTES      ; copia el arreglo original al que usará el algoritmo 1

    ; ahora vamos a medir cuánto tarda Bubble Sort

    rcall TIMER1_RESET      ; Se reinicia el timer

    ldi ZH, high(table_of_sorted_numbers_alg1)
    ldi ZL, low(table_of_sorted_numbers_alg1)
                            ; ahora Z apunta al arreglo que se va a ordenar

    rcall BUBBLE_SORT_N     ; Se ejecuta Bubble Sort

    rcall TIMER1_READ_TO_time_alg1
                            ; Se guarda el tiempo que tardó el algoritmo

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
