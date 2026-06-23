include Irvine32.inc

.data

message1 BYTE "Calculate Perimeter 2-Hexagon (LOOP and ADD instructions) : ", 0dh, 0ah, "Input Hexagon 1 (side length): ", 0

message2  BYTE "Input hexagon 2 (side length): ", 0

sideHex1 DWORD ?
sideHex2 DWORD ?

message3 BYTE "Result of Perimeter Hexagon 1 and 2 : ", 0dh, 0ah, 0

Perimeter_hexagon1 DWORD ?
Perimeter_hexagon2 DWORD ?

message4 BYTE "Total Perimeter Hexagon 1 and 2 : ", 0

TotalPerimeter DWORD ?

promptBad BYTE "Invalid input, please enter again", 0

.code
main proc

mov edx, OFFSET message1; move address message 1 to edx
call WriteString;         print out the content

read_inOptionHex1 : ;     go to function
call ReadDec;             cin
jnc goodInOptionHex1;     check condition true false

mov edx, OFFSET promptBad
call WriteString
jmp read_inOptionHex1

goodInOptionHex1 :
    mov sideHex1, eax
    mov edx, OFFSET message2
    call WriteString

read_inOptionHex2 :
    call ReadDec
    jnc goodInOptionHex2; condition betul pergi mana

    mov edx, OFFSET promptBad
    call WriteString
    jmp read_inOptionHex2

goodInOptionHex2 :
    mov sideHex2, eax
    call crlf;     new line
    mov ecx, 6; loop condition 
    mov eax, 0; jadi tempat simpan sum value hexagon 1
    mov ebx, 0; jadi tempat simpan sum value hexagon 2

loopAddHex :
    add eax, sideHex1
    add ebx, sideHex2
    loop loopAddHex; dia akan tgk dekat ecx berapa kali nak loop pastu dia next arahan

    mov Perimeter_hexagon1, eax
    mov Perimeter_hexagon2, ebx

    mov edx, OFFSET message3
    call WriteString
    mov eax, Perimeter_hexagon1
    call WriteDec ; cout nombor 
    call crlf
    mov eax, Perimeter_hexagon2
    call WriteDec ; cout nombor
    call crlf
    call crlf

    mov edx, OFFSET message4
    call WriteString
    add eax, Perimeter_hexagon1
    mov TotalPerimeter, eax
    mov eax, TotalPerimeter
    call WriteDec
    call crlf
    call crlf


exit
main ENDP
END main