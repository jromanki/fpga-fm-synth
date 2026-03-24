#include "midi.h"
#include "cmsis_os.h"

enum msg_state {
    STATE_IDLE,
    STATE_STATUS,
    STATE_DATA
};

uint32_t midi_to_phase_inc_arr[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1419, 1503, 1593, 1687, 1788, 1894, 2006, 2126, 2252, 2386, 2528, 2678, 2838, 3006, 3185, 3374, 3575, 3788, 4013, 4252, 4504, 4772, 5056, 5357, 5675, 6013, 6370, 6749, 7150, 7575, 8026, 8503, 9009, 9544, 10112, 10713, 11350, 12025, 12740, 13498, 14300, 15151, 16052, 17006, 18017, 19089, 20224, 21426, 22700, 24050, 25480, 26996, 28601, 30301, 32103, 34012, 36035, 38177, 40448, 42853, 45401, 48101, 50961, 53991, 57202, 60603, 64207, 68025, 72069, 76355, 80895, 85706, 90802, 96201, 101922, 107982, 114403, 121206, 128413, 136049, 144139, 152710, 161791, 171411, 181604, 192402, 203843, 215964, 228806, 242412, 256826, 272098, 288278, 305420, 323581, 342822, 363208, 384805, 407687, 431929, 457613, 484824, 513653, 544196, 576556, 610840, 647162, 685645 };

static enum msg_state current_state = STATE_IDLE;
extern osMessageQueueId_t to_send_queueHandle;

/* ======================== STATIC FUNCTIONS DECLARATIONS ======================== */

static uint8_t get_channel(uint8_t rcv_msg);
static uint8_t get_msg_kind(uint8_t rcv_msg);
static uint8_t get_data(uint8_t rcv_msg);
static uint8_t is_my_note_on_msg(uint8_t rcv_msg);

/* ======================== GLOBAL FUNCTIONS DEFINITIONS ======================== */

void process_midi(uint8_t rcv_msg)
{
    if (rcv_msg >= 0xF8) return;

    if (HAS_STATUS_BIT(rcv_msg)) {
        if (is_my_note_on_msg(rcv_msg)) {
            /* is a note on message */
            current_state = STATE_STATUS;
        } else {
            current_state = STATE_IDLE;
        }
    }
    else {
        switch (current_state) {
            case STATE_STATUS:
                /* is a note number data message */
                uint8_t note_num = rcv_msg; 
                uint32_t phase_inc = midi_to_phase_inc_arr[note_num];
                /* put this note on a queue to be sent over spi */
                osMessageQueuePut(to_send_queueHandle, &phase_inc, 0, 10);
                
                current_state = STATE_DATA;
                break;

            case STATE_DATA:
                /* is a velocity data message */
                current_state = STATE_IDLE; 
                break;
                
            default:
                break;
        }
    }
}

/* ======================== STATIC FUNCTIONS DEFINITIONS ======================== */

static uint8_t get_channel(uint8_t rcv_msg)
{
    return CHANNEL_BIT_MASK & rcv_msg;
}

static uint8_t get_msg_kind(uint8_t rcv_msg)
{
    return ((MSG_KIND_BIT_MASK & rcv_msg) >> MSG_KIND_BIT_POS);
}

static uint8_t get_data(uint8_t rcv_msg)
{
    return DATA_BIT_MASK & rcv_msg;
}

static uint8_t is_my_note_on_msg(uint8_t rcv_msg)
{
    if ((get_channel(rcv_msg) == MY_CHANNEL) && (get_msg_kind(rcv_msg) == 1)){
        return 1;
    } else {
        return 0;
    }
}