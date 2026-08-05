#include <iostream>
#include <string>
#include <vector>
#include <stdint.h>
#include <limits.h>
#include "xaxidma.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "xil_mmu.h"
#include "xil_io.h"
#include "sleep.h"
#include "xstatus.h"
#include <iomanip>

/************************** Konfiguracja GPIO *********************************/
#define RESET_DATA     (0xA0010000 + 0x0)
#define RESET_TRI      (0xA0010000 + 0x4)
#define MIN_MAX_DATA   (0xA0010000 + 0x8)
#define MIN_MAX_TRI    (0xA0010000 + 0xC)

/******************** Konfiguracja Rejestrów i Pamięci ***********************/
#define MEM_BASE_ADDR       0x10000000
// Adresy dla deskryptorów (BD) i buforów RX
#define RX_BD_SPACE_BASE    (MEM_BASE_ADDR + 0x00000000)
#define RX_BD_SPACE_HIGH    (MEM_BASE_ADDR + 0x0000FFFF)
#define RX_BUFFER_BASE      (MEM_BASE_ADDR + 0x01000000)

// Adresy dla deskryptorów (BD) i buforów TX
#define TX_BD_SPACE_BASE    (MEM_BASE_ADDR + 0x00010000)
#define TX_BD_SPACE_HIGH    (MEM_BASE_ADDR + 0x0001FFFF)
#define TX_BUFFER_BASE      (MEM_BASE_ADDR + 0x02000000)

#define SAMPLES_PER_PKT     129
#define PKT_COUNT           129
#define TOTAL_SAMPLES       (SAMPLES_PER_PKT * PKT_COUNT)

/************************** Zmienne Globalne *********************************/
XAxiDma AxiDma;

// Wskaźniki na bufory w pamięci DDR
u32 *temp = (u32*)RX_BUFFER_BASE;

// Lokalne tablice na przetworzone dane
static u32 spectogram_p1_T[TOTAL_SAMPLES];
static u32 spectogram_p2_T[TOTAL_SAMPLES];
static u32 spectogram_p3_T[TOTAL_SAMPLES];
static u32 spectogram_stacked[3*TOTAL_SAMPLES];

/************************** Prototypy ***************************************/
static int InitDma();
static int RxSetup(XAxiDma *AxiDmaInstPtr);
static int TxSetup(XAxiDma *AxiDmaInstPtr);
static void RunDmaTransfer();
void RunTxTransfer(u32* source_data, int num_rows, int num_cols) ;
static void ResetAndRestartDMA();

void Reset_PL_Logic();
void SetMinMax(u8 min, u8 max);
void SetUp();
void ReducePrecision(u32* src, int size, int new_precision);
void ScaleTo8Bit(u32* data, int size, u32 min, u32 max);
void Transpose(u32* src, u32* targ, u32 num_rows, u32 num_cols, u32* min, u32* max);
void CreateRGB(u32* R, u32* G, u32* B, u32* result, int precision, int size);
void CreateChByCh(u32* R, u32* G, u32* B, u32* result, int precision, int num_samples);

