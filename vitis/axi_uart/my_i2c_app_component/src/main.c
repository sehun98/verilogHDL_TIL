#include <stdint.h>

#define REG32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))
#define W32(addr, data) (REG32(addr) = (uint32_t)(data))
#define R32(addr)       (REG32(addr))

// Address Editor에서 네 I2C IP base address로 수정
#define I2C_BASEADDR      0x44A00000U

#define I2C_CR            (I2C_BASEADDR + 0x00U)
#define I2C_SR            (I2C_BASEADDR + 0x04U)
#define I2C_WDATA         (I2C_BASEADDR + 0x08U)
#define I2C_RDATA         (I2C_BASEADDR + 0x0CU)
#define I2C_CLKDIV        (I2C_BASEADDR + 0x10U)

// CR bits
#define I2C_EN            (1U << 0)
#define I2C_START         (1U << 1)
#define I2C_STOP          (1U << 2)
#define I2C_WRITE         (1U << 3)

// SR bits
#define I2C_DONE          (1U << 1)
#define I2C_NACK          (1U << 2)
#define I2C_ARLOS         (1U << 3)

// 100MHz 기준 100kHz
#define I2C_CLKDIV_100K   250U

// I2C LCD 주소: 보통 0x27 또는 0x3F
#define LCD_ADDR          0x27U
// #define LCD_ADDR        0x3FU

// PCF8574 일반 LCD backpack mapping
#define LCD_RS            0x01U
#define LCD_RW            0x02U
#define LCD_EN            0x04U
#define LCD_BL            0x08U

volatile uint32_t debug_status;

static void delay(volatile uint32_t n)
{
    while (n--) {
        __asm__ volatile ("nop");
    }
}

static void delay_ms(uint32_t ms)
{
    while (ms--) {
        delay(10000U);
    }
}

static int i2c_wait_done(void)
{
    uint32_t timeout = 1000000U;

    while (timeout--) {
        uint32_t sr = R32(I2C_SR);

        if (sr & I2C_DONE) {
            if (sr & I2C_ARLOS) {
                debug_status = 0xE001U;
                return -1;
            }
            return 0;
        }
    }

    debug_status = 0xE002U;
    return -1;
}

static int i2c_cmd(uint32_t cmd)
{
    uint32_t timeout;

    // command bit clear
    W32(I2C_CR, I2C_EN);
    delay(1000);

    // command bit rising edge
    W32(I2C_CR, I2C_EN | cmd);

    // 이전 DONE sticky가 내려가는 것 대기
    timeout = 100000U;
    while ((R32(I2C_SR) & I2C_DONE) && timeout--) {
        ;
    }
    if (R32(I2C_SR) & I2C_DONE) {
        debug_status = 0xE004U;
        return -1;
    }

    if (i2c_wait_done() != 0) {
        return -1;
    }

    // 다음 command를 위해 clear
    W32(I2C_CR, I2C_EN);
    delay(1000);

    return 0;
}

static int i2c_start(void)
{
    return i2c_cmd(I2C_START);
}

static int i2c_stop(void)
{
    return i2c_cmd(I2C_STOP);
}

static int i2c_write(uint8_t data)
{
    W32(I2C_WDATA, data);

    if (i2c_cmd(I2C_WRITE) != 0) {
        return -1;
    }

    if (R32(I2C_SR) & I2C_NACK) {
        debug_status = 0xE003U;
        return -1;
    }

    return 0;
}

static int pcf8574_write(uint8_t data)
{
    if (i2c_start() != 0) {
        return -1;
    }

    // slave address + write bit
    if (i2c_write((uint8_t)(LCD_ADDR << 1)) != 0) {
        i2c_stop();
        return -1;
    }

    if (i2c_write(data) != 0) {
        i2c_stop();
        return -1;
    }

    if (i2c_stop() != 0) {
        return -1;
    }

    delay(2000);
    return 0;
}

static int lcd_pulse(uint8_t data)
{
    if (pcf8574_write(data | LCD_EN) != 0) {
        return -1;
    }
    delay(2000);

    if (pcf8574_write(data & ~LCD_EN) != 0) {
        return -1;
    }
    delay(2000);

    return 0;
}

static int lcd_write4(uint8_t nibble, uint8_t rs)
{
    uint8_t data;

    data = (uint8_t)((nibble & 0x0F) << 4);
    data |= LCD_BL;

    if (rs) {
        data |= LCD_RS;
    }

    return lcd_pulse(data);
}

static int lcd_cmd(uint8_t cmd)
{
    if (lcd_write4((uint8_t)(cmd >> 4), 0) != 0) {
        return -1;
    }
    if (lcd_write4((uint8_t)(cmd & 0x0F), 0) != 0) {
        return -1;
    }
    delay_ms(2);

    return 0;
}

static int lcd_data(uint8_t data)
{
    if (lcd_write4((uint8_t)(data >> 4), 1) != 0) {
        return -1;
    }
    if (lcd_write4((uint8_t)(data & 0x0F), 1) != 0) {
        return -1;
    }
    delay_ms(1);

    return 0;
}

static int lcd_init(void)
{
    delay_ms(50);

    // 4-bit init sequence
    if (lcd_write4(0x03, 0) != 0) {
        return -1;
    }
    delay_ms(5);

    if (lcd_write4(0x03, 0) != 0) {
        return -1;
    }
    delay_ms(5);

    if (lcd_write4(0x03, 0) != 0) {
        return -1;
    }
    delay_ms(5);

    if (lcd_write4(0x02, 0) != 0) {
        return -1;
    }
    delay_ms(5);

    if (lcd_cmd(0x28) != 0) { // 4-bit, 2-line
        return -1;
    }
    if (lcd_cmd(0x08) != 0) { // display off
        return -1;
    }
    if (lcd_cmd(0x01) != 0) { // clear
        return -1;
    }
    delay_ms(5);
    if (lcd_cmd(0x06) != 0) { // entry mode
        return -1;
    }
    if (lcd_cmd(0x0C) != 0) { // display on, cursor off
        return -1;
    }

    return 0;
}

int main(void)
{
    debug_status = 0x00000001U;

    // I2C init
    W32(I2C_CR, 0x00000000U);
    delay_ms(1);

    W32(I2C_CLKDIV, I2C_CLKDIV_100K);
    delay_ms(1);

    W32(I2C_CR, I2C_EN);
    delay_ms(10);

    debug_status = 0x00000002U;

    // LCD init
    if (lcd_init() != 0) {
        while (1) {
            ;
        }
    }

    debug_status = 0x00000003U;

    // 첫 번째 줄에 AAAA
    if (lcd_cmd(0x80) != 0) {
        while (1) {
            ;
        }
    }
    if (lcd_data('A') != 0) {
        while (1) {
            ;
        }
    }
    if (lcd_data('A') != 0) {
        while (1) {
            ;
        }
    }
    if (lcd_data('A') != 0) {
        while (1) {
            ;
        }
    }
    if (lcd_data('A') != 0) {
        while (1) {
            ;
        }
    }

    // 두 번째 줄에 1234
    if (lcd_cmd(0xC0) != 0) {
        while (1) {
            ;
        }
    }
    if (lcd_data('1') != 0) {
        while (1) {
            ;
        }
    }
    if (lcd_data('2') != 0) {
        while (1) {
            ;
        }
    }
    if (lcd_data('3') != 0) {
        while (1) {
            ;
        }
    }
    if (lcd_data('4') != 0) {
        while (1) {
            ;
        }
    }

    debug_status = 0x00000004U;

    while (1) {
        ;
    }

    return 0;
}
