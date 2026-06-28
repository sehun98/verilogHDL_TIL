#include "../../../inc/Driver/I2C/i2c.h"
#include "../../../inc/App/CLCD1602/clcd1602.h"
#include "xparameters.h"
#include "sleep.h"
#include <stdint.h>
#include <stdbool.h>


void delay_us(uint32_t us)
{
    usleep(us);
}

void delay_ms(uint32_t ms)
{
    usleep(ms * 1000);
}

void LCD_WriteExpander(I2C_TypeDef* I2Cx, uint8_t data)
{
    I2C_Start(I2Cx);
    I2C_WriteByte(I2Cx, LCD_I2C_WRITE_ADDR);
    I2C_WriteByte(I2Cx, data);
    I2C_Stop(I2Cx);
}

void LCD_Write4Bits(I2C_TypeDef* I2Cx, uint8_t nibble, LCD_Mode mode)
{
    uint8_t data;

    data = (nibble & 0xF0) | LCD_BACKLIGHT_Msk;
    if (mode == LCD_MODE_DATA) {
        data |= LCD_RS_Msk;
    }

    LCD_WriteExpander(I2Cx, data | LCD_EN_Msk);
    delay_us(1);
    LCD_WriteExpander(I2Cx, data & ~LCD_EN_Msk);
    delay_us(50);
}

void LCD_WriteByte(I2C_TypeDef* I2Cx, uint8_t data, LCD_Mode mode)
{
    LCD_Write4Bits(I2Cx, data & 0xF0, mode);
    LCD_Write4Bits(I2Cx, (data << 4) & 0xF0, mode);
}

void LCD_SendCommand(I2C_TypeDef* I2Cx, uint8_t command)
{
    LCD_WriteByte(I2Cx, command, LCD_MODE_COMMAND);
    if (command == 0x01 || command == 0x02) {
        delay_ms(2);
    }
}

void LCD_SendData(I2C_TypeDef* I2Cx, uint8_t data)
{
    LCD_WriteByte(I2Cx, data, LCD_MODE_DATA);
}

void LCD_Init(I2C_TypeDef* I2Cx)
{
    delay_ms(50);
    LCD_Write4Bits(I2Cx, 0x30, LCD_MODE_COMMAND);
    delay_ms(5);

    LCD_Write4Bits(I2Cx, 0x30, LCD_MODE_COMMAND);
    delay_us(150);

    LCD_Write4Bits(I2Cx, 0x30, LCD_MODE_COMMAND);
    delay_us(150);

    LCD_Write4Bits(I2Cx, 0x20, LCD_MODE_COMMAND);
    delay_us(150);

    LCD_SendCommand(I2Cx, 0x28); // 4-bit, 2-line, 5x8 font
    LCD_SendCommand(I2Cx, 0x08); // display off
    LCD_SendCommand(I2Cx, 0x01); // clear display
    LCD_SendCommand(I2Cx, 0x06); // entry mode: increment

    LCD_SendCommand(I2Cx, 0x0C); // display on, cursor off
}

void LCD_SetCursor(I2C_TypeDef* I2Cx, uint8_t row, uint8_t col)
{
    static const uint8_t row_addr[] = {0x00, 0x40};

    if (row > 1) {
        row = 1;
    }
    if (col > 15) {
        col = 15;
    }

    LCD_SendCommand(I2Cx, 0x80 | (row_addr[row] + col));
}

void LCD_Print(I2C_TypeDef* I2Cx, const char *string)
{
    while (*string) {
        LCD_SendData(I2Cx, (uint8_t)*string++);
    }
}

void LCD_Clear(I2C_TypeDef* I2Cx)
{
	LCD_SendCommand(I2Cx, 0x01);
}