/************************** MAIN ********************************************/
int main() {
    std::string command;
    SetUp();

    // Konfiguracja atrybutów pamięci dla deskryptorów (brak cache)
    Xil_SetTlbAttributes(RX_BD_SPACE_BASE, 0x601);
    Xil_SetTlbAttributes(TX_BD_SPACE_BASE, 0x601);

    if (InitDma() != XST_SUCCESS) {
        std::cout << "Błąd: Nie udało się zainicjować DMA!" << std::endl;
        return -1;
    }

    if (RxSetup(&AxiDma) != XST_SUCCESS || TxSetup(&AxiDma) != XST_SUCCESS) {
        std::cout << "Błąd: Konfiguracja kanałów DMA nieudana!" << std::endl;
        return -1;
    }

    std::cout << "\r\n--- Terminal Sterowania DMA/PL ---" << std::endl;
    std::cout << "Komendy: p1 (pobierz), send (przetwórz i wyślij), show, r (reset), exit" << std::endl;

    u32 min_p1, max_p1, min_p2, max_p2, min_p3, max_p3;

    while (true) {
        std::cout << "\n> ";
        std::cin >> command;

        if (command == "p1") {
            std::cout << "Pobieranie danych..." << std::endl;
            Reset_PL_Logic();
            ResetAndRestartDMA();
            RunDmaTransfer();
            // Przykład: pobieramy 3 razy, aby mieć różne dane dla R, G, B
            Transpose(temp, spectogram_p1_T, PKT_COUNT, SAMPLES_PER_PKT, &min_p1, &max_p1);
            Transpose(temp, spectogram_p2_T, PKT_COUNT, SAMPLES_PER_PKT, &min_p2, &max_p2);
            Transpose(temp, spectogram_p3_T, PKT_COUNT, SAMPLES_PER_PKT, &min_p3, &max_p3);
            // Tu w realnym systemie powinieneś odpalić RunDmaTransfer ponownie dla p2 i p3
            std::cout << "Dane p1 przetransponowane." << std::endl;
        }
        else if (command == "send") {
            std::cout << "Przetwarzanie i wysyłka RGB..." << std::endl;

            // 1. Redukcja precyzji do 8 bitów (0-255)
//            ReducePrecision(spectogram_p1_T, TOTAL_SAMPLES, 8);
//            ReducePrecision(spectogram_p2_T, TOTAL_SAMPLES, 8);
//            ReducePrecision(spectogram_p3_T, TOTAL_SAMPLES, 8);

            ScaleTo8Bit(spectogram_p1_T, TOTAL_SAMPLES, min_p1, max_p1);
            ScaleTo8Bit(spectogram_p2_T, TOTAL_SAMPLES, min_p2, max_p2);
            ScaleTo8Bit(spectogram_p3_T, TOTAL_SAMPLES, min_p3, max_p3);

            //CreateRGB(spectogram_p1_T, spectogram_p2_T, spectogram_p3_T, spectogram_stacked, 8, TOTAL_SAMPLES);
            CreateChByCh(spectogram_p1_T, spectogram_p2_T, spectogram_p3_T, spectogram_stacked, 8, TOTAL_SAMPLES);

            // 3. Wysyłka przez DMA do PL
            RunTxTransfer(spectogram_stacked, SAMPLES_PER_PKT, PKT_COUNT);
            std::cout << "Transfer TX zakończony pomyślnie." << std::endl;
        }
        else if (command == "show") {
            for (int i = 0; i < 3*TOTAL_SAMPLES; i++) {
            	std::cout << spectogram_stacked[i] << ", ";
            	if (i % TOTAL_SAMPLES == 0) std::cout << "..." << std::endl;
            }
           // for (int i = 0; i < TOTAL_SAMPLES; i++) std::cout << spectogram_p1_T[i] << ", ";
        }
//        else if (command == "show") {
//            for (int i = 0; i < TOTAL_SAMPLES; i++) {
//                std::cout << "0x" << std::hex << std::setw(8) << std::setfill('0') << spectogram_p1_T[i] << ", ";
//
//                // Opcjonalnie: nowa linia co 8 elementów, żeby terminal nie był "rozjechany"
//                if ((i + 1) % 8 == 0) std::cout << "\n";
//            }
//            std::cout << std::dec << "..." << std::endl; // Powrót do systemu dziesiętnego
//        }

        else if (command == "r") {
            Reset_PL_Logic();
            ResetAndRestartDMA();
            std::cout << "Reset wykonany." << std::endl;
        }
        else if (command == "exit") break;
    }

    return 0;
}

/************************** Funkcje Logiki *********************************/

void SetUp() {
    Xil_Out32(RESET_TRI, 0x0);
    Xil_Out32(RESET_DATA, 0x1);
    Xil_Out32(MIN_MAX_TRI, 0x0);
    Xil_Out32(MIN_MAX_DATA, 0x0);
}

void Reset_PL_Logic() {
    Xil_Out32(RESET_DATA, 0x0);
    usleep(10000);
    Xil_Out32(RESET_DATA, 0x1);
}

void Transpose(u32* src, u32* targ, u32 num_rows, u32 num_cols, u32* min, u32* max) {
    *min = UINT32_MAX;
    *max = 0;
    for (u32 i = 0; i < num_rows; i++) {
        for (u32 j = 0; j < num_cols; j++) {
            u32 val = src[i * num_cols + j];
            if (val > *max) *max = val;
            if (val < *min) *min = val;
            targ[j * num_rows + i] = val;
        }
    }
}

