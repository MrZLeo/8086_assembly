;author: mrzleo
data segment
    num_stack db 256 dup('$')  
    top dw 0                                ; top of stack 
    value dw 0                              ; store the number that read recently
    arr dw 1 dup(9876, 8765, 7654, 6543, 5432, 4321, 3210, 2100, 1100, 1000)
    step dw 0
    index dw 0
    isReverse dw 0
ends


stack segment
    dw   256  dup(0)
ends

helpful_sentence segment
    sentence db 'please type ten numbers :-) $'
ends

bad_token_print segment
    bad_tok db 'please type legal numbers :( $'
ends

bad_help_sentence segment
    bad_help_stence db 'type enter to continue... $'
ends

final_output segment
    final_sentence db 'sorting completed :)  $'
ends

second_element segment
    output_sentence db 'second item is: '
    number db 5 dup(0)
    db '$' 
ends

processing segment
    db 'processing...... $'
ends

change_order segment
    change_order_sentence db 'In order from smallest to largest'
    db 3fH
    db '(y/n): $'
ends

exit_sentence segment
    db 'type enter to exit... $'
ends

show_mem segment
	dw '+',2, '-',2, '-',2, '-',2, '-',2, '-',2, '-', 2, '-', 2, '+', 160-16, '|',16, '|',160-16
	dw 9 dup ('+',2, '-',2, '-',2, '-',2, '-',2, '-',2, '-', 2, '-', 2, '+',160-16, '|',16, '|',160-16)	
	dw '+',2, '-',2, '-',2, '-',2, '-',2, '-',2, '-', 2, '-', 2, '+',160-10
	dw '$' 
	color dw 0
ends
    

