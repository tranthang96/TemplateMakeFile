#include "uart.h"

void init_uart(void)
{
    /* ==================================
    //STM32F103C8T6 
        RX = PA9
        TX = PA10
        CTS = PA11 (not used)
        RTS = PA12 (not used)
        Baud = 9600
    */

    // GPIO_USART1_TX on GPIO port A for tx
    gpio_set_mode(GPIOA, GPIO_MODE_OUTPUT_50_MHZ, GPIO_CNF_OUTPUT_ALTFN_PUSHPULL, GPIO_USART1_TX);
    
    usart_set_baudrate(USART1,9600);
    usart_set_databits(USART1,8);
    usart_set_stopbits(USART1,USART_STOPBITS_1);
    usart_set_mode(USART1,USART_MODE_TX);
    usart_set_parity(USART1,USART_PARITY_NONE);
    usart_set_flow_control(USART1,USART_FLOWCONTROL_NONE);

    // finally enable the uart
    usart_enable(USART1);



}
void uart_puts(char *string) {
    while (*string) {
        usart_send_blocking(USART1, *string);
        string++;
    }
}
void uart_putln(char *string) {
    uart_puts(string);
    uart_puts("\r\n");
}
