#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <stdbool.h>

#define GAME_LIST_PATH "/data/adb/modules/EnCorinVest/game.txt"
#define PERFORMANCE_SCRIPT "/data/adb/modules/EnCorinVest/Scripts/performance.sh"
#define BALANCED_SCRIPT "/data/adb/modules/EnCorinVest/Scripts/balanced.sh"
#define MAX_PACKAGE_NAME 256
#define MAX_LINE_LENGTH 1024
#define DEFAULT_DELAY 5
#define SCREEN_OFF_DELAY 10

// Global variables
volatile sig_atomic_t keep_running = 1;
bool is_in_game = false;
bool previous_game_state = false;

// Signal handler for clean termination
void handle_signal(int sig) {
    printf("Received signal %d, shutting down...\n", sig);
    keep_running = 0;
}

// Function to check if a package name is a game
bool is_game(const char *package_name) {
    FILE *game_list = fopen(GAME_LIST_PATH, "r");
    if (game_list == NULL) {
        perror("Failed to open game list");
        return false;
    }

    char line[MAX_LINE_LENGTH];
    bool result = false;

    while (fgets(line, sizeof(line), game_list)) {
        // Remove newline character if present
        size_t len = strlen(line);
        if (len > 0 && line[len - 1] == '\n') {
            line[len - 1] = '\0';
        }

        if (strstr(package_name, line) != NULL) {
            result = true;
            break;
        }
    }

    fclose(game_list);
    return result;
}

// Function to get current focused package name
char* get_current_package() {
    static char package_name[MAX_PACKAGE_NAME];
    FILE *fp;
    char buffer[MAX_LINE_LENGTH];

    package_name[0] = '\0'; // Initialize empty string

    fp = popen("dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'", "r");
    if (fp == NULL) {
        perror("Failed to run command");
        return package_name;
    }

    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        char *substr = strstr(buffer, "com.");
        if (substr != NULL) {
            char *end = strpbrk(substr, " \t\n/}");
            if (end != NULL) {
                int length = end - substr;
                if (length < MAX_PACKAGE_NAME) {
                    strncpy(package_name, substr, length);
                    package_name[length] = '\0';
                    break;
                }
            }
        }
    }

    pclose(fp);
    return package_name;
}

// Function to check if screen is on
bool is_screen_on() {
    FILE *fp;
    char buffer[MAX_LINE_LENGTH];
    bool screen_on = true;

    fp = popen("dumpsys window | grep mScreen", "r");
    if (fp == NULL) {
        perror("Failed to run command");
        return true; // Assume screen is on by default
    }

    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        if (strstr(buffer, "mScreenOn=false") != NULL) {
            screen_on = false;
            break;
        }
    }

    pclose(fp);
    return screen_on;
}

// Function to execute shell script
void execute_script(const char *script_path) {
    printf("Executing: %s\n", script_path);
    
    char command[MAX_LINE_LENGTH];
    snprintf(command, sizeof(command), "sh %s", script_path);
    
    int result = system(command);
    if (result != 0) {
        fprintf(stderr, "Failed to execute script: %s (exit code: %d)\n", script_path, result);
    }
}

int main() {
    // Set up signal handlers for clean termination
    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);
    
    printf("HamadaAI Next Gen service started\n");
    
    time_t last_check_time = 0;
    int current_delay = DEFAULT_DELAY;
    
    while (keep_running) {
        time_t current_time = time(NULL);
        
        // Only perform checks at the specified delay interval
        if (difftime(current_time, last_check_time) >= current_delay) {
            last_check_time = current_time;
            
            // Check screen state
            bool screen_on = is_screen_on();
            
            if (screen_on) {
                // If screen was previously off and now on, reset delay
                if (current_delay != DEFAULT_DELAY) {
                    printf("Screen is now ON. Setting delay to %d seconds.\n", DEFAULT_DELAY);
                    current_delay = DEFAULT_DELAY;
                }
                
                // Get current package and check if it's a game
                char *package_name = get_current_package();
                if (strlen(package_name) > 0) {
                    printf("Current focused app: %s\n", package_name);
                    is_in_game = is_game(package_name);
                    
                    // Execute the appropriate script when state changes
                    if (is_in_game != previous_game_state) {
                        if (is_in_game) {
                            printf("Game detected, applying performance profile\n");
                            execute_script(PERFORMANCE_SCRIPT);
                        } else {
                            printf("Not in game, applying balanced profile\n");
                            execute_script(BALANCED_SCRIPT);
                        }
                        previous_game_state = is_in_game;
                    }
                }
            } else {
                // Screen is off, increase delay to save battery
                if (current_delay != SCREEN_OFF_DELAY) {
                    printf("Screen is OFF. Setting delay to %d seconds to save battery.\n", SCREEN_OFF_DELAY);
                    current_delay = SCREEN_OFF_DELAY;
                }
            }
        }
        
        // Small sleep to prevent CPU hogging
        usleep(100000); // 100ms
    }
    
    printf("HamadaAI Next Gen service stopped\n");
    return 0;
}

// Placeholder