.MODEL SMALL
.STACK 100H
.DATA
    ; mesaje
    mesajIntroducereSecventa DB 'Introduceti secventa Hamming de 21 biti: $'
    mesajEroare DB 13,10,'Introducere invalida! Introduceti doar 0 si 1$'
    mesajCaractereDecodificate DB 13,10,'Caracterele decodificate sunt:$'
    mesajDouaErori DB 13,10,'S-au detectat doua erori in secventa! $'
    mesajCorectat DB 13,10,'S-a corectat o eroare pe pozitia: $'
    mesajParitate DB 'Secventa este codata pentru paritate (0) sau imparitate (1)? $'
    mesajCaracterNeprintabil DB 13,10,'Caracter neprintabil $'
    mesajScurt DB 13,10,'Mesajul introdus nu are 21 de biti $'
    ; variabile
    secventaMesajTransmis DB 22 DUP(0)      ; cream spatiu in memorie pentru 21 biti
    caractereDecodificate DB 3 DUP(0)       ; cream spatiu in memorie pentru a stoca caracterele
    pozitieEroare DW 0                      ; variabila pentru a memora pozitia erorii
    sindrom DB 5 DUP(0)                     ; spatiu pentru sindrom pt a corecta eroarea
    bitParitateGlobala DB 0                 ; bitul de paritate globala pentru a diferentia intre o eroare si doua erori
    tipParitate DB 0                        ; tipul de paritate pe care ar trebui sa il aiba mesajul primit;
    
.CODE
MAIN:
    mov AX, @DATA
    mov DS, AX
    
    afisareMesaje MACRO mesaj
        push ax      ; bagam in stiva valorile ax si dx ca sa nu le pierdem
        push dx
        mov dx, offset mesaj        ; in dx vom avea mesajul pe care vrem sa il afisam
        mov ah, 9
        int 21h
        pop dx        ; extragem din stiva valorile
        pop ax
    ENDM

    ; mesaj pt a afla paritatea
    afisareMesaje mesajParitate
    
    ; citim paritatea
    mov AH, 1
    int 21H
    cmp AL, '0'
    jl paritateInvalida ; daca al nu are valoarea 0 sau 1, oprim programul deoarece au fost introduse caractere gresite de paritate
    cmp AL, '1'
    jg paritateInvalida
    sub AL, '0'
    mov [tipParitate], AL
    jmp continuareProgram

    paritateInvalida:
        jmp introducereInvalida
    ; adaugam o noua linie pt afisarea urmatorului mesaj
    continuareProgram:
    mov DL, 13
    mov AH, 2
    int 21H
    mov DL, 10
    mov AH, 2
    int 21H
    
    ; mesajul pentru a citi secventa
    afisareMesaje mesajIntroducereSecventa
    ; contor pentru 21 de caractere + contor pt a stii la al catelea caracter suntem
    mov CX, 21
    mov SI, 0
    
citireSecventa:
    mov AH, 1
    int 21H
    cmp AL, 13 ; comparam cu enter
    je mesajIncomplet
    cmp AL, '0'
    jl introducereInvalida ; daca al nu are valoarea 0 sau 1, oprim programul deoarece au fost introduse caractere gresite
    cmp AL, '1'
    jg introducereInvalida
    
    sub AL, '0'
    mov [secventaMesajTransmis+SI], AL  ; stocam in secventa caracterul citit
    inc SI   ; crestem contorul
    loop citireSecventa
   
    call verificareBiti  ; verificam daca mesajul a fost transmis corect, daca nu corectam bitul gresit 
    
    ; pregatim registrii pt extragerea caracterelor
    xor AX, AX
    xor BX, BX
    mov SI, 0
    mov DI, 0
    mov CX, 21
    
