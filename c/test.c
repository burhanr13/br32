
int cond(int a, int b, int c) {
    return a ? b : c;
}

int aaaa(int a, int b) {
    return a && b;
}

int dummy() {
    return 0;
}

void xxxx(int a) {
    while (!a) {
        if (a) {
            while (a) dummy();
            break;
        } else {
            dummy();
        }
        dummy();
    }
    dummy();
}

int bbbbbb(int a) {
    char x[] = {1, 2, 3};
    return x[0];
}

void send(short* to, short* from, int count) {
    int n = (count + 7) / 8;
    switch (count % 8) {
        case 0: do { *to = *from++;
                case 7: *to = *from++;
                case 6: *to = *from++;
                case 5: *to = *from++;
                case 4: *to = *from++;
                case 3: *to = *from++;
                case 2: *to = *from++;
                case 1: *to = *from++;
            } while (--n > 0);
    }
}

const char* word(int a) {
    switch (a) {
        case 0: return "zero";
        case 1: return "one";
        case 2: return "two";
        // case 3: return "three";
        // case 4: return "four";
        // case 5: return "five";
        // case 6: return "six";
        // case 7: return "seven";
        case 8: return "eight";
        case 9: return "nine";
        case 10: return "ten";
        default: return "i cant count that high";
    }
}

// void labels() {
// l1: {}
// l2: {}
// l3: {}
// l4: {}
// l5:
//     goto l1;
// l6: {}
// }

// void infloop() {
//     int a=0;
//     for (;;) {
//         if (a) a=1;
//     }
// }

// void infloop2() {
//     int a = 0;
//     for (;;) {
//         if (a > 4) a *= 8;
//         a += 3;
//         if (++a == 100) break;
//         a *= 2;
//     }
// }

// void loopy() {
//     do {
//         volatile int a = 5;
//     } while(0);

//     while (1) {
//         volatile int b = 6;
//         break;
//     }
// }

void strcpy(char* dst, char* src) {
    while (*src) *dst++ = *src++;
}

// int ddd(unsigned char* a, signed char* c, unsigned short* b, signed short* d)
// {
//     return *a + *b + *c + *d;
// }

// int aaa(int a) {
//     if (a < 2) return a + 5;
//     else return a - 10;
// }

// int bbb(int a, int b) {
//     return 4 + a + b;
// }

// int main() {
//     int c = bbb(aaa(69), aaa(420));
// }

// int lol() {
//     return 5;
// }

// int qqq(int b) {
//     if ((b & (1 << 10)) != 0) return 1;
//     return 0;
// }
