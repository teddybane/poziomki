/* (c) based on Przemys³aw Sadowski code */
/* (c) £ukasz Szkup */

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

clr R18 //rejestr zawsze rowny zero do porownan
ldi R21, 0x02 // rejestr przy ktorym grzebiemy jako przy kluczu


SprawdzPrzycisk:
cp R18, R21
breq Znaleziono 
sbis PINE, 5 //stan wysoki na 5 bicie pine nie ma zwarcia nie trzymany na dole joistic
rjmp Dol
sbis PINB, 7
rjmp Gora
rjmp SprawdzPrzycisk

Znaleziono:
ldi R17, 0x90
call Wykonaj
rjmp WhileTrue

WhileTrue:
nop
rjmp WhileTrue


Dol:
ldi R17, 0x20//0b0010 0000(dolna zielona)
rcall Wykonaj
call Petla
dec R21
rjmp CzyPuszczonyDol

CzyPuszczonyDol:
sbis PINE, 5 //stan niski na pinie E 5 czyli jest zwarcie czyli joistik trzymany w dole
rjmp CzyPuszczonyDol
ldi R17, 0x00
call Wykonaj
rjmp SprawdzPrzycisk

Gora:
ldi R17, 0x40//0b0001 0000(górna zielona)
rcall Wykonaj
call Petla
inc R21
rjmp CzyPuszczonyGora

CzyPuszczonyGora:
sbis PINB,7
rjmp CzyPuszczonyGora
ldi R17, 0x00
call Wykonaj
rjmp SprawdzPrzycisk


Wykonaj://procedura gasi pozosta³e diody i zapala w³a ciwš
push R16
in R16, PORTD//or, aby oszczedziæ orginalne ustawienia reszty lini portu B
andi R16, 0x0F
or R16, R17 
out PORTD, R16
pop R16
ret

Petla:
ldi R19, 0xFF
call PustaZ
ret

PustaZ:
ldi R20, 0xFF
call PustaW
call PustaW
call PustaW
call PustaW
dec R19
cp R19, R18
brne PustaZ 
ret

PustaW:
nop
dec R20
cp R20, R18
brne PustaW
ret