extragereCaractere:
    inc SI
    
    mov DX, SI  ; introducem in dx pozitia la care suntem
    call verificarePutereALui2 ; verificam daca pozitia este putere a lui 2 ( bit de paritate)
    jc skipBit ; daca CARRY FLAG este setat, atunci pozitia este putere a lui 2 si trecem peste acest bit
    
    
    mov AL, [secventaMesajTransmis+SI-1] ; bagam in al valoarea bitului
    
    cmp DI, 8 ; comparam sa vedem daca am introdus deja primii 8 biti ai mesajului pentru a vedea ce caracter construim
    jge alDoileaCaracter ; daca di este 8 sau mai mare trecem la al doilea caracter
    
    shl BL, 1 ; daca nu construim primul caracter shiftand stanga cu o pozitie si realizand operatia sau cu noul bit pt a-i adauga la final valoarea
    or BL, AL
    jmp continuareExtragere ; continuam extragerea
    
alDoileaCaracter:
    shl BH, 1 ; construirea celui de al doilea caracter
    or BH, AL
    
continuareExtragere:
    inc DI ; crestem nr de biti adaugati deja in construirea caracterelor
    
skipBit:
    loop extragereCaractere  ; loop pt a extrage toate caracterele, cx = 21
    
    mov [caractereDecodificate], BL ; mutam primul caracter in caractereDecodificate
    mov [caractereDecodificate+1], BH  ; mutam al doilea caracter in caractereDecodificate
    call caractereNeprintabile ; verificam daca sunt caractere neprintabile
    
    afisareMesaje mesajCaractereDecodificate ; daca nu sunt atunci le afisam
    
    mov DL, [caractereDecodificate]
    mov AH, 2
    int 21H
    
    mov DL, [caractereDecodificate+1]
    mov AH, 2
    int 21H
    
    jmp iesireProgram
mesajIncomplet:
    afisareMesaje mesajScurt ; mesaj daca nu sunt 21 biti introdusi
    jmp iesireProgram
introducereInvalida:
    afisareMesaje mesajEroare  ; daca caracterele introduse sunt gresite afisam mesaj

    
iesireProgram:
    mov AH, 4CH
    int 21H

verificareBiti PROC
    push ax
    push bx
    push cx ; salvam valorile din registrii
    push dx
    push si
    push di
    
    ; Calculam bitul de paritate globala
    xor al, al ; il vom salva in al
    mov cx, 21 ; verificam toti cei 21 biti
    mov si, 0 ; incepand de la primul
    
calculParitate:
    mov bl, [secventaMesajTransmis+si]
    xor al, bl  ; realizam operatia XOR pe rand cu toti bitii
    inc si
    loop calculParitate
    mov [bitParitateGlobala], al ; salvam in variabila bitParitateGlobala valoarea acestuia
    
    ; calculam sindromul
    ; calculam primul bit de paritate (Pozitia 1,3,5,7,9,11,13,15,17,19,21)
    xor al, al ; stergem valorile din al
    mov si, 0
    mov cx, 11 ; avem nevoie de 11 operatii xor
