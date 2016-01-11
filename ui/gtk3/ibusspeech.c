#include <libspeechd.h>
#include <stdio.h>
#include <string.h>
#include <glib.h>

extern int ibs_word_begin;
extern int ibs_word_end;
extern char* ibs_words[];
extern int ibs_char_limit = 2;

static SPDConnection* g_spd = 0;
static char g_result[1024];

void ibs_init() {
  if (!g_spd) {
    char error_result[1024];
    g_spd = spd_open2("IBusSpeech", "main", NULL, SPD_MODE_SINGLE, SPD_METHOD_UNIX_SOCKET, 1, &error_result);
    ibs_update_rate();
    ibs_update_char_limit();
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
  //g_message("ibs_speak: ret=%d", ret);
}

void ibs_speak_politely(char *text) {
  g_message("ibs_speak_politely:%s", text);
  int ret = spd_say(g_spd, SPD_MESSAGE, text);
  //g_message("ibs_speak: ret=%d", ret);
}

void ibs_stop() {
  //printf("ibs_stop\n");
  spd_cancel(g_spd);
}

void ibs_exec(char *cmd) {
  FILE *fp;

  /* Open the command for reading. */
  fp = popen(cmd, "r");
  if (fp == NULL) {
    printf("Failed to run %s\n", cmd);
    return;
  }

  g_result[0] = 0;
  fgets(g_result, sizeof(g_result) - 1, fp);
  g_message("ibs_exec: %s", g_result);

  pclose(fp);
}

int ibs_is_proc_running(char *cmd) {
  char buffer[1024];
  snprintf(buffer, 1023, "ps -ef|grep '%s'|grep -v grep", cmd);
  ibs_exec(buffer);
  if (strlen(g_result) > 0)
    return 1;
  else
    return 0;
}

/* rate in Orac is 0-100, default is 50 */
int ibs_get_orca_rate() {
  ibs_exec("grep rate ~/.local/share/orca/user-settings.conf | awk '{print $2}'");
  if (strlen(g_result) > 0) {
    int rate = atoi(g_result);
    if (rate < 0 || rate > 100)
      rate = 50;
    return rate;
  } else {
    return 50;
  }
}

int ibs_get_config_rate() {
  ibs_exec("grep rate ~/.dog/config/ibusreader | awk -F= '{print $2}' 2>/dev/null");
  if (strlen(g_result) > 0) {
    int rate = atoi(g_result);
    if (rate < 0 || rate > 100)
      rate = -1;
    return rate;
  } else {
    return -1;
  }
}

void ibs_update_rate() {
  int rate = ibs_get_config_rate();
  if (rate == -1)
    rate = ibs_get_orca_rate();
  spd_set_voice_rate(g_spd, (int)((rate - 50) * 2));
  g_message("ibs_update_rate: %d -> %d", rate, (int)((rate - 50) * 2));
}


void ibs_update_char_limit() {
  ibs_exec("grep char_limit ~/.dog/config/ibusreader | awk -F= '{print $2}' 2>/dev/null");
  if (strlen(g_result) > 0) {
    int char_limit = atoi(g_result);
    if (char_limit > 1)
      ibs_char_limit = char_limit;
  }
  g_message("ibs_update_char_limit: %d", ibs_char_limit);
}

/*
int main() {
  printf("begin\n");
  ibs_init();
  printf("end\n");
}*/
