#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/usart.h>
#include <libopencm3/stm32/i2c.h>
#include "uart.h"


static void clock_int(void)
{
	rcc_clock_setup_in_hse_8mhz_out_72mhz();
	rcc_periph_clock_enable(RCC_GPIOA);
	rcc_periph_clock_enable(RCC_GPIOB);
	rcc_periph_clock_enable(RCC_GPIOC);
}
static void gpio_init(void)
{
	gpio_set_mode(GPIOA,GPIO_MODE_OUTPUT_2_MHZ, GPIO_CNF_OUTPUT_PUSHPULL,GPIO11);
}

int main(void)
{
	int i;
	clock_int();
	gpio_init();
	uart_init();

	while(1)
	{
		uart_putln("led on");
        gpio_set(GPIOA, GPIO11);
    		for (i = 0; i < 1500000; i++)	/* Wait a bit. */
			__asm__("nop");
        uart_putln("LED off");
        gpio_clear(GPIOA, GPIO11);
     		for (i = 0; i < 1500000; i++)	/* Wait a bit. */
			__asm__("nop");
	}
}
