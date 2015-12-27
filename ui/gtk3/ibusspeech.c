#include <libspeechd.h>
#include <stdio.h>

static SPDConnection* g_spd = 0;

void ibs_init() {
  if (!g_spd) {
    g_spd = spd_open("IBusSpeech", "main", NULL, SPD_MODE_SINGLE);
    spd_say(g_spd, SPD_TEXT, "i-bus reader 已启动");
  }
}

void ibs_destroy() {
  if (g_spd)
    spd_close(g_spd);
}

void ibs_speak(char *text) {
  if (!g_spd)
    ibs_init();
  spd_cancel(g_spd);
  spd_say(g_spd, SPD_TEXT, text);
}

void ibs_speakPolitely(char *text) {
  spd_say(g_spd, SPD_TEXT, text);
}

void ibs_stop() {
  spd_cancel(g_spd);
}

void ibs_speakWordForChar(char *c) {
  ibs_speak(c);
}

/*
int main() {
  printf("begin\n");
  ibs_init();
  printf("end\n");
}*/