void ReducePrecision(u32* src, int size, int new_precision) {
    int reduce = 32 - new_precision;
    for (int i = 0; i < size; i++) {
    	//src[i] = src[i]
    	src[i] = src[i] >> reduce;
    }
}

void ScaleTo8Bit(u32* data, int size, u32 min, u32 max) {
    u32 range = max - min;

    if (range == 0) {
        for (int i = 0; i < size; i++) data[i] = 0;
        return;
    }

    for (int i = 0; i < size; i++) {
        u64 scaled = ((u64)(data[i] - min) * 255) / range;
        data[i] = (u32)scaled;
    }
}

void CreateRGB(u32* R, u32* G, u32* B, u32* result, int precision, int size) {
    for (int i = 0; i < size; i++) {
        // Składanie: 0x00RRGGBB
        result[i] = ((R[i] & 0xFF) << 2*precision) | ((G[i] & 0xFF) << precision) | (B[i] & 0xFF);
    }
}

void CreateChByCh(u32* R, u32* G, u32* B, u32* result, int precision, int num_samples) {
    for (int i = 0; i < num_samples; i++) {
    	if (i % num_samples == 0) std::cout << "debug";
        result[i]               = R[i] & 0xFF; // Kanał R
        result[i + num_samples]     = G[i] & 0xFF; // Kanał G
        result[i + 2 * num_samples] = B[i] & 0xFF; // Kanał B
    }
}

void SetMinMax(u8 min, u8 max) {
    u32 MinMax = (max << 8) | min;
    Xil_Out32(MIN_MAX_DATA, MinMax);
}

/************************** Obsługa DMA *************************************/

static int InitDma() {
    XAxiDma_Config *Config = XAxiDma_LookupConfig(XPAR_AXIDMA_0_DEVICE_ID);
    if (!Config) return XST_FAILURE;
    return XAxiDma_CfgInitialize(&AxiDma, Config);
}

static int RxSetup(XAxiDma *AxiDmaInstPtr) {
    XAxiDma_BdRing *RxRingPtr = XAxiDma_GetRxRing(AxiDmaInstPtr);
    XAxiDma_Bd BdTemplate;
    XAxiDma_Bd *BdPtr;

    XAxiDma_BdRingIntDisable(RxRingPtr, XAXIDMA_IRQ_ALL_MASK);
    u32 BdCount = XAxiDma_BdRingCntCalc(XAXIDMA_BD_MINIMUM_ALIGNMENT, RX_BD_SPACE_HIGH - RX_BD_SPACE_BASE + 1);
    XAxiDma_BdRingCreate(RxRingPtr, RX_BD_SPACE_BASE, RX_BD_SPACE_BASE, XAXIDMA_BD_MINIMUM_ALIGNMENT, BdCount);

    XAxiDma_BdClear(&BdTemplate);
    XAxiDma_BdRingClone(RxRingPtr, &BdTemplate);

    XAxiDma_BdRingAlloc(RxRingPtr, PKT_COUNT, &BdPtr);
    XAxiDma_Bd *BdCurPtr = BdPtr;
    UINTPTR BuffAddr = RX_BUFFER_BASE;

    for (int i = 0; i < PKT_COUNT; i++) {
        XAxiDma_BdSetBufAddr(BdCurPtr, BuffAddr);
        XAxiDma_BdSetLength(BdCurPtr, SAMPLES_PER_PKT * 4, RxRingPtr->MaxTransferLen);
        XAxiDma_BdSetCtrl(BdCurPtr, 0);
        BuffAddr += (SAMPLES_PER_PKT * 4);
        BdCurPtr = (XAxiDma_Bd *)XAxiDma_BdRingNext(RxRingPtr, BdCurPtr);
    }

    XAxiDma_BdRingToHw(RxRingPtr, PKT_COUNT, BdPtr);
    return XAxiDma_BdRingStart(RxRingPtr);
}

