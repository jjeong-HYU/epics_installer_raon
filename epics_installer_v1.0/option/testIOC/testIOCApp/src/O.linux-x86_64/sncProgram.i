# 1 "../sncProgram.st"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 1 "<command-line>" 2
# 1 "../sncProgram.st"
# 1 "./../sncExample.stt" 1
program sncExample
double v;
assign v to "{user}:aiExample";
monitor v;

ss ss1 {
    state init {
        when (delay(10)) {
            printf("sncExample: Startup delay over\n");
        } state low
    }
    state low {
        when (v > 5.0) {
            printf("sncExample: Changing to high\n");
        } state high
    }
    state high {
        when (v <= 5.0) {
            printf("sncExample: Changing to low\n");
        } state low
    }
}
# 1 "../sncProgram.st" 2
