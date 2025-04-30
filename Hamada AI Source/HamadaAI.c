#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>

#define GAME_FILE "/data/adb/modules/EnCorinVest/game.txt"
#define SCRIPTS_DIR "/data/adb/modules/EnCorinVest/Scripts"
#define MAX_LINE 1024

// Dynamic array for game package names
char **load_game_list(size_t *count) {
    FILE *fp = fopen(GAME_FILE, "r");
    if (!fp) {
        perror("Failed to open game.txt");
        exit(EXIT_FAILURE);
    }
    char line[MAX_LINE];
    size_t capacity = 16;
    char **list = malloc(capacity * sizeof(char*));
    *count = 0;
    while (fgets(line, sizeof(line), fp)) {
        // Remove newline
        line[strcspn(line, "\r\n")] = '\0';
        if (strlen(line) == 0) continue;
        if (*count >= capacity) {
            capacity *= 2;
            list = realloc(list, capacity * sizeof(char*));
        }
        list[*count] = strdup(line);
        (*count)++;
    }
    fclose(fp);
    return list;
}

int main() {
    size_t game_count;
    char **game_list = load_game_list(&game_count);
    char current_mode[16] = "";

    while (true) {
        FILE *pipe = popen("dumpsys window", "r");
        if (!pipe) {
            perror("popen dumpsys failed");
            break;
        }

        bool game_detected = false;
        bool screen_off = false;
        char buf[MAX_LINE];

        while (fgets(buf, sizeof(buf), pipe)) {
            // Detect active window
            if (strstr(buf, "mCurrentFocus") || strstr(buf, "mFocusedApp")) {
                for (size_t i = 0; i < game_count; i++) {
                    if (strstr(buf, game_list[i])) {
                        game_detected = true;
                        break;
                    }
                }
            }
            // Detect screen off
            if (strstr(buf, "mScreen") && strstr(buf, "false")) {
                screen_off = true;
            }
        }
        pclose(pipe);

        // Determine target mode
        const char *target = game_detected ? "performance" : "balanced";
        if (strcmp(target, current_mode) != 0) {
            char script_path[MAX_LINE];
            snprintf(script_path, sizeof(script_path), "%s/%s.sh", SCRIPTS_DIR, target);
            // Execute the script
            if (system(script_path) == -1) {
                perror("Failed to execute script");
            }
            // Update current mode
            strncpy(current_mode, target, sizeof(current_mode)-1);
            current_mode[sizeof(current_mode)-1] = '\0';
        }

        // Set delay based on screen state
        int delay = screen_off ? 10 : 5;
        sleep(delay);
    }

    // Cleanup
    for (size_t i = 0; i < game_count; i++) free(game_list[i]);
    free(game_list);
    return 0;
}
