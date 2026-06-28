#include "../../../inc/Driver/I2C/i2c.h"
#include "xparameters.h"
#include <stdint.h>
#include <stdbool.h>

uint32_t I2C_GetStatus(I2C_TypeDef* I2Cx)
{
    return I2Cx->SR;
}

uint32_t I2C_WaitDone(I2C_TypeDef* I2Cx)
{
    uint32_t status;
    uint32_t timeout = 100000;

    while (timeout--) {
        status = I2C_GetStatus(I2Cx);
        if (status & I2C_SR_DONE_Msk) {
            return status;
        }
    }
    return I2C_GetStatus(I2Cx);
}

uint32_t I2C_WaitDoneClear(I2C_TypeDef* I2Cx)
{
    uint32_t status;
    uint32_t timeout = 100000;

    while (timeout--) {
        status = I2C_GetStatus(I2Cx);
        if (!(status & I2C_SR_DONE_Msk)) {
            return status;
        }
    }
    return I2C_GetStatus(I2Cx);
}

uint32_t I2C_ExecuteCommand(I2C_TypeDef* I2Cx, uint32_t command)
{
    uint32_t status;

    I2Cx->CR = I2C_EN_Msk | command;
    
    I2C_WaitDoneClear(I2Cx);
    status = I2C_WaitDone(I2Cx);

    I2Cx->CR = I2C_EN_Msk;

    return status;
}

void I2C_Init(I2C_TypeDef* I2Cx)
{
    I2Cx->CR = I2C_EN_Msk;
}

void I2C_SetClockDivider(I2C_TypeDef* I2Cx, uint32_t divider)
{
    I2Cx->CLKDIV = divider;
}

int I2C_WriteByte(I2C_TypeDef* I2Cx, uint8_t byte)
{
    uint32_t status;

    I2Cx->DR = byte;
    status = I2C_ExecuteCommand(I2Cx, I2C_WRITE_Msk);
    if (!(status & I2C_SR_DONE_Msk)) {
        return -1;
    }
    if (status & I2C_SR_NACK_Msk) {
        return 1;
    }
    return 0;
}

int I2C_ReadByte(I2C_TypeDef* I2Cx, uint8_t *byte, bool sendAck)
{
    uint32_t status;

    status = I2C_ExecuteCommand(I2Cx, I2C_READ_Msk | (sendAck ? I2C_ACK_Msk : 0));
    *byte = (uint8_t)I2Cx->DR;
    if (!(status & I2C_SR_DONE_Msk)) {
        return -1;
    }
    if (status & I2C_SR_NACK_Msk) {
        return 1;
    }
    return 0;
}

uint32_t I2C_Start(I2C_TypeDef* I2Cx)
{
    return I2C_ExecuteCommand(I2Cx, I2C_START_Msk);
}

uint32_t I2C_Stop(I2C_TypeDef* I2Cx)
{
    return I2C_ExecuteCommand(I2Cx, I2C_STOP_Msk);
}