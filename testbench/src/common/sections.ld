ENTRY( _start )

__stack_size = 4096;
PROVIDE( _stack_size = __stack_size );

MEMORY
{
    FLASH (rx) : ORIGIN = 0xFFFF0000, LENGTH = 0x1000
    RAM (xrw) : ORIGIN = 0xFFFF1000, LENGTH = 0x1000
}

SECTIONS
{
    .text ORIGIN(FLASH) : 
    { 
        *(.text) 
    }
    .stack ORIGIN(RAM) + LENGTH(RAM) - __stack_size :
    {
        . = ALIGN(4);
        PROVIDE( _susrstack = . );
        . = . + __stack_size;
        PROVIDE( _eusrstack = . );
    } >RAM
}
