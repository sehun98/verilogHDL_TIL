#ifndef INC_DRIVER_FND_FND_H_
#define INC_DRIVER_FND_FND_H_

#include <stdint.h>

#define FND_BASE XPAR_AXI_FND_V1_0_0_BASEADDR

typedef struct
{
    volatile uint32_t CR; /*!< FND control register,                   Address offset: 0x00 */
    volatile uint32_t DR; /*!< FND DATA register,                      Address offset: 0x04 */
    volatile uint32_t BRR;
} FND_TypeDef;

#define FND ((FND_TypeDef *)FND_BASE)

void FND_Init(void);
void FND_Display_On(void);
void FND_Display_Off(void);
void FND_Data(uint16_t data);

#endif /* INC_DRIVER_FND_FND_H_ */