code segment
         
    main proc
        start:
            ; set segment registers:
            mov ax, data
            mov ds, ax
            mov es, ax
            mov ax, stack
            mov ss, ax
            mov sp, 256
            
            ; read the data
            call read_data
            jmp  place_num
                           
        
            _sort:
                call clean_screen
                call choose_order
                call clean_screen
                
                mov  ax,0b800h
        		mov  es,ax
        		mov  di,160*2+64
        		mov  ax,show_mem
        		mov  ds,ax
        		mov  si,0
        		
        		; draw the frame
        		call draw
        		
        		; draw the number
        		mov  di,160*3+68
        		mov  bx, 0
        		
        		draw_the_unsorted_num:
            		push ds
            		mov  ax, data
            		mov  ds, ax
            		
        		    mov  ax, arr[bx]
        		    
        		    pop  ds
        		    mov  dx, 1b
        		    call draw_num
        		    
        		    add  di,160*2
        		    add  bx, 2
        		    cmp  bx, 20
        		    jb   draw_the_unsorted_num
        		    
        		mov di, 0
        		mov ax, data
        		mov ds, ax
        		          
                call sort
                
                ; show the final output
                call clean_screen
                
                ;clean the screen
                push cx
                mov  cx, 10
                clean_:
                    call clean_color
                    add  di,160*2
                    loop clean_
                pop cx
                
                ; mov cursor  
                mov ah,02h
                mov dh,9 
                mov dl,9+12
                int 10h       
                ; show helpful sentence     
                mov ax,processing
                mov ds,ax
                mov dx,0h
                mov ah,09h
                int 21h
                
                
                mov  ax, data
                mov  ds, ax
                xor  bx, bx
                xor  di, di
                
                draw_final_arr:
                    mov  ax, arr[bx]
                    call final_draw_num
                    
                    add bx, 2
                    cmp bx, 20
                    jb  draw_final_arr
                
                
                call clean_screen
                call final_show 
            
            jmp end
            
            
        place_num:
            ; transfer ascii to number
            xor si, si
            xor di, di
            xor bx, bx
            
            get_number_loop:
                cmp num_stack[si], '$'
                je  _sort
                
                xor bx, bx
                mov bl, num_stack[si]
                sub bl, 30H
                mov ax, value
                mov cx, 10
                mul cx
                add ax, bx
                mov value, ax
                inc si
                
                cmp num_stack[si], 20H
                je  store_num
                cmp num_stack[si], '$'
                je  end_of_num
                
                jmp get_number_loop 
            
            store_num:
                inc si
                mov bx, value
                mov arr[di], bx
                add di, 2
                mov value, 0
                jmp get_number_loop
            
            end_of_num:
                mov bx, value
                mov arr[di], bx
                add di, 2                

            jmp _sort
            
        end:
            ;call clean_screen
            
            ; type enter to exit...
            mov ah, 02h
            mov dh, 12 
            mov dl, 12+6
            int 10h
            mov ax, exit_sentence
            mov ds, ax
            mov dx, 0h
            mov ah, 09h
            int 21h
            
            end_loop:
                mov  ah, 07H
                int  21H
                cmp  al, 0dH
                je   __end
                
                jmp end_loop
            
                
        
            __end:
                mov ax, 4c00h                   ; exit to operating system.
                int 21h
    main endp
    
    read_data proc
        mov ax, data
        mov ds, ax
        mov si, 0
        
        push si
        call get_num
        
        pop si
        ret
    read_data endp
    
    
    get_num proc
        push bx
        
        ; mov cursor for printing helpful sentence
        mov_cursor:  
            mov ah,02h
            mov dh,9 
            mov dl,9+8
            int 10h
        
        ; print helpful sentence
        put_helpful_sentence:
            ; show helpful sentence     
            call show
            
            ; move curosr for reading the data
            mov ah,02h
            mov dh,10 
            mov dl,10+7
            int 10h
            
        
        
        
        ;get number
        read_char:
            mov  ah, 07H
            int  21H
            cmp  al, 30H
            jb   not_digit
            cmp  al, 39H
            ja   not_digit
            
                                 
            mov  ah, 0
            call num_stack_helper
            
            mov  ah, 2
            call num_stack_helper
            
            jmp  read_char
            
                      
        not_digit:
            cmp al, 08H
            je  breakspace
            cmp al, 0dH
            je  enter
            cmp al, 20H
            je  space
            
            ; refuse illegal input
            jmp bad_token
            
            
            breakspace:
                mov  ah, 1
                call num_stack_helper
                
                mov  ah, 2
                call num_stack_helper
                
                jmp  read_char
            
            enter:
                mov  ah, 0
                mov  al, '$'
                call num_stack_helper
                
                mov  ah, 2
                call num_stack_helper
                
                jmp  char_end
                
            bad_token:
                ; error message
                mov ah, 02h
                mov dh, 10 
                mov dl, 10+7
                int 10h
                mov ax, bad_token_print
                mov ds, ax
                mov dx, 0h
                mov ah, 09h
                int 21h
                ; type enter continue..
                mov ah, 02h
                mov dh, 11 
                mov dl, 11+6
                int 10h
                mov ax, bad_help_sentence
                mov ds, ax
                mov dx, 0h
                mov ah, 09h
                int 21h
                
                ; keep reading enter
                get_enter:
                mov  ah, 07H
                int  21H
                cmp  al, 0dH
                call clean_screen
                call show
                jmp  read_char
                
                ; if not
                jmp  get_enter
            
            space:
                mov  ah, 0
                call num_stack_helper
                
                mov  ah, 2
                call num_stack_helper
                
                jmp read_char
                
            char_end:           
                pop bx
                ret
    get_num endp
    
    num_stack_helper proc
        ; ah: 0-push, 1-pop, 2-display
        _start:
            push bx
            cmp  ah, 0
            je   _push
            
            cmp  ah, 1
            je   _pop
            
            cmp  ah, 2
            je   _display
            
        
        _push:
            mov  bx, top
            mov  num_stack[bx], al
            inc  top
            mov  num_stack[bx+1], '$'
            jmp  _end
            
        
        _pop:
            cmp  top, 0                      ; if stack is empty, return
            je   _end
            
            dec  top
            mov  bx, top
            mov  al, num_stack[bx]
            mov  num_stack[bx], '$'
            jmp  _end
            
        
        _display:
            call clean_screen
            call show
         
            jmp short _end
            
            
        _end:
            pop bx
            ret
        
        
    num_stack_helper endp
    
    
    clean_screen proc
     
        push ax
        mov  ah, 0fH
        int  10H
        mov  ah,0
        int  10H  
        pop ax
        ret
        
    clean_screen endp
    
    
    show proc
        push ax
        push dx
        
        ; mov cursor  
        mov ah,02h
        mov dh,9 
        mov dl,9+8
        int 10h       
        ; show helpful sentence     
        mov ax,helpful_sentence
        mov ds,ax
        mov dx,0h
        mov ah,09h
        int 21h
        
        ; move curosr again
        mov ah,02h
        mov dh,10 
        mov dl,10+7
        int 10h
        ; show string
        mov ax,data
        mov ds,ax
        mov dx,0h
        mov ah,09h
        int 21h 
        
        call delay
        pop dx
        pop ax
        
        ret     
    show endp
    
    

    sort proc
        ;sort the arr
        
        mov step, 4                     ; step = 4, 2, 1 /* shell sort */
        
        step_loop:
            cmp step, 0
            je  step_loop_end
            
              
        
        mov cx, step                    ; cx = i
        shl cx, 1
        out_loop:
            cmp  cx, 20                  ; for i in range[1, 10)
            je   out_loop_end
            mov  si, cx
            
            mov  ax, arr[si]
            mov  bx, step
            shl  bx, 1
            mov  di, si
            sub  di, bx
            mov  bx, arr[di]
            
            cmp  isReverse, 1
            je   reverse_sort1
                    
            cmp  ax, bx                  ; if (arr[i] < arr[i-step])
            jae  in_loop_end
            jmp  next1
            
            reverse_sort1:
            cmp  ax, bx
            jbe  in_loop_end
            
            
            next1:
            mov  dx, arr[si]             ; int temp = arr[i], dx = temp
            mov  bx, cx                  ; di = j
            jmp  in_loop_move
     
                   
        in_loop_move:                   ; for (int j = i; j >= step && temp < arr[j-step]; ++j) 
            mov  ax, step
            shl  ax, 1
            cmp  bx, ax                 ;/* shell sort */
            jb   in_loop_move_end
       
            mov  di, bx
            sub  di, ax
            
            cmp  isReverse, 1
            je   reverse_sort2
             
            cmp  dx, arr[di]
            jae  in_loop_move_end
            jmp  next2
            
            reverse_sort2:
            cmp  dx, arr[di]
            jbe  in_loop_move_end
            
            next2:
            push ax
            mov  ax, arr[di]           ; arr[j] = arr[j-step]
            mov  arr[bx], ax
            pop  ax
            
            sub  bx, ax
            
            jmp  in_loop_move
        
            
        in_loop_move_end:
            mov  arr[bx], dx  
        
            
        in_loop_end:
            add  cx, 2
            
            ;call draw_sorting_num
            
            jmp  out_loop   
        
                     
        out_loop_end:
            mov  ax, step
            shr  ax, 1
            mov  step, ax
           
            call draw_sorting_num
            jmp  step_loop
            
        step_loop_end:
            ;call draw_sorted_num
            ret
                
    sort endp
    
    draw proc
        
               
    	draw_start:
    		cmp  word ptr ds:[si]  ,  '$'
    		je   draw_ret
    		mov  ax                ,  ds:[si]
    		mov  es:[di]           ,  al
    		;call delay
    		add  di                ,  ds:[si+2]
    		add  si                ,  4
    		jmp  draw_start
    		
    	draw_ret:
    		ret
    		
    draw endp
    
    
    delay proc
		push cx
		mov cx,03fh
		run1:
		push cx
		mov cx,0fffh
		run2:
		loop run2
		pop cx
		loop run1
		pop cx
		ret
    delay endp
    
    ; draw the number:
    ;   @ax: the number
    ;   @dx: the color
    ;   @es:[di]: the position that number print
    draw_num proc
        push ax
        push bx
        push cx
        push di
        push dx
        mov  cx, 0
        mov  bx, 10
        mov  color, dx
        xor  dx, dx
        
        _draw_store_char:
            div  bx
            add  dx, 30H
            push dx
            xor  dx, dx
            inc  cx
            cmp  ax, 0
            jnz  _draw_store_char
            
        _draw_num:
            pop  ax
            mov  es:[di], ax
            mov  dx, color
            mov  es:[di+1], dx
            call delay
            add  di, 2
            loop _draw_num
            
       _draw_end:     
            pop  dx
            pop  di
            pop  cx
            pop  bx
            pop  ax
            ret
                   
    draw_num endp
    
    draw_sorting_num proc
        push dx
        push cx
        push ax
        push di
        push bx
        push ds
        
        mov  di,160*3+68
		mov  bx, 0
        ; draw the number
        _draw_sorting_num:
            pop  ds
            mov  ax, arr[bx]
            push ds
            push ax
		    
		    cmp  step, 0
		    je   change_color
		    mov  dx, 1b
		    jmp  next
		    
		    change_color:
		        mov dx, 1bH
		    
		    next:
		    mov  ax, show_mem
		    mov  ds, ax
		    pop  ax
		    
		    ;mov  dx, 1b
		    
		    call draw_num
		    
		    add  di,160*2
		    add  bx, 2
		    cmp  bx, 20
		    jb  _draw_sorting_num
		
		pop  ds
		pop  bx
		pop  di
		pop  ax
		pop  cx
		pop  dx        
    	
    	ret	
    draw_sorting_num endp
    
    final_show proc
        
        ;call final_draw_num
        
        push ax
        push dx
        
        ; mov cursor  
        mov ah,02h
        mov dh,9 
        mov dl,9+8
        int 10h       
        ; show helpful sentence     
        mov ax,final_output
        mov ds,ax
        mov dx,0h
        mov ah,09h
        int 21h
        
        ; move curosr again
        mov ah,02h
        mov dh,10 
        mov dl,10+3 ;number is too long
        int 10h
        ; show all elements
        mov ax,data
        mov ds,ax
        mov dx,0h
        mov ah,09h
        int 21h
        
        ; move curosr again
        mov ah,02h
        mov dh,11 
        mov dl,11+6
        int 10h
        ; show sentence of second element
        push ax
        push ds
        push cx
        mov  ax, data
        mov  ds, ax
        mov  bx, 0
        
        loop_find_second:
            cmp num_stack[bx], ' '
            je  find_second_num1
            inc bx
            jmp loop_find_second
        
        find_second_num1:    
            xor cx, cx
            inc bx
        find_second_num2:
            xor  ax, ax
            mov  al, num_stack[bx]
            push ax
            inc  cx
            inc  bx
            cmp  num_stack[bx], ' '
            je   put_second1
            jmp  find_second_num2
            
        put_second1:    
            mov  ax, second_element
            mov  ds, ax
            xor  ax, ax
        put_second2:
            pop  ax
            mov  bx, cx
            mov  number[bx], al
            loop put_second2
            
            pop  cx
            pop  dx
            pop  ax
            
                
        
        mov ax,second_element
        mov ds,ax
        mov dx,0h
        mov ah,09h
        int 21h 
        
        pop dx
        pop ax
        
        ret 
        
    final_show endp
    
    
    final_draw_num proc
        push ax
        push bx
        push cx
        push dx
        mov  index, di
        mov  cx, 0
        mov  bx, 10
        xor  dx, dx
        xor  di, di
        
        _final_draw_store_char:
            div  bx
            add  dx, 30H
            push dx
            xor  dx, dx
            inc  cx
            cmp  ax, 0
            jnz  _final_draw_store_char
                 
            mov  di, index
        _final_draw_num:
            pop  ax
            mov  num_stack[di], al
            call delay
            inc  di
            loop _final_draw_num
            
       _final_draw_end:
            mov  num_stack[di], ' '
            inc  di
            mov  index, di    
            pop  dx
            pop  cx
            pop  bx
            pop  ax
            ret
                   
    final_draw_num endp
    
    
    choose_order proc
        push ax
        push dx
        push ds
        
        ; mov cursor  
        mov ah,02h
        mov dh,9 
        mov dl,9+8
        int 10h       
        ; show helpful sentence     
        mov ax,change_order
        mov ds,ax
        mov dx,0h
        mov ah,09h
        int 21h
        
        ; read the choice
        mov  ah, 07H
        int  21H
        cmp  al, 6eH
        je   change_to_reverse
        cmp  al, 4eH
        je   change_to_reverse
        jmp  change_order_end
        
        change_to_reverse:
            mov ax, data
            mov ds, ax
            mov isReverse, 1
            
        change_order_end:
            pop ds
            pop dx
            pop ax
            ret
        
        
    choose_order endp
    
    
    clean_color proc
        push di
        push bx
        push ax
        push ds
        
        mov  di,160*3+68
		mov  bx, 0
		mov  ax, show_mem
		mov  ds, ax
		
		_clean_color_loop:
    		mov  es:[di], ' '
		    mov  es:[di+1], 7
		    add  di,160*2
		    inc  bx
		    cmp  bx, 4
		    jb   _clean_color_loop
       
       pop ds
       pop ax
       pop bx
       pop di
       ret 
        
        
    clean_color endp
    
ends

end start ; set entry point and stop the assembler.