static int TxSetup(XAxiDma *AxiDmaInstPtr) {
    XAxiDma_BdRing *TxRingPtr = XAxiDma_GetTxRing(AxiDmaInstPtr);
    XAxiDma_Bd BdTemplate;

    XAxiDma_BdRingIntDisable(TxRingPtr, XAXIDMA_IRQ_ALL_MASK);
    u32 BdCount = XAxiDma_BdRingCntCalc(XAXIDMA_BD_MINIMUM_ALIGNMENT, TX_BD_SPACE_HIGH - TX_BD_SPACE_BASE + 1);
    XAxiDma_BdRingCreate(TxRingPtr, TX_BD_SPACE_BASE, TX_BD_SPACE_BASE, XAXIDMA_BD_MINIMUM_ALIGNMENT, BdCount);

    XAxiDma_BdClear(&BdTemplate);
    XAxiDma_BdRingClone(TxRingPtr, &BdTemplate);
    return XAxiDma_BdRingStart(TxRingPtr);
}

void RunDmaTransfer() {
    XAxiDma_BdRing *RxRingPtr = XAxiDma_GetRxRing(&AxiDma);
    XAxiDma_Bd *BdPtr;
    int processed = 0;

    while (processed < PKT_COUNT) {
        processed += XAxiDma_BdRingFromHw(RxRingPtr, XAXIDMA_ALL_BDS, &BdPtr);
    }

    Xil_DCacheInvalidateRange(RX_BUFFER_BASE, TOTAL_SAMPLES * 4);

    // Recykling deskryptorów
    XAxiDma_BdRingFree(RxRingPtr, PKT_COUNT, BdPtr);
    XAxiDma_Bd *NewBdPtr;
    XAxiDma_BdRingAlloc(RxRingPtr, PKT_COUNT, &NewBdPtr);
    XAxiDma_BdRingToHw(RxRingPtr, PKT_COUNT, NewBdPtr);
}

void RunTxTransfer(u32* source_data, int num_rows, int num_cols) {
    XAxiDma_BdRing *TxRingPtr = XAxiDma_GetTxRing(&AxiDma);
    XAxiDma_Bd *BdPtr;
    XAxiDma_Bd *BdCurPtr;

    // 1. Flush cache dla całego obszaru danych
    Xil_DCacheFlushRange((UINTPTR)source_data, num_rows * num_cols * sizeof(u32));

    // 2. Alokujemy tyle deskryptorów, ile mamy rzędów
    if (XAxiDma_BdRingAlloc(TxRingPtr, num_rows, &BdPtr) != XST_SUCCESS) {
        xil_printf("Błąd: Nie można zaalokować deskryptorów TX!\r\n");
        return;
    }

    BdCurPtr = BdPtr;
    UINTPTR CurrentAddr = (UINTPTR)source_data;

    for (int i = 0; i < num_rows; i++) {
        // Ustawiamy adres początku rzędu
        XAxiDma_BdSetBufAddr(BdCurPtr, CurrentAddr);

        // Długość jednego rzędu w bajtach
        XAxiDma_BdSetLength(BdCurPtr, num_cols * sizeof(u32), TxRingPtr->MaxTransferLen);

        // KLUCZOWE: Każdy rządek to osobna ramka AXI-Stream (TLAST na końcu)
        // SOF = Start of Frame, EOF = End of Frame
        XAxiDma_BdSetCtrl(BdCurPtr, XAXIDMA_BD_CTRL_TXSOF_MASK | XAXIDMA_BD_CTRL_TXEOF_MASK);

        // Przesunięcie adresu o jeden rząd
        CurrentAddr += (num_cols * sizeof(u32));

        // Przejście do następnego deskryptora w pierścieniu
        BdCurPtr = (XAxiDma_Bd *)XAxiDma_BdRingNext(TxRingPtr, BdCurPtr);
    }

    // 3. Przekazanie wszystkich deskryptorów do sprzętu na raz
    XAxiDma_BdRingToHw(TxRingPtr, num_rows, BdPtr);

    // 4. Czekamy na zakończenie wszystkich transferów (polling)
    int processed = 0;
    while (processed < num_rows) {
        processed += XAxiDma_BdRingFromHw(TxRingPtr, XAXIDMA_ALL_BDS, &BdPtr);
    }

    // 5. Zwolnienie deskryptorów
    XAxiDma_BdRingFree(TxRingPtr, num_rows, BdPtr);
}

void ResetAndRestartDMA() {
    XAxiDma_Reset(&AxiDma);
    int TimeOut = 10000;
    while (TimeOut--) {
        if (XAxiDma_ResetIsDone(&AxiDma)) break;
    }
    RxSetup(&AxiDma);
    TxSetup(&AxiDma);
}
