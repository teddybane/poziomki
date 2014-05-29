/* (c) Przemys³aw Sadowski */

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
ldi R16, low(RAMEND)//wpisanie do wskaŸnika stosu adresu koñca pamiêci SRAM
ldi R17, high(RAMEND)
out SPH, R17
out SPL, R16

push R16//dobrze jest zawsze odk³adaæ u¿ywany rejestr na stos, przydaje siê
push R17

ldi R16, 0b11100000//PORTB linie 5 do 7 w trybie wejœciowym
in R17, PORTB	   //funkcja OR nie zmieni pozosta³ych bitów PORTx
or R17, R16	   //rejestr DDRB wyzerowany, ustawienie PORTB 	
out PORTB, R17	   //w³¹cza podci¹ganie na liniach wejœciowych

ldi R16, 0b00110000//PORTE linie 4 i 5 w trybie wejœciowym
in R17, PORTE
or R17, R16
out PORTE, R17

ldi R16, 0b11110000//linie 4-7 portu D w trybie wyjœciowym, 
in R17, DDRD
or R17, R16	   //zasilanie diod LED
out DDRD, R17

pop R17//zdejmujemy najpierw ten, który ostatni umieœciliœmy
pop R16

SprawdzPrzycisk:
//Instrukcja pracuje tylko na przestrzeni we-wy (0x20-0x3F)
sbis PINE, 4 //
rjmp Prawy	//krótki, szybki skok
sbis PINB, 6
rjmp Lewy
sbis PINE, 5
rjmp Dol
sbis PINB, 7
rjmp Gora
sbis PINB, 5
rjmp Gasimy
rjmp SprawdzPrzycisk



Prawy:
ldi R17, 0x80//0b1000 0000 (górna czerwona dioda)
rcall Wykonaj
rjmp SprawdzPrzycisk

Lewy:
ldi R17, 0x10//0b0100 0000(dolna czerwona)
rcall Wykonaj
rjmp SprawdzPrzycisk

Dol:
ldi R17, 0x20//0b0010 0000(dolna zielona)
rcall Wykonaj
rjmp SprawdzPrzycisk

Gora:
ldi R17, 0x40//0b0001 0000(górna zielona)
rcall Wykonaj
rjmp SprawdzPrzycisk

Gasimy:
ldi R17, 0x00
rcall Wykonaj
rjmp SprawdzPrzycisk

Wykonaj://procedura gasi pozosta³e diody i zapala w³aœciw¹
push R16
in R16, PORTD//or, aby oszczedziæ orginalne ustawienia reszty lini portu B
andi R16, 0x0F
or R16, R17 
out PORTD, R16
pop R16
ret

