#include "midi.h"
#include "cmsis_os.h"
#include <math.h>

enum msg_state {
    STATE_IDLE,
    STATE_STATUS,
    STATE_DATA
};

uint32_t midi_to_phase_inc_arr[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 709, 752, 796, 844, 894, 947, 1003, 1063, 1126, 1193, 1264, 1339, 1419, 1503, 1593, 1687, 1788, 1894, 2006, 2126, 2252, 2386, 2528, 2678, 2838, 3006, 3185, 3374, 3575, 3788, 4013, 4252, 4504, 4772, 5056, 5357, 5675, 6013, 6370, 6749, 7150, 7575, 8026, 8503, 9009, 9544, 10112, 10713, 11350, 12025, 12740, 13498, 14300, 15151, 16052, 17006, 18017, 19089, 20224, 21426, 22700, 24050, 25480, 26996, 28601, 30301, 32103, 34012, 36035, 38177, 40448, 42853, 45401, 48101, 50961, 53991, 57202, 60603, 64207, 68025, 72070, 76355, 80895, 85706, 90802, 96201, 101922, 107982, 114403, 121206, 128413, 136049, 144139, 152710, 161791, 171411, 181604, 192402, 203843, 215964, 228806, 242412, 256827, 272098, 288278, 305420, 323581, 342822 };
uint16_t exp_volume_arr[] = { 0, 69, 73, 77, 81, 86, 91, 96, 101, 107, 113, 119, 126, 133, 140, 148, 156, 165, 174, 184, 194, 205, 217, 229, 242, 255, 270, 285, 301, 317, 335, 354, 374, 394, 417, 440, 464, 490, 518, 547, 577, 610, 644, 680, 718, 758, 800, 845, 892, 942, 994, 1050, 1109, 1171, 1236, 1305, 1378, 1455, 1537, 1622, 1713, 1809, 1910, 2017, 2130, 2249, 2374, 2507, 2647, 2795, 2951, 3116, 3290, 3474, 3669, 3874, 4090, 4319, 4560, 4815, 5084, 5369, 5669, 5986, 6320, 6673, 7046, 7440, 7856, 8295, 8759, 9249, 9766, 10312, 10888, 11497, 12139, 12818, 13534, 14291, 15090, 15933, 16824, 17764, 18757, 19806, 20913, 22082, 23316, 24619, 25996, 27449, 28983, 30603, 32314, 34120, 36027, 38041, 40168, 42413, 44784, 47287, 49930, 52721, 55668, 58780, 62066, 65535 };

static volatile enum msg_state current_state = STATE_IDLE;
static volatile uint8_t msg_type;
static volatile uint8_t first_data_msg;
extern osMessageQueueId_t to_send_queueHandle;

/* ======================== STATIC FUNCTIONS DECLARATIONS ======================== */

static void assemble_message(
    fpga_msg_t* fpga_msg,
    uint8_t msg_type,
    uint8_t data1,
    uint8_t data2);

static uint8_t choose_target_osc();
static uint8_t get_channel(uint8_t rcv_msg);
static uint8_t get_msg_kind(uint8_t rcv_msg);
static uint8_t get_data(uint8_t rcv_msg);
static uint32_t map_mod_freq_mult(uint8_t data);
static uint8_t is_my_note_on_msg(uint8_t rcv_msg);
static uint8_t is_my_note_off_msg(uint8_t rcv_msg);
static uint8_t is_my_cc_chg_msg(uint8_t rcv_msg);

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
        else if (is_my_cc_chg_msg(rcv_msg)) {
            /* is a control change message */
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
                /* is a first data message of supported status message */
                first_data_msg = data;

                if ((msg_type == NOTE_ON_MSG) || (msg_type == NOTE_OFF_MSG)) {
                    fpga_msg_t fpga_msg;

                    /* translate message for spi */
                    assemble_message(&fpga_msg, msg_type, data, 0);

                    /* put this message on a queue to be sent over spi */
                    osMessageQueuePut(to_send_queueHandle, &fpga_msg, 0, 10);
                }
                
                current_state = STATE_DATA;
                break;

            case STATE_DATA:
                /* is a 2nd data message of supported status message */
                if (msg_type == CTRL_CHG_MSG) {
                    fpga_msg_t fpga_msg;

                    /* translate message for spi */
                    assemble_message(&fpga_msg, msg_type, first_data_msg, data);

                    /* put this message on a queue to be sent over spi */
                    osMessageQueuePut(to_send_queueHandle, &fpga_msg, 0, 10);
                };

                break;
                
            default:
                break;
        }
    }
}

/* ======================== STATIC FUNCTIONS DEFINITIONS ======================== */

static void assemble_message(fpga_msg_t* fpga_msg, uint8_t msg_type, uint8_t data1, uint8_t data2)
{

    fpga_msg->target_osc = choose_target_osc();
    fpga_msg->msg_type = msg_type;

    if (msg_type == NOTE_OFF_MSG){
        fpga_msg->msg_type = 0;
        fpga_msg->data = 0;
    }
    else if (msg_type == NOTE_ON_MSG){
        fpga_msg->msg_type = 1;
        fpga_msg->data = midi_to_phase_inc_arr[data1];
    }
    else if (msg_type == CTRL_CHG_MSG){
        /* first data message is a CC channel */
        if (data1 == CC_CHAN_VOLUME){
            /* change output volume */
            fpga_msg->msg_type = 7;
            fpga_msg->data = (uint32_t) exp_volume_arr[data2];
        }

        if (data1 == CC_MOD_DEPTH){
            /* change depth of FM modulation (7-bit) */
            fpga_msg->msg_type = 2;
            fpga_msg->data = (uint32_t) data2;
        }

        if (data1 == CC_MOD_FREQ_MULT){
            /* change depth of FM modulation (7-bit) */
            fpga_msg->msg_type = 3;
            fpga_msg->data = map_mod_freq_mult(data2);
        }
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

static uint32_t map_mod_freq_mult(uint8_t data)
{

    float f = (float) data;
    return (uint32_t) (roundf(f/32));
}

static uint8_t is_my_note_on_msg(uint8_t rcv_msg)
{
    if ((get_channel(rcv_msg) == MY_CHANNEL)
        && (get_msg_kind(rcv_msg) == NOTE_ON_MSG))
    {
        return 1;
    } else {
        return 0;
    }
}

static uint8_t is_my_note_off_msg(uint8_t rcv_msg)
{
    if ((get_channel(rcv_msg) == MY_CHANNEL)
        && (get_msg_kind(rcv_msg) == NOTE_OFF_MSG))
    {
        return 1;
    } else {
        return 0;
    }
}

static uint8_t is_my_cc_chg_msg(uint8_t rcv_msg)
{
    if ((get_channel(rcv_msg) == MY_CHANNEL)
        && (get_msg_kind(rcv_msg) == CTRL_CHG_MSG))
    {
        return 1;
    } else {
        return 0;
    }
}