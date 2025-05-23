#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>

#define GAME_LIST "/data/adb/modules/EnCorinVest/game.txt"
#define PERFORMANCE_SCRIPT "/data/adb/modules/EnCorinVest/Scripts/performance.sh"
#define BALANCED_SCRIPT "/data/adb/modules/EnCorinVest/Scripts/balanced.sh"

#define MAX_PATTERNS 256
#define MAX_PATTERN_LENGTH 256
#define BUFFER_SIZE 1024

typedef enum { EXEC_NONE, EXEC_GAME, EXEC_NORMAL } ExecType;

int main(void) {
    // Check if game.txt exists
    FILE *file = fopen(GAME_LIST, "r");
    if (!file) {
        fprintf(stderr, "Error: %s not found\n", GAME_LIST);
        return 1;
    }
    fclose(file);

    bool prev_screen_on = true; // initial status (assumed on)
    ExecType last_executed = EXEC_NONE;

    while (1) {
        // Build game package list from GAME_LIST.
        char patterns[MAX_PATTERNS][MAX_PATTERN_LENGTH];
        int num_patterns = 0;
        file = fopen(GAME_LIST, "r");
        if (file) {
            char line[BUFFER_SIZE];
            while (fgets(line, sizeof(line), file) && num_patterns < MAX_PATTERNS) {
                // Remove newline character.
                line[strcspn(line, "\n")] = '\0';
                // Skip empty lines.
                if (line[0] == '\0') continue;
                // Skip lines containing spaces.
                if (strchr(line, ' ') != NULL) continue;
                // Save the pattern.
                strncpy(patterns[num_patterns], line, MAX_PATTERN_LENGTH - 1);
                patterns[num_patterns][MAX_PATTERN_LENGTH - 1] = '\0';
                num_patterns++;
            }
            fclose(file);
        }

        // Check screen status by executing "dumpsys window".
        bool current_screen_on = true;
        FILE *pipe_fp = popen("dumpsys window", "r");
        if (pipe_fp) {
            char buffer[BUFFER_SIZE];
            while (fgets(buffer, sizeof(buffer), pipe_fp)) {
                if (strstr(buffer, "mScreenOn") != NULL) {
                    if (strstr(buffer, "false") != NULL) {
                        current_screen_on = false;
                        break;
                    }
                }
            }
            pclose(pipe_fp);
        }

        // Print a message if the screen status has changed.
        if (current_screen_on != prev_screen_on) {
            printf("Screen status changed\n");
            prev_screen_on = current_screen_on;
        }

        // Proceed with app detection only if the screen is on.
        if (current_screen_on) {
            // Execute "dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'" and check for any matching game package.
            pipe_fp = popen("dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'", "r");
            char matched_package[BUFFER_SIZE] = "";
            if (pipe_fp) {
                char line[BUFFER_SIZE];
                while (fgets(line, sizeof(line), pipe_fp)) {
                    // Check each game package pattern against the line.
                    for (int i = 0; i < num_patterns; i++) {
                        if (strstr(line, patterns[i]) != NULL) {
                            // Save the matched pattern (simulate grep -o and tail -1 by keeping the last match).
                            strncpy(matched_package, patterns[i], sizeof(matched_package) - 1);
                            matched_package[sizeof(matched_package) - 1] = '\0';
                        }
                    }
                }
                pclose(pipe_fp);
            }

            // Execute the corresponding script if the detection state changed.
            if (strlen(matched_package) > 0) {
                // A game package was detected.
                if (last_executed != EXEC_GAME) {
                    printf("Game package detected: %s\n", matched_package);
                    char command[BUFFER_SIZE];
                    snprintf(command, sizeof(command), "sh %s", PERFORMANCE_SCRIPT);
                    system(command);
                    last_executed = EXEC_GAME;
                }
            } else {
                // No game package detected.
                if (last_executed != EXEC_NORMAL) {
                    printf("Non-game package detected\n");
                    char command[BUFFER_SIZE];
                    snprintf(command, sizeof(command), "sh %s", BALANCED_SCRIPT);
                    system(command);
                    last_executed = EXEC_NORMAL;
                }
            }
        }
        
        sleep(5); // Updated sleep duration to 5 seconds
    }

    return 0;
}