p1_loop:
    xor al, [secventaMesajTransmis+si] ; ne folosim de XOR
    add si, 2  ; pt a calcula urmatoarea pozitie impara
    loop p1_loop
    mov [sindrom], al  ; mutam in sindrom valoarea calculata
    
    ;  calculam al doilea bit de paritate (Pozitia 2,3,6,7,10,11,14,15,18,19)
    xor al, al ; stergem valoarea din al pentru a nu influenta rezultatul
    mov al, [secventaMesajTransmis+1] ; Pozitia 2
    xor al, [secventaMesajTransmis+2] ; Pozitia 3
    xor al, [secventaMesajTransmis+5] ; Pozitia 6
    xor al, [secventaMesajTransmis+6]  ; Pozitia 7
    xor al, [secventaMesajTransmis+9]  ; Pozitia 10
    xor al, [secventaMesajTransmis+10] ; Pozitia 11
    xor al, [secventaMesajTransmis+13] ; Pozitia 14
    xor al, [secventaMesajTransmis+14] ; Pozitia 15
    xor al, [secventaMesajTransmis+17] ; Pozitia 18
    xor al, [secventaMesajTransmis+18] ; Pozitia 19
    mov [sindrom+1], al ; mutam in sindrom valoarea
    
    ;calculam bitul 4 de paritate (Pozitia 4-7,12-15,20,21)
    xor al, al
    mov al, [secventaMesajTransmis+3] ; Pozitia 4
    xor al, [secventaMesajTransmis+4] ; Pozitia 5
    xor al, [secventaMesajTransmis+5]  ; Pozitia 6
    xor al, [secventaMesajTransmis+6]  ; Pozitia 7
    xor al, [secventaMesajTransmis+11] ; Pozitia 12
    xor al, [secventaMesajTransmis+12] ; Pozitia 13
    xor al, [secventaMesajTransmis+13] ; Pozitia 14
    xor al, [secventaMesajTransmis+14] ; Pozitia 15
    xor al, [secventaMesajTransmis+19] ; Pozitia 20
    xor al, [secventaMesajTransmis+20] ; Pozitia 21
    mov [sindrom+2], al ; mutam in sindrom valoarea
    
    ; calculam bitul 8 de paritate (Pozitia 8-15)
    xor al, al
    mov al, [secventaMesajTransmis+7]  ; Pozitia 8
    xor al, [secventaMesajTransmis+8]  ; Pozitia 9
    xor al, [secventaMesajTransmis+9] ; Pozitia 10
    xor al, [secventaMesajTransmis+10] ; Pozitia 11
    xor al, [secventaMesajTransmis+11] ; Pozitia 12
    xor al, [secventaMesajTransmis+12] ; Pozitia 13
    xor al, [secventaMesajTransmis+13] ; Pozitia 14
    xor al, [secventaMesajTransmis+14] ; Pozitia 15
    mov [sindrom+3], al ; mutam in sindrom valoarea
    
    ; calculam bitul 16 de paritate (Pozitia 16-21)
    xor al, al
    mov al, [secventaMesajTransmis+15] ; Pozitia 16
    xor al, [secventaMesajTransmis+16] ; Pozitia 17
    xor al, [secventaMesajTransmis+17] ; Pozitia 18
    xor al, [secventaMesajTransmis+18] ; Pozitia 19
    xor al, [secventaMesajTransmis+19] ; Pozitia 20
    xor al, [secventaMesajTransmis+20] ; Pozitia 21
    mov [sindrom+4], al ; mutam in sindrom valoarea

     ; verificam bitii din sindrom
    xor cx, cx ; contor pt cati biti sunt setati cu 1
    mov si, 0  ; contor pt al catelea bit suntem
    mov dl, 5 ; cati biti verificam
verificareSindrom:
    mov al, [sindrom+si]
    and al, 1    ; verificam daca bitul este 1
    jz urmatorulBitSindrom  ; daca nu trecem la urmatorul bit
    inc cx  ; numaram bitii de 1
urmatorulBitSindrom:
    inc si  ; crestem contorul
    dec dl  ; scadem bitii de verificat
    jnz verificareSindrom  ; daca di nu e zero continuam verificarea


    cmp cx, 0   ; daca cx e 0 nu avem erori
    jne avemEroare   ; daca nu e 0 ( jump not equal ) avem eroare
    jmp iesireProcedura  ; daca cx = 0 atunci sarim la final
