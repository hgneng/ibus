#!/usr/bin/bash
gcc -I/usr/include/speech-dispatcher -L/usr/lib/x86_64-linux-gnu ibusspeech.c -lspeechd && ./a.out
