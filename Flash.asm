.model large
.data

exit db 0
player_pos dw 1760d                         ;player pos

arrow_pos dw 0d                             ;arrow pos
arrow_status db 0d                          ;0 = arrow ready to go else not 
arrow_limit dw  22d     ;150d

mutant_pos dw 3860d       ;3990d
mutant_status db 0d
         
                                            ;direction of pl
                                            ;up=8, down=2
direction db 0d

state_buf db '00:0:0:0:0:0:00:00$'          ;score
hit_num db 0d
hits dw 0d
miss dw 0d  

game_over_str dw '  ',0ah,0dh
dw '                             |               |',0ah,0dh
dw '                             |---------------|',0ah,0dh
dw '                             | ^   Score   ^ |',0ah,0dh
dw '                             |_______________|',0ah,0dh
dw ' ',0ah,0dh 
dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw '                                You lost',0ah,0dh
dw '                        Press Enter to start(lose) again$',0ah,0dh 


game_start_str dw '  ',0ah,0dh

dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw ' ',0ah,0dh
dw '                ====================================================',0ah,0dh
dw '               ||                                                  ||',0ah,0dh                                        
dw '               ||     *      Time Freeze Shooter        *          ||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh
dw '               ||--------------------------------------------------||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh
dw '               ||          Game Inspired by the flash              ||',0ah,0dh          
dw '               ||        arrow up / down to move player            ||',0ah,0dh
dw '               ||          and space button to shoot               ||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh
dw '               ||            Press Enter to start                  ||',0ah,0dh 
dw '               ||                                                  ||',0ah,0dh
dw '               ||                                                  ||',0ah,0dh
dw '                ====================================================',0ah,0dh
dw '$',0ah,0dh




.code
main proc
mov ax,@data
mov ds,ax

mov ax, 0B800h
mov es,ax 



jmp game_menu                              ;main menu

                                                                   
main_loop:                                 ;logic update and display 
                                           ;check for key press
    mov ah,1h
    int 16h                                ;if pressed pressed
    jnz key_pressed
    jmp inside_loop                        ;if not continue
    
    inside_loop:                           ;check
        
        cmp miss,9                         ;if miss >= 9 game over
        jge game_over
        
        mov dx,arrow_pos                   ;check collisions
        cmp dx, mutant_pos
        je hit
        
        cmp direction,8d                   ;player pos updates
        je player_up
        cmp direction,2d                   ;up or down direction
        je player_down
        
        mov dx,arrow_limit                 ;arrow hide 
        cmp arrow_pos, dx
        jge hide_arrow
        
        cmp mutant_pos, 0d                 ;check miss mutant
        jle miss_mutant
        jne render_mutant 
    
        hit:                               ;sound if hit ( nu merge mereu da nu ma prind de ce )
            mov ah,2
            mov dx, 7d
            int 21h 
            
            inc hits                       ;score update
            
            lea bx,state_buf               ;score display
            call show_score 
            lea dx,state_buf
            mov ah,09h
            int 21h
            
            mov ah,2                       ;endl
            mov dl, 0dh
            int 21h    
            
            jmp fire_mutant                ;new mutant pops up
    
        render_mutant:                     ;draw mutant
            mov cl, ' '                    ;hide old mutant
            mov ch, 1111b
        
            mov bx,mutant_pos 
            mov es:[bx], cx
                
            sub mutant_pos,160d            ;draw in new position
            mov cl, 15d
            mov ch, 1101b
        
            mov bx,mutant_pos 
            mov es:[bx], cx
            
            cmp arrow_status,1d            ;check arrow for rendering
            je render_arrow
            jne inside_loop2 
        
        render_arrow:                      ;render arrow
        
            mov cl, ' '
            mov ch, 1111b
        
            mov bx,arrow_pos               ;hide old position
            mov es:[bx], cx
                
            add arrow_pos,4d               ;draw new position
            mov cl, 26d
            mov ch, 1001b
        
            mov bx,arrow_pos 
            mov es:[bx], cx
        
        inside_loop2:
            
            mov cl, 125d                  ;draw player 
            mov ch, 1100b
            
            mov bx,player_pos 
            mov es:[bx], cx
            

    cmp exit,0
    je main_loop                          ;end main loop
    jmp exit_game
 
jmp inside_loop2
    
player_up:                                ;remove player from old position
    mov cl, ' '
    mov ch, 1111b
        
    mov bx,player_pos 
    mov es:[bx], cx
    
    sub player_pos, 160d                  ;set player new position
    mov direction, 0    

    jmp inside_loop2                      ;it will draw in main loop
    
player_down:
    mov cl, ' '                           ;same as player up
    mov ch, 1111b                         ;hide old one and set new postion
                                          
    mov bx,player_pos 
    mov es:[bx], cx
    
    add player_pos,160d                   ;and main loop draw that
    mov direction, 0
    
    jmp inside_loop2

