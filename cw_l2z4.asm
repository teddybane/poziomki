#include<usb1287def.inc>

.def jeden=R31
.def zero=R30
.def gora=R29
.def dol=R28
.def dioda_stan=R19
.cseg
.org 0x0
    rjmp Poczatek

.org 0x000C						// External Interrupt Request 5
    rjmp PrzerwanieINT				// przerwanie INT5 dla PE5-DOWN

.org 0x0012						// Pin Change Interrupt Request 7
    rjmp PrzerwaniePCINT			// przerwanie PCINT7 dla PB7-UP

.org 0x2e 	// obsluga przerwania timera, ten konkretny adres to timer/counter0 overflow
jmp Obsluga

Poczatek:
    ldi r16, low(RAMEND)			// wpisanie do wskaznika stosu adresu konca pamieci sram
    ldi r17, high(RAMEND)
    out sph, r17					// zapisujemy R17 na SPH
    out spl, r16					// zapisujemy R16 na SPL

    push r16						// wkladamy na stos wartosc R16
    push r17						// wkladamy na stos wartosc R17

    ldi jeden, 1
    ldi zero, 0
    ldi gora, 0b10000000
    ldi dol, 0b00000001
    ldi dioda_stan, 1
    // dokonczyc sterowanie


    ldi R16, 0b11100000				// linie 5, 6, 7 PORTB w trybie wejsciowym
    in R17, PORTB	   
    or R17, R16	   
    out PORTB, R17	   

    ldi R16, 0b00110000				// linie 4, 5 PORTE w trybie wejsciowym
    in R17, PORTE
    or R17, R16
    out PORTE, R17

    //inicjalizajia diod
    ldi R16, 0b11110000				// linie 4, 5, 6, 7 portu D w trybie wyjsciowym
    in R17, DDRD
    OR R17, R16	   
    out DDRD, R17

    pop R17							// sciagamy ze stosu
    pop R16							//sciagamy ze stosu
    
    // ustawianie prescalera
    ldi R16, 5 	//0b101 ustawienie wartosci , 
                    //odpowiednia wartosc bierzemy z dokumentacji
    out TCCR0B, R16 //wpisanie wartosci z R16 do 
                    // 0b101 dzielenie prze 1024

    // ustawienie trybu pracy timera
    ldi R16, 1
    sts TIMSK0, R16 	// Store Direct To Data Space
                            // bit 0 ustawiony na 1 wlacza przerwanie w trakcie przepelnienia

    // Ustawienie przerwan zewnetrznych, port E
    LDI R16, 0b00001111
    STS EICRB, R16

    // Ustawienie maskowania, port E
    LDI R16, 0b00100000
    OUT EIMSK, R16 // Musi byż OUT bo to nie STS czyli bez dodatkowych 20

    // Ustawienie przerwan zewnetrznych, port B
    LDI R16, 0b00000001
    STS PCICR, R16

    // Ustawienie maskowania, port B
    LDI R16, 0b11111111
    STS PCMSK0, R16

    sei 			// ustawienie flagi i == wyzwolenie mozliwosci obslugi przerwan
    koniec: jmp koniec 	// nieskonczona petla
/////////////////////////////////////////////////////////////////////////////////////////////////
PrzerwanieINT:		// przerwanieINT - ruch joystickiem w dol
    bst jeden, 0
    push dol
    reti
//////////////////////////////////////////////////////////////////////////////////////////////

PrzerwaniePCINT:	// przerwaniePCINT - ruch joystickiem w gore
    sbis PORTB, 7       //jesli w PORTB 7 bit zapalony pomin nastepna instrukcje
    reti
    bst jeden, 0        //oznaczamy ze wystapilo przerwanie
    push gora           // wpychamy na stos oznaczenie przerwania
    reti

/////////////////////////////////////////////////////////////////////////////////////////////////
Obsluga: 	
    in R21, SREG
	cpi R21, 0b01000000 
    breq Alternatywa

    sei
    cp dioda_stan, jeden	// cp = compare
    breq Zgas  		// branch

    //tu zapalamy
    ldi R17, 0x40		//0b0001 0000(gorna zielona)
    ldi dioda_stan, 0x01    // oznaczenie zapalenia diody
    rjmp wykonaj_i_wroc

Alternatywa:
    bst zero, 0
    pop R20     //zdjecie se stosu oznaczenia czy gora czy dol
    sei
    cp R20, dol     //sprawdzanie czy gora
    breq Zielona_dol

    cp R20, gora    //sprawdzanie czy dol
    breq Czerwona_dol

Zielona_dol:
    cp dioda_stan, jeden	// cp = compare
    breq Zgas 		// branch

    //tu zapalamy
    ldi R17, 0x20		//dolna zielona
    ldi dioda_stan, 0x01    // oznaczenie zapalenia diody
    rjmp wykonaj_i_wroc

Czerwona_dol:
    cp dioda_stan, jeden	// cp = compare
    breq Zgas 
    //tu zapalamy
    ldi R17, 0x10		//0b0001 0000(gorna zielona)
    ldi dioda_stan, 0x01    // oznaczenie zapalenia diody
    rjmp wykonaj_i_wroc

Zgas:
    ldi R17, 0x00 	    
    ldi dioda_stan, 0x00	// zmienna-flata przedstawiajaca stan diody 0=zgaszona, 1=zapalona
    rjmp wykonaj_i_wroc

wykonaj_i_wroc:
    call Wykonaj
    reti 

Wykonaj:		//procedura gasi pozostałe diody i zapala wła ciwš
push R16
in R16, PORTD		//or, aby oszczedzić orginalne ustawienia reszty lini portu B
andi R16, 0x0F
or R16, R17 
out PORTD, R16
pop R16
ret
