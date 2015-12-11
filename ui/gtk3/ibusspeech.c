#include <libspeechd.h>
#include <stdio.h>

void ibs_init() {
  SPDConnection* spd = spd_open("IBusSpeech", "main", NULL, SPD_MODE_SINGLE);
  spd_say(spd, SPD_TEXT, "hello world");
  spd_close(spd);
}
/*
int main() {
  printf("begin\n");
  ibs_init();
  printf("end\n");
}*/