key_pressed:                              ;input hanaling section
    mov ah,0
    int 16h

    cmp ah,48h                            ;go upKey if up button is pressed
    je upKey
    cmp ah, 50h
    je downKey
    
    cmp ah,39h                            ;go spaceKey if up button is pressed
    je spaceKey
    
    cmp ah,4Bh                            ;go leftKey (this is for debuging)
    je leftKey
     
                                          ;if no key is pressed go to inside of loop
    jmp inside_loop

leftKey:                                  ;we use it for debuging 
    ;jmp game_over
    inc miss
            
    lea bx,state_buf
    call show_score 
    lea dx,state_buf
    mov ah,09h
    int 21h
    
    mov ah,2
    mov dl, 0dh
    int 21h
jmp inside_loop
    
upKey:                                    ;set player direction to up
    mov direction, 8d
    jmp inside_loop

downKey:
    mov direction, 2d                     ;set player direction to down
    jmp inside_loop
    
spaceKey:                                 ;shoot a arrow
    cmp arrow_status,0
    je  fire_arrow
    jmp inside_loop

fire_arrow:                               ;set arrow postion in player position
    mov dx, player_pos                    ;so arrow fire from player postion
    mov arrow_pos, dx
    
    mov dx,player_pos                     ;when fire an arrow it also set limit
    mov arrow_limit, dx                   ;of arrow. where it should be hide
    add arrow_limit, 22d  ;150
    
    mov arrow_status, 1d                  ;set arrow status.It prevents multiple 
    jmp inside_loop                       ;shooting 

miss_mutant:
    add miss,1                            ;update score

    lea bx,state_buf                      ;display score
    call show_score 
    lea dx,state_buf
    mov ah,09h
    int 21h
                                          ;new line
    mov ah,2
    mov dl, 0dh
    int 21h
jmp fire_mutant
    
fire_mutant:                              ;fire new mutant
    mov mutant_status, 1d
    mov mutant_pos, 3860d     ;3990d
    jmp render_mutant
    
hide_arrow:
    mov arrow_status, 0                   ;hide arrow
    
    mov cl, ' '
    mov ch, 1111b
    
    mov bx,arrow_pos 
    mov es:[bx], cx
    
    cmp mutant_pos, 0d 
    jle miss_mutant
    jne render_mutant 
    
    jmp inside_loop2
                                          ;print game over screen
game_over:
    mov ah,09h
    ;mov dh,0
    mov dx, offset game_over_str
    int 21h
    
    
    
    mov cl, ' '                           ;hide last of screen mutant
    mov ch, 1111b 
    mov bx,arrow_pos                      
    
    mov cl, ' '                           ;hide player
    mov ch, 1111b 
    mov bx,player_pos  
 
    
    ;reset value                          ;update veriable for start again
    mov miss, 0d
    mov hits,0d
    
    mov player_pos, 1760d

    mov arrow_pos, 0d
    mov arrow_status, 0d 
    mov arrow_limit, 22d      ;150d

    mov mutant_pos, 3860d       ;3990d
    mov mutant_status, 0d
         
    mov direction, 0d
                                           ;wait for input
    input:
        mov ah,1
        int 21h
        cmp al,13d
        jne input
        call clear_screen
        jmp main_loop
    

game_menu:
                                           ;game menu screen
    mov ah,09h
    mov dh,0
    mov dx, offset game_start_str
    int 21h
                                           ;wait for input
    input2:
        mov ah,1
        int 21h
        cmp al,13d
        jne input2
        call clear_screen
        
        lea bx,state_buf                   ;display score
        call show_score 
        lea dx,state_buf
        mov ah,09h
        int 21h
    
        mov ah,2
        mov dl, 0dh
        int 21h
        
        jmp main_loop

exit_game:                                  ;fin
mov exit,10d

main endp



proc show_score
    lea bx,state_buf
    
    mov dx, hits
    add dx,48d 
    
    mov [bx], 9d
    mov [bx+1], 9d
    mov [bx+2], 9d
    mov [bx+3], 9d
    mov [bx+4], 'H'
    mov [bx+5], 'i'                                        
    mov [bx+6], 't'
    mov [bx+7], 's'
    mov [bx+8], ':'
    mov [bx+9], dx
    
    mov dx, miss
    add dx,48d
    mov [bx+10], ' '
    mov [bx+11], 'M'
    mov [bx+12], 'i'
    mov [bx+13], 's'
    mov [bx+14], 's'
    mov [bx+15], ':'
    mov [bx+16], dx
ret    
show_score endp 


clear_screen proc near
        mov ah,0
        mov al,3
        int 10h        
        ret
clear_screen endp

end main
