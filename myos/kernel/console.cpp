#include "console.hpp"

// Static state for the console
namespace {
    // Current cursor position
    int row = 0;
    int col = 0;
    
    // Current text attribute (color)
    uint8_t attrib = 0x0F; // White on black
    
    // Move cursor to new line
    void newline() {
        col = 0;
        if (++row >= vga::H) {
            // Scroll the screen up
            for (int r = 1; r < vga::H; ++r) {
                for (int c = 0; c < vga::W; ++c) {
                    vga::buffer[(r-1)*vga::W + c] = vga::buffer[r*vga::W + c];
                }
            }
            
            // Clear bottom row
            for (int c = 0; c < vga::W; ++c) {
                vga::buffer[(vga::H-1)*vga::W + c] = (attrib << 8) | ' ';
            }
            
            row = vga::H - 1;
        }
    }
}


namespace vga {
    void clear() {
        // Fill screen with spaces using current attribute
        for (int r = 0; r < H; ++r) {
            for (int c = 0; c < W; ++c) {
                buffer[r*W + c] = (attrib << 8) | ' ';
            }
        }
        
        // Reset cursor to top-left
        row = 0;
        col = 0;
    }

    void putc(char c) {
        // Handle special characters
        if (c == '\n') {
            newline();
            return;
        }
        
        // Write character to screen
        buffer[row*W + col] = (attrib << 8) | static_cast<uint8_t>(c);
        
        // Advance cursor
        if (++col >= W) {
            newline();
        }
    }

    void writes(const char* s) {
        // Write each character in the string
        while (*s) {
            putc(*s++);
        }
    }
}