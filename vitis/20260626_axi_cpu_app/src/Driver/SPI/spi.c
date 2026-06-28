#include "../../../inc/Driver/SPI/spi.h"
#include <stddef.h>
#include <stdint.h>

void SPI_Init(SPI_TypeDef *SPIx)
{
    SPIx->CR = 0U;
    SPI_SetMasterSlave(SPIx, SPI_MSTR_MASTER);
    SPI_SetMode(SPIx, SPI_MODE_3);
    SPI_SetBaudRate(SPIx, SPI_BR_DIV32);
    SPI_SetDataBit(SPIx, SPI_DFF_16BIT);
    SPI_SetFirstBit(SPIx, SPI_FIRSTBIT_MSB);
}

void SPI_SetMode(SPI_TypeDef *SPIx, SPI_ModeState mode)
{
    SPIx->CR &= ~(SPI_CR_CPHA_Msk | SPI_CR_CPOL_Msk);
    SPIx->CR |= ((uint32_t)mode & 0x3U);
}

void SPI_SetBaudRate(SPI_TypeDef *SPIx, SPI_BaudRate_t baudRate)
{
    SPIx->CR &= ~SPI_CR_BRR_Msk;
    SPIx->CR |= ((uint32_t)baudRate << SPI_CR_BRR_Pos) & SPI_CR_BRR_Msk;
}

void SPI_SetDataBit(SPI_TypeDef *SPIx, SPI_DataBit_t dataBit)
{
    SPIx->CR &= ~SPI_CR_DFF_Msk;

    if (dataBit == SPI_DFF_16BIT) {
        SPIx->CR |= SPI_CR_DFF_Msk;
    }
}

void SPI_SetMasterSlave(SPI_TypeDef *SPIx, SPI_MasterSlave_t masterSlave)
{
    SPIx->CR &= ~SPI_CR_MSTR_Msk;

    if (masterSlave == SPI_MSTR_MASTER) {
        SPIx->CR |= SPI_CR_MSTR_Msk;
    }
}

void SPI_SetFirstBit(SPI_TypeDef *SPIx, SPI_LSBFirst_t firstBit)
{
    SPIx->CR &= ~SPI_CR_LSBFIRST_Msk;

    if (firstBit == SPI_FIRSTBIT_LSB) {
        SPIx->CR |= SPI_CR_LSBFIRST_Msk;
    }
}

void SPI_WriteData(SPI_TypeDef *SPIx, uint32_t data)
{
    SPIx->DR = data;
}

uint32_t SPI_ReadData(SPI_TypeDef *SPIx)
{
    return SPIx->DR;
}

void SPI_Start(SPI_TypeDef *SPIx)
{
    SPIx->CR |= SPI_CR_START_Msk;
}

uint32_t SPI_GetStatus(SPI_TypeDef *SPIx)
{
    return SPIx->SR;
}

uint32_t SPI_WaitDone(SPI_TypeDef *SPIx)
{
    uint32_t status;
    uint32_t timeout = SPI_TIMEOUT;

    while (timeout--) {
        status = SPI_GetStatus(SPIx);
        if (status & SPI_SR_RX_DONE_Msk) {
            return status;
        }
    }

    return SPI_GetStatus(SPIx);
}

uint32_t SPI_WaitDoneClear(SPI_TypeDef *SPIx)
{
    uint32_t status;
    uint32_t timeout = SPI_TIMEOUT;

    while (timeout--) {
        status = SPI_GetStatus(SPIx);
        if (!(status & SPI_SR_RX_DONE_Msk)) {
            return status;
        }
    }

    return SPI_GetStatus(SPIx);
}

uint32_t SPI_WaitBusyClear(SPI_TypeDef *SPIx)
{
    uint32_t status;
    uint32_t timeout = SPI_TIMEOUT;

    while (timeout--) {
        status = SPI_GetStatus(SPIx);
        if (!(status & SPI_SR_TX_BUSY_Msk)) {
            return status;
        }
    }

    return SPI_GetStatus(SPIx);
}

int SPI_TransmitReceive(SPI_TypeDef *SPIx, uint32_t txData, uint32_t *rxData)
{
    uint32_t status;

    status = SPI_WaitBusyClear(SPIx);
    if (status & SPI_SR_TX_BUSY_Msk) {
        return -1;
    }

    SPI_WriteData(SPIx, txData);
    SPI_Start(SPIx);

    status = SPI_WaitDoneClear(SPIx);
    if (status & SPI_SR_RX_DONE_Msk) {
        return -1;
    }

    status = SPI_WaitDone(SPIx);

    if (!(status & SPI_SR_RX_DONE_Msk)) {
        return -1;
    }

    if (rxData != NULL) {
        *rxData = SPI_ReadData(SPIx);
    }

    if (status & SPI_SR_ERROR_Msk) {
        return 1;
    }

    return 0;
}

int SPI_TransmitReceive8(SPI_TypeDef *SPIx, uint8_t txData, uint8_t *rxData)
{
    uint32_t rx;
    int ret;

    SPI_SetDataBit(SPIx, SPI_DFF_8BIT);
    ret = SPI_TransmitReceive(SPIx, txData, &rx);

    if (rxData != NULL) {
        *rxData = (uint8_t)rx;
    }

    return ret;
}

int SPI_TransmitReceive16(SPI_TypeDef *SPIx, uint16_t txData, uint16_t *rxData)
{
    uint32_t rx;
    int ret;

    SPI_SetDataBit(SPIx, SPI_DFF_16BIT);
    ret = SPI_TransmitReceive(SPIx, txData, &rx);

    if (rxData != NULL) {
        *rxData = (uint16_t)rx;
    }

    return ret;
}
