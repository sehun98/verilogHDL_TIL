#include "../../../inc/Driver/UART/uart.h"
#include "xparameters.h"
#include <stdint.h>

void UART_WriteByte(UART_TypeDef *UARTx, uint8_t data)
{
    while ((UARTx->SR & UART_SR_TXF_Msk) != 0U) {
        // TX FIFO full이면 대기
    }

    UARTx->DR = (uint32_t)data;
}

void UART_WriteString(UART_TypeDef *UARTx, const char *str)
{
    while (*str != '\0') {
        UART_WriteByte(UARTx, (uint8_t)(*str));
        str++;
    }
}

uint8_t UART_ReadByte(UART_TypeDef *UARTx)
{
    while ((UARTx->SR & UART_SR_RXE_Msk) != 0U) {
        // RX FIFO empty이면 대기
    }

    return (uint8_t)(UARTx->DR & 0xFFU);
}

uint32_t UART_ReadByteNonBlocking(UART_TypeDef *UARTx, uint8_t *data)
{
    if ((UARTx->SR & UART_SR_RXE_Msk) != 0U) {
        return 0U;   // no data
    }

    *data = (uint8_t)(UARTx->DR & 0xFFU);
    return 1U;       // read success
}

uint32_t UART_WriteByteNonBlocking(UART_TypeDef *UARTx, uint8_t data)
{
    if ((UARTx->SR & UART_SR_TXF_Msk) != 0U) {
        return 0U;   // TX full
    }

    UARTx->DR = (uint32_t)data;
    return 1U;       // write success
}

void UART_Init(UART_TypeDef *UARTx, uint32_t baudrate)
{
    uint32_t brr_code;
    switch (baudrate)
    {
        case 9600U:
            brr_code = UART_BRR_9600;
            break;
        case 19200U:
            brr_code = UART_BRR_19200;
            break;
        case 38400U:
            brr_code = UART_BRR_38400;
            break;
        case 57600U:
            brr_code = UART_BRR_57600;
            break;
        case 115200U:
            brr_code = UART_BRR_115200;
            break;
        case 230400U:
            brr_code = UART_BRR_230400;
            break;
        default:
            brr_code = UART_BRR_9600;
            break;
    }

    UARTx->CR &= ~UART_CR_BRR_Msk;
    UARTx->CR |= (brr_code << UART_CR_BRR_Pos);

    UARTx->CR |= (UART_CR_RXE_Msk | UART_CR_TXE_Msk | UART_CR_UE_Msk);
}

void UART_EnableInterrupt(UART_TypeDef *UARTx, uint32_t interruptMask)
{
    UARTx->IER |= interruptMask;
}

void UART_DisableInterrupt(UART_TypeDef *UARTx, uint32_t interruptMask)
{
    UARTx->IER &= ~interruptMask;
}

uint32_t UART_GetInterruptFlag(UART_TypeDef *UARTx, uint32_t interruptMask)
{
    return (UARTx->IFR & interruptMask);
}

uint32_t UART_GetPendingInterrupt(UART_TypeDef *UARTx)
{
    return (UARTx->IFR & UARTx->IER);
}

void UART_ClearInterruptFlag(UART_TypeDef *UARTx, uint32_t interruptMask)
{
    UARTx->ICR = interruptMask;
}
