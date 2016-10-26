;Programa atlieka 4 uzadvinius, su ivesta eilute, nuo 8 iki 80 simboliu
;Uzdavinys A: sukeicia ketvirta ir devinta simbolius vietomis
;Uzdavinys B: spausdina kiekvieno baito bitus ir spausdina kiekvieno baito trecio ir priespaskutinio bitu suma (Bitai numeruojami nuo jauniausio, kurio numeris yra 0)
;Uzdavinys C: spausdina stulpeliu kiekvieno ivesto baito reiksme, kuri yra padauginta is 178 ir prie jos prideta 5 (atsakymas pateikiamas 10-taineje sistemoje, baito reiksmes nagrinejamos kaip bezenkliai skaiciai)
;Uzdavinys D: spausdina stulpeliu tu baitu reiksmes, kuriu reiksmes skaitmenu sandauga desimtaineje sistemoje yra didesne uz 6
;------------------------------------------------------------------------


gaukNurodytaBaitoBita macro  baitas, kelintas          
; Makrosas keicia AX
; Pirmas argumentas:  baitas (adresas/reiksme/konstanta)
; Antras argumentas:  kelinta bita norime suzinoti (bitai skaiciuojami nuo nulinio - jauniausio)
; Rezultas: al - nurodyto bito reiksme
   push cx                               ; issaugome cx (naudojamas cikle)
   mov cl, kelintas                      ; bito numeris
   mov al, byte ptr baitas               ; krauname baita
   shr al, cl                            ; stumiame nurodyta bita i pradzia
   and al, 01                            ; atmetame kitus bitus
   pop cx                                ; graziname cx reiksme 
endm

;------------------------------------------------------------------

desimtaineje macro buffer
        local exit,con
