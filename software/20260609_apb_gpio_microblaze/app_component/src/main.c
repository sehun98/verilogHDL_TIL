#include <stdint.h>

#define GPIO_BASE 0x40001000U
#define GPIO_CRH  (*(volatile uint32_t *)(GPIO_BASE + 0x04))
#define GPIO_ODR  (*(volatile uint32_t *)(GPIO_BASE + 0x0C))

static void delay(void)
{
    for (volatile int i = 0; i < 1000000; i++);
}

int main(void)
{
    GPIO_CRH = 0x33333333;  // gpio_pin[8]~[15] output

    while (1)
    {
        // 0000 0101 0101
        GPIO_ODR = 0x00005500;
        delay();

        GPIO_ODR = 0x00000000;
        delay();
    }

    return 0;
}
