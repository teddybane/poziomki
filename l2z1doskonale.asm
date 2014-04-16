/* based on (c) Przemysław Sadowski code */
/* (c) Łukasz Szkup */

#include<usb1287def.inc>

.cseg
.org 0x0
rjmp Ares


/*Linie joystick'a:
PB5-SELECT
PB6-LEFT
PB7-UP
PE4-RIGHT
PE7-DOWN
Linie LED
PD4-RED1
PD5-GREEN1
PD6-RED2
PD7-GREEN2 */


Ares:
ldi R16, low(RAMEND)//wpisanie do wskaźnika stosu adresu końca pamięci SRAM
ldi R17, high(RAMEND)
out SPH, R17
out SPL, R16

push R16//dobrze jest zawsze odkładać używany rejestr na stos, przydaje się
push R17

ldi R16, 0b11100000//PORTB linie 5 do 7 w trybie wejściowym
in R17, PORTB    //funkcja OR nie zmieni pozostałych bitów PORTx
or R17, R16    //rejestr DDRB wyzerowany, ustawienie PORTB
out PORTB, R17    //włącza podciąganie na liniach wejściowych

ldi R16, 0b00110000//PORTE linie 4 i 5 w trybie wejściowym
in R17, PORTE
or R17, R16
out PORTE, R17

ldi R16, 0b11110000//linie 4-7 portu D w trybie wyjściowym,
in R17, DDRD
or R17, R16    //zasilanie diod LED
out DDRD, R17

pop R17//zdejmujemy najpierw ten, który ostatni umieściliśmy
pop R16


//ladowanie stanow poczatkowych dla zminnych
ldi R31, 0x00 //uniwersalne zero
ldi R30, 0xFF
ldi R27, 0x80  //wstepne wypelnienie rejestru
ldi R20, 0x7C //R20 nie swiecenie czerwonej, swiecenie zielonej
ldi R21, 0x7D //R21 nie swiecenie zielonej, swiecenie czerwonej
ldi R22, 0x7D
ldi R23, 0x7C
ldi R19, 0x0F


Main:
rcall swiec_czerwona
rcall swiec_zielona
cp R19, R31 //porownanie sprawdzajace co 255 cykli maina czy ma zmienic dlugosc swiecenia
breq SprawdzJoystic
dec R19
rjmp Main

SprawdzJoystic:
ldi R19, 0x0F  // przed wykozystaniem w pełnej petli
sbis PINE, 5
rcall Dol //jesli do dolu zwieksz swiecenie czerwonej i zmniejsz zielonej
sbis PINB, 7
rcall Gora  //jesli do gory zwieksz swiecenie zielonej i zmniejsz czerwonej
rcall Main

Dol:
cp R22, R31
breq Omin_dol
dec R20 	//przerwa czerwona --, 
dec R22 	// świecenie zielonej --
inc R21 	// swiecenie czerwonej ++,
inc R23 	// przerwa zielonej++
Omin_dol:
rcall Petla_pelna
ret

Gora:
cp R21, R31
breq Omin_gora
inc R20 	//przerwa czerwona ++, 
inc R22 	//świecenie zielonej ++
dec R21 	//swiecenie czerwonej --,
dec R23		//przerwa zielonej --
Omin_gora:
rcall Petla_pelna
ret

Petla_pelna:
dec R27
cp R27, R31
brne Petla_pelna
ldi R27, 0x80 // po skonczeniu petla sprzata po sobie
ret

swiec_czerwona:
cp R21, R31
breq nieZapalajCz
ldi R17, 0x10 // 0b0100 0000(dolna czerwona)
rcall Wykonaj // zapalenie
mov R26, R21 // kopiowanie z rejestru sterujacego do roboczego petla swiecaca
rcall Petla_czas_swiecenia_cz // petla wyznaczajaca dlugosc swiecenia pracuje na R26-roboczym
nieZapalajCz:
//all Gasimy
//v R26, R20 // kopiowanie z rejestru sterującego do roboczego petla wygaszona
//all Petla_reg_czerwona // okresla dlugosc nie-swiecenia
ret

Petla_czas_swiecenia_cz:
nop
nop
nop
nop
dec R26
cp R26, R31
brne Petla_czas_swiecenia_cz
ret

Petla_reg_czerwona:
nop
nop
nop
nop
dec R26
cp R26, R31
brne Petla_reg_czerwona
ret



swiec_zielona:
cp R22, R31
breq nieZapalajZ
ldi R17, 0x20 //0b0010 0000(dolna zielona)
rcall Wykonaj
mov R26, R22
rcall Petla_czas_swiecenia_z
nieZapalajZ:
//all Gasimy
//v R26, R23
//all Petla_reg_zielona
ret

Petla_czas_swiecenia_z:
nop
nop
nop
nop
dec R26
cp R26, R31
brne Petla_czas_swiecenia_z
ret

Petla_reg_zielona:
nop
nop
nop
nop
dec R28
cp R28, R31
brne Petla_reg_czerwona
ret

Gasimy:
ldi R17, 0x00
rcall Wykonaj
ret

Wykonaj://procedura gasi pozostałe diody i zapala właściwą
push R16
in R16, PORTD//or, aby oszczedzić orginalne ustawienia reszty lini portu B
andi R16, 0x0F
or R16, R17
out PORTD, R16
pop R16
ret

