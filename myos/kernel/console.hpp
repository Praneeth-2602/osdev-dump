#pragma once
#include <stdint.h>

namespace vga {
// Fix: use a non-constexpr pointer to VGA buffer
static uint16_t* const buffer = (uint16_t*)0xB8000;
constexpr int W = 80;
constexpr int H = 25;

void clear();
void putc(char c);
void writes(const char* s);
}