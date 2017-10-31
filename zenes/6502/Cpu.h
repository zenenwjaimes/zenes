//
//  Cpu.h
//  
//
//  Created by zenen jaimes on 10/31/17.
//

#ifndef Cpu_h
#define Cpu_h

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/time.h>


typedef struct StateCpu {
    boolean        is_running;
    uint32_t       counter;
    uint8_t        reg_acc;
    uint8_t        reg_x;
    uint8_t        reg_y;
    uint16_t       reg_sp;
    uint8_t        reg_status;
    uint16_t       reg_pc;
    uint8_t        *memory;
    uint8_t        interrupt_period;
    uint16_t       notify_ppu_value;
    uint16_t       notify_ppu_address;
} StateCpu;

int Emulate6502(StateCpu* state);
void GenerateInterrupt(StateCpu* state, int interrupt_num);

#endif /* Cpu_h */
