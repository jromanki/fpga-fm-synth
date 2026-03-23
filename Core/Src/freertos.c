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
extern osMessageQueueId_t midi_queueHandle;
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
typedef StaticQueue_t osStaticMessageQDef_t;
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
/* USER CODE BEGIN Variables */
extern SPI_HandleTypeDef hspi3;
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

/* Private function prototypes -----------------------------------------------*/
/* USER CODE BEGIN FunctionPrototypes */

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
    // HAL_GPIO_TogglePin(GPIOC, GPIO_PIN_13);
    osDelay(500);
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
  char a = 'A';

  /* Infinite loop */
  for(;;)
  {
    HAL_SPI_Transmit(&hspi3, (uint8_t *) &a, 1, 100);
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
      osDelay(1);
    }
  }
  /* USER CODE END process_midi_from_queue */
}

/* Private application code --------------------------------------------------*/
/* USER CODE BEGIN Application */

/* USER CODE END Application */

