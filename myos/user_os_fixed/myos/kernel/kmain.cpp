#include "console.hpp"
#include <stdint.h>

// Entry point called from boot.s
extern "C" void kmain() {
    // Clear the screen and display simple text messages
    vga::clear();
    vga::writes("Hello from myos kernel!\n");
    vga::writes("Welcome to myOS - a simple 32-bit OS\n");
    
    // Enter an infinite loop - in a real OS, this would be
    // the place to initialize system services and enter
    // the main scheduler loop
    while (1) {
        // Use halt to save power while idle
        asm volatile("hlt");
    }
}