#include <libspeechd.h>
#include <stdio.h>

extern int ibs_word_begin;
extern int ibs_word_end;
extern char* ibs_words[];

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
  printf("ibs_speak:%s\n", text);
  //spd_cancel(g_spd);
  spd_say(g_spd, SPD_TEXT, text);
}

void ibs_speak_politely(char *text) {
  printf("ibs_speak_politely:%s\n", text);
  spd_say(g_spd, SPD_MESSAGE, text);
}

void ibs_stop() {
  printf("ibs_stop\n");
  spd_cancel(g_spd);
}

/*
int main() {
  printf("begin\n");
  ibs_init();
  printf("end\n");
}*/
