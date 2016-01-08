#include <libspeechd.h>
#include <stdio.h>
#include <string.h>
#include <glib.h>

extern int ibs_word_begin;
extern int ibs_word_end;
extern char* ibs_words[];

static SPDConnection* g_spd = 0;
static char g_result[1024];

void ibs_init() {
  if (!g_spd) {
    char error_result[1024];
    g_spd = spd_open2("IBusSpeech", "main", NULL, SPD_MODE_SINGLE, SPD_METHOD_UNIX_SOCKET, 1, &error_result);
    spd_say(g_spd, SPD_TEXT, "i-bus reader 已启动");
  }
}

void ibs_destroy() {
  if (g_spd)
    spd_close(g_spd);
}

void ibs_speak(char *text) {
  g_message("ibs_speak:%s", text);
  //spd_cancel(g_spd);
  int ret = spd_say(g_spd, SPD_TEXT, text);
  g_message("ibs_speak: ret=%d", ret);
}

void ibs_speak_politely(char *text) {
  g_message("ibs_speak_politely:%s", text);
  int ret = spd_say(g_spd, SPD_MESSAGE, text);
  g_message("ibs_speak: ret=%d", ret);
}

void ibs_stop() {
  //printf("ibs_stop\n");
  spd_cancel(g_spd);
}

void exec(char *cmd) {
  FILE *fp;

  /* Open the command for reading. */
  fp = popen(cmd, "r");
  if (fp == NULL) {
    printf("Failed to run %s\n", cmd);
    return;
  }

  /* Read the output a line at a time - output it. */
  fgets(g_result, sizeof(g_result) - 1, fp);

  pclose(fp);
}

int isProcRunning(char *cmd) {
  char buffer[1024];
  snprintf(buffer, 1023, "ps -ef|grep '%s'|grep -v grep", cmd);
  exec(buffer);
  if (strlen(g_result) > 0)
    return 1;
  else
    return 0;
}

/*
int main() {
  printf("begin\n");
  ibs_init();
  printf("end\n");
}*/
