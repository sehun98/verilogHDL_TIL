#include <stdint.h>

#define AXI_UART_S00_AXI_UART_CR_OFFSET   0
#define AXI_UART_S00_AXI_UART_SR_OFFSET   4
#define AXI_UART_S00_AXI_UART_BRR_OFFSET  8
#define AXI_UART_S00_AXI_UART_DR_OFFSET   12
#define AXI_UART_S00_AXI_UART_IER_OFFSET  16
#define AXI_UART_S00_AXI_UART_IFR_OFFSET  20
#define AXI_UART_S00_AXI_UART_ICR_OFFSET  24

#define AXI_UART_S00_AXI_UART_BASE 0x44A00000U

#define UART_REG(offset) (*(volatile uint32_t *)(AXI_UART_S00_AXI_UART_BASE + (offset)))

#define UART_CR   UART_REG(AXI_UART_S00_AXI_UART_CR_OFFSET)
#define UART_SR   UART_REG(AXI_UART_S00_AXI_UART_SR_OFFSET)
#define UART_BRR  UART_REG(AXI_UART_S00_AXI_UART_BRR_OFFSET)
#define UART_DR   UART_REG(AXI_UART_S00_AXI_UART_DR_OFFSET)
#define UART_IER  UART_REG(AXI_UART_S00_AXI_UART_IER_OFFSET)
#define UART_IFR  UART_REG(AXI_UART_S00_AXI_UART_IFR_OFFSET)
#define UART_ICR  UART_REG(AXI_UART_S00_AXI_UART_ICR_OFFSET)

#define UART_CR_RE    (1 << 0)
#define UART_CR_TE    (1 << 1)
#define UART_CR_UE    (1 << 2)

#define UART_SR_RXE   (1 << 0)   // RX FIFO empty
#define UART_SR_RXD   (1 << 1)   // RX data available
#define UART_SR_RXF   (1 << 2)
#define UART_SR_TXE   (1 << 3)
#define UART_SR_TXD   (1 << 4)
#define UART_SR_TXF   (1 << 5)   // TX FIFO full
#define UART_SR_BUSY  (1 << 6)

#define UART_ICR_TXIC    (1 << 0)
#define UART_ICR_TXOVRC  (1 << 2)
#define UART_ICR_RXOVRC  (1 << 3)
#define UART_ICR_FEC     (1 << 4)

static void uart_init(void)
{
    // interrupt 사용 안 함
    UART_IER = 0x00000000;

    // error / tx interrupt flag clear
    UART_ICR = UART_ICR_TXIC | UART_ICR_TXOVRC | UART_ICR_RXOVRC | UART_ICR_FEC;

    // baudrate 설정
    UART_BRR = 115200;

    // UART enable, TX enable, RX enable
    UART_CR = UART_CR_UE | UART_CR_TE | UART_CR_RE;
}

static void uart_putc(uint8_t data)
{
    // TX FIFO full이면 대기
    while (UART_SR & UART_SR_TXF) {
    }

    UART_DR = data;
}

static uint8_t uart_getc(void)
{
    // RX FIFO empty이면 대기
    while (UART_SR & UART_SR_RXE) {
    }

    return (uint8_t)(UART_DR & 0xFF);
}

int main(void)
{
    uint8_t rx_data;

    uart_init();

    while (1) {
        // 1 byte 송신

        // loopback으로 돌아온 1 byte 수신
        rx_data = uart_getc();
        uart_putc(rx_data);


    }

    return 0;
}