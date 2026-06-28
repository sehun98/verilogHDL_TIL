#include "../../../inc/Driver/GPIO/gpio.h"
#include "../../../inc/App/BUTTON/button.h"
#include "xparameters.h"
#include <stdint.h>
#include <stdbool.h>

Button_t buttons[4] = {
    {GPIOC, GPIO_PIN_0, RELEASE, 0},
    {GPIOC, GPIO_PIN_1, RELEASE, 0},
    {GPIOC, GPIO_PIN_2, RELEASE, 0},
    {GPIOC, GPIO_PIN_3, RELEASE, 0}
};

void Button_DebounceTask(Button_t *btn)
{
    bool btnValue;

    btnValue = GPIO_ReadPin(btn->GPIOx, btn->GPIO_Pin);

    switch (btn->state)
    {
        case RELEASE:
            if (btnValue == GPIO_PIN_SET) {
                btn->state = isPRESS;
            }
            break;

        case isPRESS:
            if (btnValue == GPIO_PIN_SET) {
                btn->state = PRESS;
                btn->flag = 1;
            } else {
                btn->state = RELEASE;
            }
            break;

        case PRESS:
            if (btnValue == GPIO_PIN_RESET) {
                btn->state = isRELEASE;
            }
            break;

        case isRELEASE:
            if (btnValue == GPIO_PIN_RESET) {
                btn->state = RELEASE;
            } else {
                btn->state = PRESS;
            }
            break;

        default:
            btn->state = RELEASE;
            break;
    }
}
