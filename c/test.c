
int ddd(unsigned char *a, signed char *c, unsigned short *b, signed short *d) {
    return *a + *b + *c + *d;
}

int aaa(int a) {
    if (a < 2) return a + 5;
    else return a - 10;
}

int bbb(int a, int b) {
    return a + b;
}

int main() {
    int c = bbb(aaa(69), aaa(420));
}

int lol() {
    return 5;
}
