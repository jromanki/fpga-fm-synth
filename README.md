# fpga-fm-synth
Poniżej przedstawiono strukturę najważniejszych katalogów i plików projektu wraz z krótkim opisem ich zawartości.

 - `synth-tangnano20k` - Katalog zawierający kompletną logikę syntezatora zaimplementowaną w języku Verilog. W podkatalogu `src` znajdują się wydzielone moduły odpowiedzialne za syntezę polifoniczną, generację sygnałów nośnych i modulujących (DDS), a także warstwę sprzętową komunikacji (SPI, I2S).
 - `control-blackpill` - Projekt przygotowany w środowisku STM32CubeMX. Zawiera kod odpowiedzialny za odbieranie i dekodowanie komunikatów z klawiatury MIDI za pośrednictwem portu UART, algorytm dynamicznej alokacji głosów oraz procedury sterujące przesyłaniem danych konfiguracyjnych do układu FPGA.
 - `hardware` - Zawiera schemat sprzętowy wykonany w programie KiCad oraz użyte biblioteki komponentów jako submoduły git.
 - `scripts` - Zestaw skryptów pomocniczych w języku Python służących m.in. do generacji tablic LUT, konwersji parametrów MIDI na wartości sterujące dla układu FPGA oraz wyznaczania optymalnych częstotliwości PLL układu.


## Struktura repozytorium - część STM32
```
control-blackpill
|-- build                   - katalog plikow wynikowych kompilacji
|-- Core                    - kod zrodlowy aplikacji MCU
|   |-- Inc
|   |   `-- midi.h          - definicje struktur i protokolu MIDI
|   `-- Src
|       |-- freertos.c      - konfiguracja FreeRTOS, definicja taskow
|       |                   (SPI + MIDI + LED sync)
|       |-- main.c          - punkt inicjalizacji systemu
|       |-- midi.c          - dekodowanie komunikatow MIDI,
|       |                   przydzial glosow,
|       |                   konwersja danych MIDI->FPGA,
|       |                   sterowanie modulacja i glosnoscia
|       `-- usart.c         - UART MIDI RX -> kolejka do dekodowania
|-- Drivers                 - biblioteki HAL/CMSIS STM32
|-- freertos-blink.ioc      - konfiguracja projektu STM32CubeMX
`-- Makefile                - skrypt budowania projektu MCU
```

## Struktura repozytorium - część FPGA

```
synth-tangnano20k
|-- build               - katalog na wyniki syntezy i place&route
|-- mk.sh               - skrypt automatyzujacy proces budowania
|-- pinout.cst          - plik przypisania pinow ukladu FPGA
|-- src                 - kod zrodlowy logiki FPGA w jezyku Verilog
|   |-- dds             - moduly implementacji pojedynczego glosu
|   |                   (DDS, LUT, modulacja)
|   |-- i2s.v           - interfejs transmisji audio I2S
|   |-- mixer.v         - sumowanie sygnalow wielu glosow
|   |-- pll.v           - konfiguracja i uzycie petli PLL
|   |-- spi             - moduly obslugi komunikacji SPI
|   |-- spi_parser.v    - dekodowanie ramek SPI na komendy sterujace
|   `-- top.v           - glowny modul systemu FPGA
`-- tb                  - testbenche symulacyjne
    |-- i2s             - symulacja i weryfikacja interfejsu I2S
    |-- spi             - symulacja interfejsu SPI
    `-- sq_gen.v        - generator przebiegow prostokatnych (test)
```