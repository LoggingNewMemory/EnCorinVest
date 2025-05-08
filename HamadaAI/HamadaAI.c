#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>

#define BUFFER_SIZE 256
#define GAME_FILE_PATH "/data/adb/modules/EnCorinVest/game.txt"
#define SCRIPT_PATH "/data/adb/modules/EnCorinVest/Scripts/"
#define PERFORMANCE_SCRIPT "performance.sh"
#define BALANCED_SCRIPT "balanced.sh"
#define DELAY_ON 5
#define DELAY_OFF 10

bool isGamePackage(const char *packageName) {
    FILE *file = fopen(GAME_FILE_PATH, "r");
    if (!file) {
        perror("Failed to open game.txt");
        return false;
    }

    char line[BUFFER_SIZE];
    while (fgets(line, sizeof(line), file)) {
        line[strcspn(line, "\n")] = 0; // Remove newline character
        if (strcmp(line, packageName) == 0) {
            fclose(file);
            return true;
        }
    }

    fclose(file);
    return false;
}

void executeScript(const char *script) {
    char command[BUFFER_SIZE];
    snprintf(command, sizeof(command), "sh %s%s", SCRIPT_PATH, script);
    system(command);
}

void getCurrentPackage(char *packageName, size_t size) {
    FILE *fp = popen("dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'", "r");
    if (fp == NULL) {
        perror("Failed to run command");
        return;
    }

    char buffer[BUFFER_SIZE];
    packageName[0] = '\0';
    
    if (fgets(buffer, sizeof(buffer), fp) != NULL) {
        char *start = strstr(buffer, "/");
        if (start) {
            start++; // Skip the '/'
            char *end = strpbrk(start, " :/\n\r\t");
            if (end) {
                int length = end - start;
                if (length < size) {
                    strncpy(packageName, start, length);
                    packageName[length] = '\0';
                } else {
                    strncpy(packageName, start, size - 1);
                    packageName[size - 1] = '\0';
                }
            }
        }
    }
    pclose(fp);
}

bool isScreenOn() {
    FILE *fp = popen("dumpsys window | grep mScreen", "r");
    if (fp == NULL) {
        perror("Failed to run command");
        return false;
    }

    char buffer[BUFFER_SIZE];
    bool screenOn = true;
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        if (strstr(buffer, "mScreen=false")) {
            screenOn = false;
            break;
        }
    }
    pclose(fp);
    return screenOn;
}

int main() {
    char currentPackage[BUFFER_SIZE] = {0};
    char lastPackage[BUFFER_SIZE] = {0};
    int delay = DELAY_ON;

    while (true) {
        getCurrentPackage(currentPackage, sizeof(currentPackage));

        if (strlen(currentPackage) > 0 && strcmp(currentPackage, lastPackage) != 0) {
            if (isGamePackage(currentPackage)) {
                executeScript(PERFORMANCE_SCRIPT);
            } else {
                executeScript(BALANCED_SCRIPT);
            }
            strncpy(lastPackage, currentPackage, sizeof(lastPackage));
        }

        if (!isScreenOn()) {
            delay = DELAY_OFF;
        } else {
            delay = DELAY_ON;
        }

        sleep(delay);
    }

    return 0;
}