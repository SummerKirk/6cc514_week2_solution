# When the PC starts, the processor is essentially emulating an 8086 processor, i.e. 
# a 16-bit processor.  So our initial boot loader code is 16-bit code that will 
# eventually switch the processor into 32-bit mode.

# This code is linked to assume a starting address of 0x7C00 which is where the BIOS
# will load a boot segment.

.code16                         # Assemble for 16-bit mode
.globl start
start:
    jmp     real_start

# Write to the console using BIOS.
# 
# Input: SI contains the address of the null-terminated string to be displayed

cons_write:
    movb    $0x0e, %ah           # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen

cons_write_rpt:
    movb    (%si), %al          # Load the byte at the location contained in the SI register into AL   
    inc     %si                 # Add 1 to the value in SI
    cmp     $0, %al             # Compare the value in AL with 0
    jz      cons_write_done     # If it is zero, then we are done
    int     $0x10               # Output the character in AL to the screen
    jmp     cons_write_rpt      # and continue

cons_write_done:                # Something that is called will never return 
    ret                         # until a 'ret' instruction is encountered.  Labels do 
                                # not give a program any structure.  They just give a 
                                # memory location a name that we can use in our code. 

cons_write_crlf:
    movb    $0x0e, %ah          # Output CR
    movb    $0x0d, %al
    int     $0x10
    movb    $0x0a, %al          # Output LF
    int     $0x10
    ret

cons_writeline:
    call    cons_write
    call    cons_write_crlf
    ret    


cons_write_int:
    movw %bx, %ax               # put bx into ax
    movw $int_starter + 5, %si      # set up string with placeholder
cons_create_int_rpt:
    call divide_by_ten          # call div to get our remainder
    # fish for remainder in dx (it's dl)
    add $48, %dl                # add 48 to it
    movb %dl, (%si)             # add remainder+48 (stored in) to string
    dec %si                     # reduce string
    cmp $0, %ax                 # compare ax to 0
    jnz cons_create_int_rpt     # keep creating the value if not 0
    call cons_writeline         # if 0, will fall throgh to writeline call    
cons_write_int_done:
    ret

divide_by_ten:
    xor %dx, %dx
    movw $10, %cx
    div %cx                     # remainder will be in dx
    ret


cons_write_hex:
    movw %bx, %ax
    movw $int_starter + 4, %si
    movw $hex_lookup, %di       # put lookup in di
create_hex_rpt:
    call divide_by_sixteen      # need to turn bx into hex
    movb $0, (%di)                # reset di (overwriting (di) would overweite what it's pointing to)
    add %dl, (%di)              # lookup table, dl is added to di's incriment
    movw %di, (%si)             # put di contents at si REMMEBER TO RESET DI
    dec %si
    cmp $0, %ax                 # compare ax to 0
    jnz create_hex_rpt     # keep creating the value if not 0
    call cons_writeline
cons_write_hex_done:
    ret

divide_by_sixteen:
    xor %dx, %dx
    movw $10, %cx
    div %cx
    ret

real_start:
    movb    %dl, (boot_device) # Boot device number is passed in DL from BIOS. Save it hear since DL might get trashed

    movw    $boot_message, %si  # Display our boot message - load string stored in boot message method into SI
    call    cons_writeline      # display boot message

    movw    $booted_from_msg, %si
    call    cons_write

    movw $0xFFFF, %bx             # number malarkey
    call cons_write_int

    movw $65535, %bx             # number malarkey
    call cons_write_hex

    movb    (boot_device), %dl
    cmp     $0x80, %dl
    jge     harddrive

    movw    $fd, %si
    jmp     finish

harddrive:
    movw    $hd, %si

finish:
    call    cons_writeline

endless_loop:                   # Loop forever more
    jmp     endless_loop    

# Program data

boot_device:
    .byte   0

boot_message:     
    .string "Boot Loader Stage 2 loaded"             
booted_from_msg:
    .string "Booting from "
fd: .string "floppy disk"
hd: .string "hard drive"

int_starter:
    .string "place"
hex_lookup:
    .ascii "123456789abcdef"