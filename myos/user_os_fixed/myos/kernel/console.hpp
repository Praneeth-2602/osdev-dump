#pragma once
#include <stdint.h>   // use C headers in freestanding code

namespace vga {
    // Each cell = [char (low 8)] + [attribute (high 8)]
    extern volatile uint16_t* const buffer;

    constexpr int W = 80;
    constexpr int H = 25;

    void clear();
    void putc(char c);
    void writes(const char* s);
}
