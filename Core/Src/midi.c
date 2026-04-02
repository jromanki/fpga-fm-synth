#include "midi.h"
#include "cmsis_os.h"

enum msg_state {
    STATE_IDLE,
    STATE_STATUS,
    STATE_DATA
};

uint32_t midi_to_phase_inc_arr[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 709, 752, 796, 844, 894, 947, 1003, 1063, 1126, 1193, 1264, 1339, 1419, 1503, 1593, 1687, 1788, 1894, 2006, 2126, 2252, 2386, 2528, 2678, 2838, 3006, 3185, 3374, 3575, 3788, 4013, 4252, 4504, 4772, 5056, 5357, 5675, 6013, 6370, 6749, 7150, 7575, 8026, 8503, 9009, 9544, 10112, 10713, 11350, 12025, 12740, 13498, 14300, 15151, 16052, 17006, 18017, 19089, 20224, 21426, 22700, 24050, 25480, 26996, 28601, 30301, 32103, 34012, 36035, 38177, 40448, 42853, 45401, 48101, 50961, 53991, 57202, 60603, 64207, 68025, 72070, 76355, 80895, 85706, 90802, 96201, 101922, 107982, 114403, 121206, 128413, 136049, 144139, 152710, 161791, 171411, 181604, 192402, 203843, 215964, 228806, 242412, 256827, 272098, 288278, 305420, 323581, 342822 };
static enum msg_state current_state = STATE_IDLE;
static uint8_t msg_type;
extern osMessageQueueId_t to_send_queueHandle;

/* ======================== STATIC FUNCTIONS DECLARATIONS ======================== */

static void assemble_message(fpga_msg_t* fpga_msg, uint8_t msg_type, uint8_t data);
static uint8_t choose_target_osc();
static uint8_t get_channel(uint8_t rcv_msg);
static uint8_t get_msg_kind(uint8_t rcv_msg);
static uint8_t get_data(uint8_t rcv_msg);
static uint8_t is_my_note_on_msg(uint8_t rcv_msg);
static uint8_t is_my_note_off_msg(uint8_t rcv_msg);

/* ======================== GLOBAL FUNCTIONS DEFINITIONS ======================== */

void process_midi(uint8_t rcv_msg)
{
    if (rcv_msg >= 0xF8) return;

    if (HAS_STATUS_BIT(rcv_msg)) {
        msg_type = get_msg_kind(rcv_msg);

        if (is_my_note_on_msg(rcv_msg)) {
            /* is a note on message */
            current_state = STATE_STATUS;
        }
        else if (is_my_note_off_msg(rcv_msg)) {
            /* is a note off message */
            current_state = STATE_STATUS;
        }
        else {
            current_state = STATE_IDLE;
        }
    }
    else {
        uint8_t data = rcv_msg; 

        switch (current_state) {
            case STATE_STATUS:
                /* is a data message of supported status message */
                fpga_msg_t fpga_msg;

                /* translate message for spi */
                assemble_message(&fpga_msg, msg_type, data);

                /* put this message on a queue to be sent over spi */
                osMessageQueuePut(to_send_queueHandle, &fpga_msg, 0, 10);
                
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

static void assemble_message(fpga_msg_t* fpga_msg, uint8_t msg_type, uint8_t data)
{

    fpga_msg->target_osc = choose_target_osc();
    fpga_msg->msg_type = msg_type;

    if (msg_type == NOTE_OFF_MSG){
        fpga_msg->data = 0;
    }
    else if (msg_type == NOTE_ON_MSG){
        fpga_msg->data = midi_to_phase_inc_arr[data];
    }
}

static uint8_t choose_target_osc()
{
    return 0;
}

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

static uint8_t is_my_note_off_msg(uint8_t rcv_msg)
{
    if ((get_channel(rcv_msg) == MY_CHANNEL) && (get_msg_kind(rcv_msg) == 0)){
        return 1;
    } else {
        return 0;
    }
}