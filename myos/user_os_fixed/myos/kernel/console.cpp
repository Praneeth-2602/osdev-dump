// kernel/console.cpp
#include "console.hpp"

namespace vga {
    // Define the single shared buffer object (one-definition, no per-TU statics).
    // IMPORTANT: this assumes a flat data segment (base=0) and that paging
    // either is disabled or maps physical 0xB8000 to linear 0xB8000.
    volatile uint16_t* const buffer = reinterpret_cast<volatile uint16_t* const>(0xB8000);

    namespace {
        int row = 0;
        int col = 0;
        uint8_t attrib = 0x07; // light grey on black

        inline void newline() {
            col = 0;
            if (++row >= H) {
                // scroll up 1 line
                for (int r = 1; r < H; ++r) {
                    for (int c = 0; c < W; ++c) {
                        buffer[(r - 1) * W + c] = buffer[r * W + c];
                    }
                }
                // clear last line
                for (int c = 0; c < W; ++c) {
                    buffer[(H - 1) * W + c] = (uint16_t)' ' | (uint16_t(attrib) << 8);
                }
                row = H - 1;
            }
        }
    } // anonymous

    void clear() {
        row = col = 0;
        for (int r = 0; r < H; ++r) {
            for (int c = 0; c < W; ++c) {
                buffer[r * W + c] = (uint16_t)' ' | (uint16_t(attrib) << 8);
            }
        }
    }

    void putc(char ch) {
        if (ch == '\n') { newline(); return; }
        if (ch == '\r') { col = 0;   return; }

        // guard - avoid writing outside bounds if row/col ever get corrupted
        if (row < 0) row = 0;
        if (col < 0) col = 0;
        if (row >= H) row = H - 1;
        if (col >= W) { newline(); } // wrap/advance as needed

        buffer[row * W + col] = (uint16_t)ch | (uint16_t(attrib) << 8);

        if (++col >= W) newline();
    }

    void writes(const char* s) {
        if (!s) return;
        while (*s) putc(*s++);
    }
} // namespace vga
