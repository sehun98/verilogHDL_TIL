#include "../../../inc/Driver/GPIO/gpio.h"
#include "xparameters.h"
#include <stdint.h>

void GPIO_Set_Direction(GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin, GPIO_ModeState Mode)
{
    if (Mode == GPIO_MODE_OUTPUT) {
        GPIOx->CR |= GPIO_Pin;
    } else {
        GPIOx->CR &= ~GPIO_Pin;
    }
}

GPIO_PinState GPIO_ReadPin(GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin)
{
    if ((GPIOx->IDR & GPIO_Pin) != 0U) {
        return GPIO_PIN_SET;
    } else {
        return GPIO_PIN_RESET;
    }
}

void GPIO_WritePin(GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin, GPIO_PinState PinState)
{
    if (PinState != GPIO_PIN_RESET) {
        GPIOx->ODR |= GPIO_Pin;
    } else {
        GPIOx->ODR &= ~GPIO_Pin;
    }
}

void GPIO_TogglePin(GPIO_TypeDef *GPIOx, uint16_t GPIO_Pin)
{
    GPIOx->ODR ^= GPIO_Pin;
}

uint32_t GPIO_ReadPort(GPIO_TypeDef *GPIOx)
{
    return GPIOx->IDR;
}
void GPIO_WritePort(GPIO_TypeDef *GPIOx, uint16_t PortData)
{
    GPIOx->ODR = (uint32_t) PortData;
}
