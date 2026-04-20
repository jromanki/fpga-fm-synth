#include <math.h>
#include <stdbool.h>

#include "midi.h"
#include "cmsis_os.h"

enum msg_state {
    STATE_IDLE,
    STATE_STATUS,
    STATE_DATA
};
 
typedef struct {
    uint8_t note_value;
    uint8_t note_age;
    bool active;
} voice_t;
 

uint32_t midi_to_phase_inc_arr[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 709, 752, 796, 844, 894, 947, 1003, 1063, 1126, 1193, 1264, 1339, 1419, 1503, 1593, 1687, 1788, 1894, 2006, 2126, 2252, 2386, 2528, 2678, 2838, 3006, 3185, 3374, 3575, 3788, 4013, 4252, 4504, 4772, 5056, 5357, 5675, 6013, 6370, 6749, 7150, 7575, 8026, 8503, 9009, 9544, 10112, 10713, 11350, 12025, 12740, 13498, 14300, 15151, 16052, 17006, 18017, 19089, 20224, 21426, 22700, 24050, 25480, 26996, 28601, 30301, 32103, 34012, 36035, 38177, 40448, 42853, 45401, 48101, 50961, 53991, 57202, 60603, 64207, 68025, 72070, 76355, 80895, 85706, 90802, 96201, 101922, 107982, 114403, 121206, 128413, 136049, 144139, 152710, 161791, 171411, 181604, 192402, 203843, 215964, 228806, 242412, 256827, 272098, 288278, 305420, 323581, 342822 };
uint16_t exp_volume_arr[] = { 0, 42, 57, 72, 87, 103, 119, 137, 157, 177, 199, 222, 247, 273, 301, 331, 362, 395, 431, 468, 507, 549, 593, 640, 689, 740, 795, 852, 912, 975, 1041, 1111, 1184, 1261, 1341, 1425, 1513, 1606, 1702, 1803, 1909, 2019, 2134, 2254, 2380, 2511, 2648, 2790, 2939, 3094, 3255, 3423, 3598, 3780, 3969, 4166, 4371, 4584, 4806, 5036, 5274, 5523, 5780, 6048, 6325, 6613, 6912, 7222, 7543, 7876, 8221, 8579, 8949, 9333, 9731, 10142, 10568, 11009, 11466, 11938, 12426, 12931, 13454, 13994, 14553, 15130, 15726, 16343, 16979, 17637, 18317, 19018, 19742, 20490, 21262, 22059, 22881, 23729, 24604, 25507, 26438, 27398, 28387, 29408, 30460, 31544, 32662, 33813, 34999, 36222, 37481, 38778, 40113, 41489, 42905, 44363, 45863, 47408, 48998, 50634, 52318, 54050, 55832, 57665, 59551, 61490, 63484, 65535 };
voice_t voices[NUM_OF_VOICES];

static volatile enum msg_state current_state = STATE_IDLE;
static volatile uint8_t msg_type;
static volatile uint8_t first_data_msg;
extern osMessageQueueId_t to_send_queueHandle;

/* ======================== STATIC FUNCTIONS DECLARATIONS ======================== */

static uint8_t assemble_message(
    fpga_msg_t* fpga_msg,
    uint8_t msg_type,
    uint8_t data1,
    uint8_t data2);


static uint8_t assign_voice_note_on(uint8_t midi_note);

/**
 * @brief   This function decides which voice should be turned off on
 *          MIDI OFF message
 * 
 * @param midi_note     MIDI note value
 * @return int8_t       Returns oscillator ID if found voice playing requested
 *                      note, if not returns -1 (note got stolen before)
 */
static int8_t assign_voice_note_off(uint8_t midi_note);

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
                    if (assemble_message(&fpga_msg, msg_type, data, 0)) {
                        break;
                    }

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
                    if (assemble_message(&fpga_msg, msg_type, first_data_msg, data)){
                        break;
                    }

                    /* put this message on a queue to be sent over spi */
                    osMessageQueuePut(to_send_queueHandle, &fpga_msg, 0, 10);
                };

                break;
                
            default:
                break;
        }
    }
}

void init_voices() {
    /* init to very old value */
    for (int i=0; i<NUM_OF_VOICES; i++) {
        voices[i].active = false;
    }
}

/* ======================== STATIC FUNCTIONS DEFINITIONS ======================== */

static uint8_t assemble_message(fpga_msg_t* fpga_msg, uint8_t msg_type, uint8_t data1, uint8_t data2)
{

    fpga_msg->target_osc = 0;
    fpga_msg->msg_type = msg_type;

    if (msg_type == NOTE_OFF_MSG){
        int8_t osc = assign_voice_note_off(data1);
        if (osc == -1){
            /* voice was stolen - don't send note off*/
            return 1;
        }
        else {
            fpga_msg->target_osc = (uint8_t) osc;
        }

        fpga_msg->msg_type = 0;
        fpga_msg->data = 0;
    }

    else if (msg_type == NOTE_ON_MSG){
        fpga_msg->target_osc = assign_voice_note_on(data1);
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

    return 0;
}

static int8_t assign_voice_note_off(uint8_t midi_note)
{
    uint8_t target_voice_idx = -1;
 
    for (int i=0; i<NUM_OF_VOICES; i++) {
 
        /* if found voice playing midi_note currently */
        if (voices[i].note_value == midi_note && voices[i].active) {
            /* mark voice as free */
            voices[i].active = false;
 
            /* found target voice */
            target_voice_idx = i;
        }
    }
 
    return target_voice_idx;
}

static uint8_t assign_voice_note_on(uint8_t midi_note)
{
    uint8_t target_voice_idx = 255;
 
    /* Check for retrigger */
    for (int i = 0; i < NUM_OF_VOICES; i++) {
        if (voices[i].active && voices[i].note_value == midi_note) {
            /* Use this voice again */
            target_voice_idx = i;
            break;
        }
    }

    /* find free voice */
    for (int i = 0; i < NUM_OF_VOICES; i++) {
        if (!voices[i].active){
            target_voice_idx = i;
            break;
        }
    }
 
    /* if not found a free voice */
    if (target_voice_idx == 255){
        target_voice_idx = 0;
 
        /* steal voice with the oldest note */
        for (int i = 1; i < NUM_OF_VOICES; i++) {
 
            if (voices[i].note_age > voices[target_voice_idx].note_age) {
                /* if found older active note save its index */
                target_voice_idx = i;
            }
        }   
    }
 
    /* increment all voice ages */
    for (int i = 0; i < NUM_OF_VOICES; i++) {
 
        if (voices[i].active && voices[i].note_age < 255) {
            voices[i].note_age++;
        }
    }
 
    /* assign note an oldest voice */
    voices[target_voice_idx].note_value = midi_note;
    voices[target_voice_idx].note_age = 0;
    voices[target_voice_idx].active = true;
 
    /* return index of assigned voice */
    return target_voice_idx;
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