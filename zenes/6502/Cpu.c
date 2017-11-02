//
//  Cpu.c
//  
//
//  Created by zenen jaimes on 10/31/17.
//

#include "Cpu.h"

int Emulate6502(StateCpu* state)
{
    if (!state->is_running) {
        return 0;
    }
    
    return 1;
}

void GenerateInterrupt(StateCpu* state, int interrupt_num)
{
    
}
