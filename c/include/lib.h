#pragma once

typedef _Bool bool;
#define true ((bool) 1)
#define false ((bool) 0)

typedef signed char int8_t;
typedef unsigned char uint8_t;
typedef signed short int16_t;
typedef unsigned short uint16_t;
typedef signed int int32_t;
typedef unsigned int uint32_t;

int __mul(int a, int b);
int __div(int a, int b);
int __mod(int a, int b);

int printf(const char* fmt, ...);

void set_timer(int period, bool repeat, bool enableIrq);
void stop_timer();
void delay(int cycles);