;Macro keicia BX, DX, AX
;Atsakyma issaugome atmintyje pirmo argumento buffer adresu ir macro pabaigoje atspausdinamas
		mov bx,10                        ; 0Ah=10(10) i bx uzkrauname pagrinda is kurio dalinsime
		push si                          ;issisaugom steke si reiksme kuri mum skaiciuoja kuris skaitmuo siuometu nagrinejamas
		mov si, offset buffer            ; atsakymo buferis, i si ikrauname bufferio pabaigos adresa
		push si                          ; isaugome steke pabaigos adresa
		
		con:                             ; konvertavimo procesas
			xor dx, dx                   ; dx = 0000h
			div bx                       ; daliname skaiciu esanti  ax registre is bx (pagrindo). ax registre lieka sveikoji dalis, dx registre liekana
			add dl, '0'                  ; kad paversti i reikiama ASCII koda (naudojame dl registra, nes liekanos reiksme bus mazesne uz 10h, '0' reiksme yra 48 (desimtaineje, 30h)
			mov [si], dl                 ; liekanos reiksme (jau paversta i reikiama simboli) issisaugome ef adresu [si]
			dec si                       ; si--, jei reiktu irasyti dar viena skaiciu (-- nes pradedame rasyti nuo galo)
			cmp ax, 0                    ; paziurime ar pradinis skaicius visas susidalino iki 0
			jz exit                      ; jei 0 tai baigiame konvertacija ir einame i isvedima
			jmp con                      ; jei ne 0 tai konvertuojame toliau
		exit:
			inc si                       ; si++, nes pries tai buvo sumazintas, o dar vieno skaiciaus irasyti neprireike
			mov dx, si                   ; ikeliame dx <-si nes dx bus spausdinamas
			pop bx                       ; is steko graziname pabaigos adreso reiksme
			mov word ptr[bx+1],240Ah     ; pridedame eilutes pabaiga (LS+ $) uz ivestu duomenu pabaigos adreso
			mov ah, 09h                  ; spausdinimo funkcija
			int 21h
			pop si                       ;graziname is steko reiksme kurioje buvo issaugota kuris skaitmuo nagrinejamas
endm
;------------------------------------------------------------------------

desimtaineje6 macro
		local exit,con
;Macro keicia BX, DX, AX
;Macro sudaugina baito reiksmes skaitmenis desimtaineje skaiciavimo sistemoje, atsakymas pateikiamas AX registre
		mov bx, 000Ah                    ; 0Ah=10(10) i bx uzkrauname pagrinda is kurio dalinsime
		push cx                          ; issisaugom steke cx reiksme
		xor cx, cx                       ; cx = 0 ,nes i ji bus renkama kiek kartu reiks nuimt reiksme is steko
		
		con:                             ; konvertavimo procesas
			xor dx, dx                   ; dx = 0000h
			div bx                       ; daliname skaiciu esanti  ax registre is bx (pagrindo). ax registre lieka sveikoji dalis, dx registre liekana
			push dx                      ; issaugome steke liekana (skaitmeni)
			inc cx                       ; cx ++, nes reikes is steko isimt viena daugiau reiksme
			cmp ax, 0                    ; paziurime ar pradinis skaicius visas susidalino iki 0
			jz exit                      ; jei 0 tai baigiame konvertacija ir einame i isvedima
			jmp con                      ; jei ne 0 tai konvertuojame toliau
		exit:
			dec cx                       ;cx -- nes viena reiksme is steko issimsime pries cikla
			pop ax                       ;is steko isimame pirma skaitmeni
			skait:                       ; ciklas is steko paims visus skaitmenis
				pop bx                   ; is steko isimame likusius skaitmenis
				mul bx                   ; sudauginame skaitmenis
				loop skait
			pop cx                       ; graziname cx reiksme
endm
;------------------------------------------------------------------------


spausdinkEil macro eilute
; Makro keicia AH, DX
	mov ah, 09                           ; isvedimo funkcija
	mov dx, offset eilute                ; isvedinejima eilute
	int 21h
endm


;------------------------------------------------------------------------


spausdinkSkaitmeni macro  skaitmuo          
; Makrosas keicia AH, DL
   mov dl, skaitmuo                      ; skaitmuo, kuri spausdinsime (nuo 0 iki 9)
   add dl, '0'                           ; pridedame '0', kad gautume tinkama ASCII koda
   mov ah, 02                            ; "antra" dos int 21h funkcija
   int 21h
endm

;------------------------------------------------------------------------


spausdinkBaitoBitus macro  baitas         
; Makrosas keicia AL, BL
; Pirmas argumentas - baitas (adresas/reiksme/konstanta)

push cx                                  ; issaugome cx
mov cx, 8                                ; reikia 8 bitu todel cikla kartosime 8 kartus
mov bl, 7                                ; pradesime nuo vyriausio 7-ojo bito
bitas:
gaukNurodytaBaitoBita baitas,bl          ; randamas bitas
  spausdinkSkaitmeni al                  ; atspausdinamas bitas
  dec bl                                 ; kiekviename cikle rasim vis zemesni bita
  loop bitas
pop cx                                   ; graziname cx reiksme

  gaukNurodytaBaitoBita baitas,6         ; randame 6 bita (pries paskutinio)

  mov bl, al                             ; bl <- 6 bitas 

  gaukNurodytaBaitoBita baitas,3         ; randame 3 bita
  
  add bl, al                             ; bl = prie 6 bito pridedam 3 bita
  
    spausdinkEil bitu_suma
  spausdinkSkaitmeni bl                  ; spausdiname bitu suma
   
endm

;------------------------------------------------------------------------
  
.model small
       ASSUME CS:kodas, DS:duomenys, SS:stekas
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stekas segment word stack 'STACK'
       dw 400h dup (00)                            ; stekas -> 2 Kb
stekas ends
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
duomenys segment para public 'DATA'
   
    pranesimas:
	db 'Marius Kurbakovas Programu sistemos 1 kursas pirma grupe'
	db 0Dh, 0Ah
	db 'Ivesk eilute nuo 8 iki 80 simboliu$'
    naujaEilute:   
	db 0Dh, 0Ah, '$'                               ; tuscia eilute
	uzduotisA:
	db 'A uzduotis: '
	db 0Dh, 0Ah, '$'
	uzduotisB:
	db 'B uzduotis: '
	db 0Dh, 0Ah, '$'
	uzduotisC:
	db 'C uzduotis: '
	db 0Dh, 0Ah, '$'
	uzduotisD:
	db 'D uzduotis: '
	db 0Dh, 0Ah, '$'
    dar_pranesimas:
    db 'Tu ivedei: $'
    rezultato_pranesimas:
    db 'Ketvirtasis simbolis keiciamas vietomis su devintuoju: $'
	bitu_suma:
	db ' priespaskutinio ir trecio bitu suma = $'
	sk:
	db ' baito reiksme padauginta is 178 ir prideta 5 (desimtaineje sistemoje): $'
    
   
    buferisIvedimui:
       db 81, 00, 100 dup ('*')
	buferisIsvedimuiC:
	   db 6, 00, 100 dup ('*')                      ; C uzduotyje naudojamas buferis, kuriame saugomas C uzduoties atsakymas (jau desimtaineje sistemoje)
	buferisIsvedimuiD:
	   db 4, 00 , 100 dup ('*')                     ; D uzduotyje naudojamas buferis, kuriame saugoma baito reiksme 
duomenys ends
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
kodas segment para public 'CODE'
    pradzia:

       mov ax,     seg duomenys                     ; "krauname" duomenu segmenta
       mov ds,     ax
	   
    spausdinkEil pranesimas
	spausdinkEil naujaEilute

       mov ah,     0Ah                              ; ivesties funkcija
       mov dx,     offset buferisIvedimui           ; buferis
       int 21h       

    spausdinkEil naujaEilute
	spausdinkEil naujaEilute


    spausdinkEil uzduotisA

       mov bl,     byte ptr [buferisIvedimui + 1]   ; bl<-kiek buvo ivesta simboliu
       xor bh,     bh                               ; bh <- 0   
       mov word ptr [bx + 3 + buferisIvedimui], 240Ah ; LF + '$' -> eilutes galas
       
       ; Isvedame ivesta eilute:
       spausdinkEil dar_pranesimas

       spausdinkEil naujaEilute

       mov dx,     offset buferisIvedimui + 2
       mov ah,     09
       int 21h

       ; Keiciame eilute:
    
	mov al,     byte ptr[buferisIvedimui + 5]       ; al <- ketvirtas simbolis
	mov cl, byte ptr[buferisIvedimui + 10]          ; cl <- devintas simbolis
	mov byte ptr[buferisIvedimui + 10], al          ; devintas <- al
	mov byte ptr[buferisIvedimui + 5], cl	        ; ketvirtas <- cl
	
    spausdinkEil rezultato_pranesimas
    spausdinkEil naujaEilute
	
       mov dx,     offset buferisIvedimui + 2      ; isvedama pakeista eilute
       mov ah,     09
       int 21h
	   ; simboliu atkeitimas
	   mov al,     byte ptr[buferisIvedimui + 5]   ; al <- ketvirtas simbolis
	mov cl, byte ptr[buferisIvedimui + 10]         ; cl <- devintas simbolis
	mov byte ptr[buferisIvedimui + 10], al         ; devintas <- al
	mov byte ptr[buferisIvedimui + 5], cl	       ; ketvirtas <- cl

	   mov ah, 01h                                 ; pauze tarp uzduociu
	   int 21h
	spausdinkEil naujaEilute
	spausdinkEil uzduotisB
	
	mov cl, byte ptr [buferisIvedimui + 1]         ; ciklas kartosis tiek kartu kiek buvo ivesta simboliu
	mov si, 2                                      ; si skaiciuos kuris skaitmuo nagrinejamas
	ciklasB:
		spausdinkBaitoBitus [buferisIvedimui+si]   ; macro atspausdina visus simbolio bitus, o paskui atspaudina reikiamu bitu suma
		spausdinkEil naujaEilute 
		inc si                                     ; si++, kad butu imamas kitas skaicius
		loop ciklasB
		
		mov ah, 01h                                ; pauze tarp uzduociu
	    int 21h
	spausdinkEil naujaEilute
	spausdinkEil uzduotisC
	mov si, 2                                      ; si skaiciuos kuris skaitmuo nagrinejamas
	mov cl, byte ptr [buferisIvedimui + 1]         ; ciklas kartosis tiek kartu kiek buvo ivesta simboliu
	
	ciklasC:                                       ; atliekama C uzduotis (spausdina stulpeliu kiekvieno įvesto baito reikšmę, kuri yra padauginta iš 178 ir prie jos pridėta 5)
			mov dl, byte ptr [buferisIvedimui+si]  ; simbolis kuri spausdinsime
			mov al, dl                             ; issisaugome uzkrauto baito reiksme AL registre (kuriame atliksime veiksmus)
			mov ah, 02                             ; atspausdina simboli
			int 21h
			spausdinkEil sk
		xor ah, ah                                 ; AX -> 00al
		xor bh, bh
		mov bl, 00b2h                                ; 00b2h = 178
		mul bx                                     ; ax = ax * bx
		add ax, 0005                               ; ax = ax + 0005
		inc si                                     ; si++ nes imsime kita simboli
		
		desimtaineje buferisIsvedimuiC + 5         ; i si buferi (eilute) ivedame jau i desimtaine pakeista skaiciu
		loop ciklasC
		
		
	   mov ah, 01h                                 ; pauze tarp uzduociu
	   int 21h
	spausdinkEil naujaEilute
	spausdinkEil uzduotisD
	
	mov cl, byte ptr [buferisIvedimui + 1]         ; ciklas kartosis tiek kartu kiek buvo ivesta simboliu
	mov si, 2                                      ; si skaiciuos kuris skaitmuo nagrinejamas
	
	ciklasD:                                       ; Atliekama D uzduotis (spausdina stulpeliu tų baitų numerius, kurių reikšmės skaitmenų sandauga dešimtainėje sistemoje yra didesnė už 6)
		mov al, byte ptr [buferisIvedimui+si]      ; krauname baita
		xor ah, ah                                 ; AX -> 00al
		inc si                                     ; si++
		desimtaineje6                              ; skaicius paverciamas i desimtainius skaitmenis ir jie sudauginami
		cmp al, 06h                                ; pagal uzduoti lyginame bito skaitmenu sandauga (desimtaineje sistemoje) su 6
		jle nedidesnis                             ; jei al mazesnis arba lygus 6 tada sokama i ciklo pabaiga, jei ne tai ciklas tesiamas toliau nuo sios vietos 
		mov al, byte ptr [buferisIvedimui+si-1]    ; al <- ikeliamas baitas
		desimtaineje buferisIsvedimuiD + 3         ; isvedama baito reiksme desimtaineje sistemoje (tarkim jei simbolis 0, tai isvedame 48)
		nedidesnis:
		loop ciklasD

       mov ah,     4ch                             ; baigimo funkcijos numeris
       int 21h
kodas  ends
    end pradzia 