; calculam pozitia erorii
avemEroare:
    
    xor ax, ax 
    mov al, [sindrom+4]  ; primul bit pe care il adaugam este bitul de sindrom pt 16 deoarece bitul 16 este influentat doar de pozitiile cele mai mari, astfel detecteaza erorile pe pozitii mari in cazul in care e eronat
    and al, 1  ; verificam daca e 0 sau 1 
    shl al, 4  ; il mutam cu 4 pozitii spre stanga
    mov bl, al ; il mutam in bl
     
    mov al, [sindrom+3]  ; bitul 8 este al doilea cel mai mare bit de paritate influentat doar de pozitii mari, procesul continua pt p4,p2,p1, in functie de cati biti sunt influentati si valoarea lor
    and al, 1   ; verificam daca e 0 sau 1
    shl al, 3   ; il mutam 3 pozitii mai la stanga
    or bl, al  ; facem operatia sau intre ce avem deja in bl, si ce e nou in al pt a ajunge cu pozitia erorii in bl
     
    mov al, [sindrom+2]  ; bitul 4
    and al, 1
    shl al, 2
    or bl, al
    
    mov al, [sindrom+1]  ; bitul 2
    and al, 1
    shl al, 1
    or bl, al
    
    mov al, [sindrom]  ; bitul 1
    and al, 1
    or bl, al
    
    mov [pozitieEroare], bx   ; mutam pozitia erorii din bx in variabila

    ; verificam paritatea calculata cu cea pe care o asteptam
    mov al, [bitParitateGlobala]
    xor al, [tipParitate]    
    test al, 1
    jz eroareDubla           ; daca tipul de paritate nu este acelasi si  cx!=0 atunci avem doua erori

    ; corectarea unei erori
    mov bx, [pozitieEroare] ; in bx avem pozitia erorii
    dec bx  ; o scadem cu 1 deoarece in secventa am inceput de la 0
    mov al, [secventaMesajTransmis+bx]
    xor al, 1  ; modificam bitul
    mov [secventaMesajTransmis+bx], al ; il salvam in secventa
    
    
    afisareMesaje mesajCorectat   ; afisam mesajul
    mov ax, [pozitieEroare]        ; punem pozitia erorii in ax
    
    mov bx, 10                     ; vom imparti la 10 , pt a afisa corect in cazul in care eroarea e pe o pozitie de 2 cifre
    xor dx, dx                     ; stergem valorile din dx pt a stoca restul
    div bx                         ; impartim la 10
    push dx                         ; restul il stocam in stiva
   
    test ax,ax                   ; daca rezultatul este zero, avem o singura cifra
    jz oSinguraCifra              
    
   
    add al, '0'                   ; daca nu, afisam prima cifra
    mov dl, al                     
    mov ah, 2                      
    int 21h
    
    oSinguraCifra:
    
    pop dx                  ; extragem restul din stiva si il afisam
    add dl, '0'                    
    mov ah, 2                      
    int 21h
    
    jmp iesireProcedura ; dam jump la final

eroareDubla:
    afisareMesaje mesajDouaErori ; mesaj in cazul in care avem doua erori
    pop di
    pop si
    pop dx
    pop cx 
    pop bx
    pop ax
    jmp iesireProgram ; terminam programul
    
iesireProcedura:
    pop di
    pop si
    pop dx  ; reluam valorile registrilor din stiva
    pop cx
    pop bx
    pop ax
    ret
verificareBiti ENDP
    
caractereNeprintabile PROC
    cmp BL, 32
    jle caracterNeprintabil ; comparam sa vedem daca caracterele au valorile caracterelor neprintabile
    cmp BH, 32
    jle caracterNeprintabil
    ret
caracterNeprintabil:
    afisareMesaje mesajCaracterNeprintabil
    mov ah, 4CH
    int 21h
caractereNeprintabile ENDP

verificarePutereALui2 PROC
    push AX
    mov AX, DX   ; ax  = dx , dx = pozitia in secventa
    dec AX ; scadem ax cu 1
    and DX, AX  ; facem si intre dx si ax
    jnz nuEPutere ; daca rezultatul nu este zero atunci pozitia nu este putere a lui 2
    STC  ; daca rezultatul e zero setam CARRY FLAG = 1
    pop AX ; reluam valoarea in ax
    ret
nuEPutere:
    CLC ; dam clear la CARRY FLAG = 0
    pop AX
    ret
verificarePutereALui2 ENDP

END MAIN