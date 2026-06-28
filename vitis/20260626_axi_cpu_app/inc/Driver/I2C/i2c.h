#ifndef INC_DRIVER_I2C_I2C_H_
#define INC_DRIVER_I2C_I2C_H_

#include <stdint.h>
#include <stdbool.h>

#define I2C_MASTER_BASE_ADDR    XPAR_AXI_I2C_MASTER_V1_0_0_BASEADDR

// I2C_CR bits
#define I2C_EN_Pos      0U
#define I2C_START_Pos   1U
#define I2C_STOP_Pos    2U
#define I2C_WRITE_Pos   3U
#define I2C_READ_Pos    4U
#define I2C_ACK_Pos     5U

#define I2C_EN_Msk      (1U << I2C_EN_Pos)
#define I2C_START_Msk   (1U << I2C_START_Pos)
#define I2C_STOP_Msk    (1U << I2C_STOP_Pos)
#define I2C_WRITE_Msk   (1U << I2C_WRITE_Pos)
#define I2C_READ_Msk    (1U << I2C_READ_Pos)
#define I2C_ACK_Msk     (1U << I2C_ACK_Pos)

#define I2C_SR_BUSY_Pos   0U
#define I2C_SR_DONE_Pos   1U
#define I2C_SR_NACK_Pos   2U
#define I2C_SR_ARLOS_Pos  3U

#define I2C_SR_BUSY_Msk   (1U << I2C_SR_BUSY_Pos)
#define I2C_SR_DONE_Msk   (1U << I2C_SR_DONE_Pos)
#define I2C_SR_NACK_Msk   (1U << I2C_SR_NACK_Pos)
#define I2C_SR_ARLOS_Msk  (1U << I2C_SR_ARLOS_Pos)



#define I2C ((I2C_TypeDef *)I2C_MASTER_BASE_ADDR)

typedef struct
{
    volatile uint32_t CR;  /*!< I2C Control register,             Address offset: 0x00 */
    volatile uint32_t SR; /*!< I2C Status register,               Address offset: 0x04 */
    volatile uint32_t DR; /*!< I2C Data register,                 Address offset: 0x08 */
    volatile uint32_t CLKDIV; /*!< I2C Clock Div register,        Address offset: 0x0C */
} I2C_TypeDef;

uint32_t I2C_GetStatus(I2C_TypeDef* I2Cx);
uint32_t I2C_WaitDone(I2C_TypeDef* I2Cx);
uint32_t I2C_WaitDoneClear(I2C_TypeDef* I2Cx);
uint32_t I2C_ExecuteCommand(I2C_TypeDef* I2Cx, uint32_t command);
void I2C_Init(I2C_TypeDef* I2Cx);
void I2C_SetClockDivider(I2C_TypeDef* I2Cx, uint32_t divider);
int I2C_WriteByte(I2C_TypeDef* I2Cx, uint8_t byte);
int I2C_ReadByte(I2C_TypeDef* I2Cx, uint8_t *byte, bool sendAck);
uint32_t I2C_Start(I2C_TypeDef* I2Cx);
uint32_t I2C_Stop(I2C_TypeDef* I2Cx);

#endif /* INC_DRIVER_I2C_I2C_H_ */
