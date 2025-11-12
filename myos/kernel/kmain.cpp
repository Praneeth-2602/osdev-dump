#include "console.hpp"

// Entry point called from boot.s
extern "C" void kmain() {
    // Make sure we initialize directly without using any C++ constructors
    vga::clear();
    vga::writes("Hello from myos kernel!");
    vga::writes("\nWelcome to myos - a simple 32-bit OS");

    // Enter infinite loop
    for(;;) {
        __asm__("hlt");
    }
}