#ifndef INC_DRIVER_SPI_SPI_H_
#define INC_DRIVER_SPI_SPI_H_

#include "xparameters.h"
#include <stdint.h>

#define SPI_BASE XPAR_AXI_SPI_MASTER_V1_0_0_BASEADDR

// Register map
// 0x00: CR
// 0x04: SR
// 0x08: DR write = TX_DATA, read = RX_DATA
typedef struct
{
    volatile uint32_t CR;  /*!< SPI control register, Address offset: 0x00 */
    volatile uint32_t SR;  /*!< SPI status register,  Address offset: 0x04 */
    volatile uint32_t DR;  /*!< SPI data register,    Address offset: 0x08 */
} SPI_TypeDef;

#define SPI ((SPI_TypeDef *)SPI_BASE)

typedef enum
{
    SPI_MODE_0 = 0U,   // CPOL = 0, CPHA = 0
    SPI_MODE_1 = 1U,   // CPOL = 0, CPHA = 1
    SPI_MODE_2 = 2U,   // CPOL = 1, CPHA = 0
    SPI_MODE_3 = 3U    // CPOL = 1, CPHA = 1
} SPI_ModeState;

typedef enum
{
    SPI_BR_DIV2   = 0U,   // SPI_CLK = 100MHz / 2   = 50.000 MHz
    SPI_BR_DIV4   = 1U,   // SPI_CLK = 100MHz / 4   = 25.000 MHz
    SPI_BR_DIV8   = 2U,   // SPI_CLK = 100MHz / 8   = 12.500 MHz
    SPI_BR_DIV16  = 3U,   // SPI_CLK = 100MHz / 16  = 6.250 MHz
    SPI_BR_DIV32  = 4U,   // SPI_CLK = 100MHz / 32  = 3.125 MHz
    SPI_BR_DIV64  = 5U,   // SPI_CLK = 100MHz / 64  = 1.5625 MHz
    SPI_BR_DIV128 = 6U,   // SPI_CLK = 100MHz / 128 = 781.25 kHz
    SPI_BR_DIV256 = 7U    // SPI_CLK = 100MHz / 256 = 390.625 kHz
} SPI_BaudRate_t;

typedef enum
{
    SPI_DFF_8BIT  = 0U,
    SPI_DFF_16BIT = 1U
} SPI_DataBit_t;

typedef enum
{
    SPI_MSTR_SLAVE  = 0U,
    SPI_MSTR_MASTER = 1U
} SPI_MasterSlave_t;

typedef enum
{
    SPI_FIRSTBIT_MSB = 0U,
    SPI_FIRSTBIT_LSB = 1U
} SPI_LSBFirst_t;

// SPI_CR
// reserved[31:9] LSBFirst[8] DFF[7] MSTR[6] start[5] spi_br[4:2] cpol[1] cpha[0]
#define SPI_CR_CPHA_Pos        0U
#define SPI_CR_CPOL_Pos        1U
#define SPI_CR_BRR_Pos         2U
#define SPI_CR_START_Pos       5U
#define SPI_CR_MSTR_Pos        6U
#define SPI_CR_DFF_Pos         7U
#define SPI_CR_LSBFIRST_Pos    8U

#define SPI_CR_CPHA_Msk        (1U << SPI_CR_CPHA_Pos)
#define SPI_CR_CPOL_Msk        (1U << SPI_CR_CPOL_Pos)
#define SPI_CR_BRR_Msk         (0x7U << SPI_CR_BRR_Pos)
#define SPI_CR_START_Msk       (1U << SPI_CR_START_Pos)
#define SPI_CR_MSTR_Msk        (1U << SPI_CR_MSTR_Pos)
#define SPI_CR_DFF_Msk         (1U << SPI_CR_DFF_Pos)
#define SPI_CR_LSBFIRST_Msk    (1U << SPI_CR_LSBFIRST_Pos)

// SPI_SR
// reserved[31:4] tx_busy[3] tx_overrun_error[2] rx_done[1] rx_frame_error[0]
#define SPI_SR_RX_FRAME_ERROR_Pos      0U
#define SPI_SR_RX_DONE_Pos             1U
#define SPI_SR_TX_OVERRUN_ERROR_Pos    2U
#define SPI_SR_TX_BUSY_Pos             3U

#define SPI_SR_RX_FRAME_ERROR_Msk      (1U << SPI_SR_RX_FRAME_ERROR_Pos)
#define SPI_SR_RX_DONE_Msk             (1U << SPI_SR_RX_DONE_Pos)
#define SPI_SR_TX_OVERRUN_ERROR_Msk    (1U << SPI_SR_TX_OVERRUN_ERROR_Pos)
#define SPI_SR_TX_BUSY_Msk             (1U << SPI_SR_TX_BUSY_Pos)
#define SPI_SR_ERROR_Msk               (SPI_SR_RX_FRAME_ERROR_Msk | SPI_SR_TX_OVERRUN_ERROR_Msk)

#define SPI_TIMEOUT                    100000U

void SPI_Init(SPI_TypeDef *SPIx);

void SPI_SetMode(SPI_TypeDef *SPIx, SPI_ModeState mode);
void SPI_SetBaudRate(SPI_TypeDef *SPIx, SPI_BaudRate_t baudRate);
void SPI_SetDataBit(SPI_TypeDef *SPIx, SPI_DataBit_t dataBit);
void SPI_SetMasterSlave(SPI_TypeDef *SPIx, SPI_MasterSlave_t masterSlave);
void SPI_SetFirstBit(SPI_TypeDef *SPIx, SPI_LSBFirst_t firstBit);

void SPI_WriteData(SPI_TypeDef *SPIx, uint32_t data);
uint32_t SPI_ReadData(SPI_TypeDef *SPIx);

void SPI_Start(SPI_TypeDef *SPIx);
uint32_t SPI_GetStatus(SPI_TypeDef *SPIx);
uint32_t SPI_WaitDone(SPI_TypeDef *SPIx);
uint32_t SPI_WaitDoneClear(SPI_TypeDef *SPIx);
uint32_t SPI_WaitBusyClear(SPI_TypeDef *SPIx);

int SPI_TransmitReceive(SPI_TypeDef *SPIx, uint32_t txData, uint32_t *rxData);
int SPI_TransmitReceive8(SPI_TypeDef *SPIx, uint8_t txData, uint8_t *rxData);
int SPI_TransmitReceive16(SPI_TypeDef *SPIx, uint16_t txData, uint16_t *rxData);

#endif /* INC_DRIVER_SPI_SPI_H_ */
