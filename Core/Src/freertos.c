/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * File Name          : freertos.c
  * Description        : Code for freertos applications
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "FreeRTOS.h"
#include "task.h"
#include "main.h"
#include "cmsis_os.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "midi.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
typedef StaticQueue_t osStaticMessageQDef_t;
/* USER CODE BEGIN PTD */

struct out_spi_msg_t{
  uint8_t packets[5];
  uint8_t target_osc;
  uint8_t msg_type;
};

volatile uint8_t note_pressed_recently = 0;
volatile uint8_t note_led_waiting = 0;

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
/* USER CODE BEGIN Variables */
extern SPI_HandleTypeDef hspi1;
extern osMessageQueueId_t midi_queueHandle;

/* USER CODE END Variables */
/* Definitions for blink01 */
osThreadId_t blink01Handle;
const osThreadAttr_t blink01_attributes = {
  .name = "blink01",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityNormal,
};
/* Definitions for transmit_spi */
osThreadId_t transmit_spiHandle;
const osThreadAttr_t transmit_spi_attributes = {
  .name = "transmit_spi",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityLow,
};
/* Definitions for process_midi */
osThreadId_t process_midiHandle;
const osThreadAttr_t process_midi_attributes = {
  .name = "process_midi",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityLow,
};
/* Definitions for midi_queue */
osMessageQueueId_t midi_queueHandle;
uint8_t midi_queueBuffer[ 32 * sizeof( uint8_t ) ];
osStaticMessageQDef_t midi_queueControlBlock;
const osMessageQueueAttr_t midi_queue_attributes = {
  .name = "midi_queue",
  .cb_mem = &midi_queueControlBlock,
  .cb_size = sizeof(midi_queueControlBlock),
  .mq_mem = &midi_queueBuffer,
  .mq_size = sizeof(midi_queueBuffer)
};
/* Definitions for to_send_queue */
osMessageQueueId_t to_send_queueHandle;
uint8_t to_send_queueBuffer[ 16 * sizeof( uint32_t ) ];
osStaticMessageQDef_t to_send_queueControlBlock;
const osMessageQueueAttr_t to_send_queue_attributes = {
  .name = "to_send_queue",
  .cb_mem = &to_send_queueControlBlock,
  .cb_size = sizeof(to_send_queueControlBlock),
  .mq_mem = &to_send_queueBuffer,
  .mq_size = sizeof(to_send_queueBuffer)
};

/* Private function prototypes -----------------------------------------------*/
/* USER CODE BEGIN FunctionPrototypes */
static void assemble_spi_packets(uint32_t data_in, struct out_spi_msg_t* msg);
/* USER CODE END FunctionPrototypes */

void start_blink_01(void *argument);
void transmit_spi_01(void *argument);
void process_midi_from_queue(void *argument);

void MX_FREERTOS_Init(void); /* (MISRA C 2004 rule 8.1) */

/**
  * @brief  FreeRTOS initialization
  * @param  None
  * @retval None
  */
void MX_FREERTOS_Init(void) {
  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* USER CODE BEGIN RTOS_MUTEX */
  /* add mutexes, ... */
  /* USER CODE END RTOS_MUTEX */

  /* USER CODE BEGIN RTOS_SEMAPHORES */
  /* add semaphores, ... */
  /* USER CODE END RTOS_SEMAPHORES */

  /* USER CODE BEGIN RTOS_TIMERS */
  /* start timers, add new ones, ... */
  /* USER CODE END RTOS_TIMERS */

  /* Create the queue(s) */
  /* creation of midi_queue */
  midi_queueHandle = osMessageQueueNew (32, sizeof(uint8_t), &midi_queue_attributes);

  /* creation of to_send_queue */
  to_send_queueHandle = osMessageQueueNew (16, sizeof(uint32_t), &to_send_queue_attributes);

  /* USER CODE BEGIN RTOS_QUEUES */
  /* add queues, ... */
  /* USER CODE END RTOS_QUEUES */

  /* Create the thread(s) */
  /* creation of blink01 */
  blink01Handle = osThreadNew(start_blink_01, NULL, &blink01_attributes);

  /* creation of transmit_spi */
  transmit_spiHandle = osThreadNew(transmit_spi_01, NULL, &transmit_spi_attributes);

  /* creation of process_midi */
  process_midiHandle = osThreadNew(process_midi_from_queue, NULL, &process_midi_attributes);

  /* USER CODE BEGIN RTOS_THREADS */
  /* add threads, ... */
  /* USER CODE END RTOS_THREADS */

  /* USER CODE BEGIN RTOS_EVENTS */
  /* add events, ... */
  /* USER CODE END RTOS_EVENTS */

}

/* USER CODE BEGIN Header_start_blink_01 */
/**
  * @brief  Function implementing the blink01 thread.
  * @param  argument: Not used
  * @retval None
  */
/* USER CODE END Header_start_blink_01 */
void start_blink_01(void *argument)
{
  /* USER CODE BEGIN start_blink_01 */
  /* Infinite loop */
  for(;;)
  {
    if (note_pressed_recently){
      note_pressed_recently = 0;
      note_led_waiting = 1;
      HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, 0);
      osDelay(50);
      HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, 1);
      note_led_waiting = 1;
    }
    if (note_led_waiting == 0){
      HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, 1);
    }
    osDelay(1);
  }
  /* USER CODE END start_blink_01 */
}

/* USER CODE BEGIN Header_transmit_spi_01 */
/**
* @brief Function implementing the transmit_spi thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_transmit_spi_01 */
void transmit_spi_01(void *argument)
{
  /* USER CODE BEGIN transmit_spi_01 */
  uint32_t data_to_tx;
  static struct out_spi_msg_t msg;

  /* Infinite loop */
  for(;;)
  {
    if (osMessageQueueGet(to_send_queueHandle, (void *)&data_to_tx, NULL, 10) == osOK) {
      msg.msg_type = 1;
      msg.target_osc = 2;
      assemble_spi_packets(data_to_tx, &msg);
      HAL_GPIO_WritePin(GPIOA, GPIO_PIN_4, 0);
      HAL_SPI_Transmit_DMA(&hspi1, msg.packets, 5);
    }
  }
  /* USER CODE END transmit_spi_01 */
}

/* USER CODE BEGIN Header_process_midi_from_queue */
/**
* @brief Function implementing the process_midi thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_process_midi_from_queue */
void process_midi_from_queue(void *argument)
{
  /* USER CODE BEGIN process_midi_from_queue */
  uint8_t rcv_msg = 0;

  /* Infinite loop */
  for(;;)
  {
    if (osMessageQueueGet(midi_queueHandle, (void *)&rcv_msg, NULL, 10) == osOK) {
      note_pressed_recently = 1;
      process_midi(rcv_msg);
    }
  }
  /* USER CODE END process_midi_from_queue */
}

/* Private application code --------------------------------------------------*/
/* USER CODE BEGIN Application */
static void assemble_spi_packets(uint32_t data_in, struct out_spi_msg_t* msg)
{
  // msg->packets[0] = 0x00 | (msg->msg_type << 4) | (msg->target_osc);
  msg->packets[0] = 0x00;

  /* Shift out uint32_t by 8 bit frames MSB first */
  for (int i = 0; i < 4; i++){
    msg->packets[i + 1] = (data_in >> (8 * (3 - i))) & 0xFF;
  }
}
/* USER CODE END Application */

