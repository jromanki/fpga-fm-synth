#ifndef __MIDI_H__
#define __MIDI_H__

#define STATUS_BIT_MASK                     0x80
#define STATUS_BIT_POS                      7

/* FOR STATUS_BYTES*/
#define MSG_KIND_BIT_MASK                   0x70
#define MSG_KIND_BIT_POS                    4
#define CHANNEL_BIT_MASK                    0x0F

#define NOTE_OFF_MSG                        0
#define NOTE_ON_MSG                         1
#define POLY_AFT_MSG                        2
#define CTRL_CHG_MSG                        3
#define PROG_CHG_MSG                        4
#define CHAN_AFT_MSG                        5
#define PITCH_BND_MSG                       6
#define SYS_MSG                             7

/* FOR DATA BYTES */
#define DATA_BIT_MASK 0x7F

#define HAS_STATUS_BIT(byte) ((byte & STATUS_BIT_MASK) != 0)

#endif