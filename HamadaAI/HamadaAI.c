#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>

#define GAME_LIST "/data/EnCorinVest/game.txt"
#define PERFORMANCE_SCRIPT "/data/adb/modules/EnCorinVest/Scripts/performance.sh"
#define BALANCED_SCRIPT "/data/adb/modules/EnCorinVest/Scripts/balanced.sh"
#define BYPASS_SCRIPT "/data/adb/modules/EnCorinVest/Scripts/encorin_bypass_controller.sh"
#define CONFIG_FILE "/data/adb/modules/EnCorinVest/encorin.txt"

#define MAX_PATTERNS 256
#define MAX_PATTERN_LENGTH 256
#define BUFFER_SIZE 1024

typedef enum { EXEC_NONE, EXEC_GAME, EXEC_NORMAL } ExecType;

bool is_bypass_enabled() {
    FILE *file = fopen(CONFIG_FILE, "r");
    if (!file) {
        return false;
    }

    char line[BUFFER_SIZE];
    while (fgets(line, sizeof(line), file)) {
        line[strcspn(line, "\n")] = '\0';
        if (strstr(line, "BYPASS=") != NULL) {
            fclose(file);
            return (strstr(line, "BYPASS=Yes") != NULL);
        }
    }

    fclose(file);
    return false;
}

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
    int delay_seconds = 5;
    bool bypass_enabled = is_bypass_enabled();

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

        // Check screen status
        bool current_screen_on = true;
        FILE *screen_pipe = popen("dumpsys window | grep \"mScreenOn\" | grep false", "r");
        if (screen_pipe) {
            char screen_buffer[BUFFER_SIZE];
            if (fgets(screen_buffer, sizeof(screen_buffer), screen_pipe)) {
                current_screen_on = false;
            }
            pclose(screen_pipe);
        }

        // Handle screen status changes and set delay
        if (current_screen_on != prev_screen_on) {
            if (current_screen_on) {
                printf("Screen turned on - setting delay to 5 seconds\n");
                delay_seconds = 5;
            } else {
                printf("Screen turned off - setting delay to 10 seconds for power conservation\n");
                delay_seconds = 10;
            }
            prev_screen_on = current_screen_on;
        }

        // Get focused app package using new method (only if screen is on)
        char matched_package[BUFFER_SIZE] = "";
        
        if (current_screen_on) {
            FILE *pipe_fp = popen("dumpsys window | grep 'mFocusedApp' | sed 's/.*ActivityRecord{[^ ]* [^ ]* \\([^ ]*\\/[^ ]*\\).*/\\1/'", "r");
            if (pipe_fp) {
                char buffer[BUFFER_SIZE];
                if (fgets(buffer, sizeof(buffer), pipe_fp)) {
                    // Remove newline character
                    buffer[strcspn(buffer, "\n")] = '\0';
                    
                    // Check if any game package pattern matches the focused app
                    for (int i = 0; i < num_patterns; i++) {
                        if (strstr(buffer, patterns[i]) != NULL) {
                            strncpy(matched_package, patterns[i], sizeof(matched_package) - 1);
                            matched_package[sizeof(matched_package) - 1] = '\0';
                            break;
                        }
                    }
                }
                pclose(pipe_fp);
            }
        }

        // Re-check bypass status each loop (allows runtime config changes)
        bypass_enabled = is_bypass_enabled();

        // Process app detection (only if screen is on)
        if (current_screen_on && strlen(matched_package) > 0) {
            // A game package was detected.
            if (last_executed != EXEC_GAME) {
                printf("Game package detected: %s\n", matched_package);
                char command[BUFFER_SIZE];
                snprintf(command, sizeof(command), "sh %s", PERFORMANCE_SCRIPT);
                system(command);
                
                // Execute bypass script with enable if enabled
                if (bypass_enabled) {
                    printf("Bypass enabled - executing bypass controller enable\n");
                    snprintf(command, sizeof(command), "sh %s enable", BYPASS_SCRIPT);
                    system(command);
                }
                
                last_executed = EXEC_GAME;
            }
        } else {
            // No game package detected.
            if (last_executed != EXEC_NORMAL) {
                printf("Non-game package detected\n");
                char command[BUFFER_SIZE];
                snprintf(command, sizeof(command), "sh %s", BALANCED_SCRIPT);
                system(command);
                
                // Execute bypass script with disable if it was previously enabled
                if (bypass_enabled && last_executed == EXEC_GAME) {
                    printf("Exiting game - executing bypass controller disable\n");
                    snprintf(command, sizeof(command), "sh %s disable", BYPASS_SCRIPT);
                    system(command);
                }
                
                last_executed = EXEC_NORMAL;
            }
        }
        
        sleep(delay_seconds);
    }

    return 0;
}