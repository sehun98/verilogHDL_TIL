#include "../../../inc/Driver/FND/fnd.h"
#include "xparameters.h"
#include <stdint.h>

void FND_Init(void)
{
	FND->BRR = 1000;
}
void FND_Display_On(void)
{
    FND->CR |= 0x01U;
}

void FND_Display_Off(void)
{
    FND->CR &= ~0x01U;
}

void FND_Data(uint16_t data)
{
    FND->DR = (uint32_t)data;
}