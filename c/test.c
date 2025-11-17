
void loopy() {
    do {
        volatile int a = 5;
    } while(0);

    while (1) {
        volatile int b = 6;
        break;
    }
}

void strcpy(char* dst, char* src) {
    while (*src) *dst++ = *src++;
}

int ddd(unsigned char* a, signed char* c, unsigned short* b, signed short* d) {
    return *a + *b + *c + *d;
}

int aaa(int a) {
    if (a < 2) return a + 5;
    else return a - 10;
}

int bbb(int a, int b) {
    return 4 + a + b;
}

int main() {
    int c = bbb(aaa(69), aaa(420));
}

int lol() {
    return 5;
}

int qqq(int b) {
    if ((b & (1 << 10)) != 0) return 1;
    return 0;
}
