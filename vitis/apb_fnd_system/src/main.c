#include <stdint.h>

#define FND_BASE 0x40004000U
#define FND_CR  (*(volatile uint32_t *)(FND_BASE + 0x00))
#define FND_DR  (*(volatile uint32_t *)(FND_BASE + 0x04))

void delay(void){
	for(int i = 0; i < 100000000; i++);
}

int main(void)
{
	FND_CR = 0x00000000;

	while(1)
	{
		FND_DR = 1234;

	}
	return 0;
}
