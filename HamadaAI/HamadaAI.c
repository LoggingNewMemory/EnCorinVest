#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>
#include <sys/stat.h> 
#include <time.h>     

// --- CONFIGURATION ---
// File paths for game list and performance scripts
#define GAME_LIST "/data/EnCorinVest/game.txt"
#define PERFORMANCE_SCRIPT "/data/adb/modules/EnCorinVest/Scripts/performance.sh"
#define BALANCED_SCRIPT "/data/adb/modules/EnCorinVest/Scripts/balanced.sh"

// --- CONSTANTS ---
#define MAX_PATTERNS 256
#define MAX_PATTERN_LENGTH 256
#define BUFFER_SIZE 1024

// Represents the currently active performance profile
typedef enum {
    PROFILE_NONE,
    PROFILE_GAME,
    PROFILE_BALANCED
} ProfileType;

// --- FUNCTION PROTOTYPES ---
int load_game_patterns(char patterns[MAX_PATTERNS][MAX_PATTERN_LENGTH]);
bool is_screen_on(void);
void get_focused_app(char* app_buffer, size_t buffer_size);
bool is_game_focused(const char* focused_app, int num_patterns, const char patterns[MAX_PATTERNS][MAX_PATTERN_LENGTH]);
void apply_profile(ProfileType new_profile, ProfileType* last_profile);
time_t get_file_mod_time(const char* path);


// --- MAIN FUNCTION ---
int main(void) {
    char game_patterns[MAX_PATTERNS][MAX_PATTERN_LENGTH];
    int num_patterns = 0;
    time_t last_modified_time = 0;

    ProfileType last_applied_profile = PROFILE_NONE;
    int sleep_delay_seconds = 5;

    // Initial check to ensure scripts are executable (optional but good practice)
    if (access(PERFORMANCE_SCRIPT, X_OK) != 0 || access(BALANCED_SCRIPT, X_OK) != 0) {
        fprintf(stderr, "Error: Performance or Balanced script not found or not executable.\n");
        return 1;
    }


    while (1) {
        // --- Dynamic Game List Reloading Logic ---
        time_t current_mod_time = get_file_mod_time(GAME_LIST);
        if (current_mod_time != last_modified_time) {
            printf("Change detected in %s. Reloading game list...\n", GAME_LIST);
            int loaded_count = load_game_patterns(game_patterns);
            if (loaded_count != -1) {
                num_patterns = loaded_count;
                last_modified_time = current_mod_time;
                printf("%d game patterns loaded.\n", num_patterns);
            }
        }
        
        // --- Main Profile Switching Logic ---
        if (is_screen_on()) {
            sleep_delay_seconds = 5; // Use shorter delay for responsiveness when screen is on

            char focused_app[BUFFER_SIZE] = "";
            get_focused_app(focused_app, sizeof(focused_app));

            if (strlen(focused_app) > 0 && is_game_focused(focused_app, num_patterns, (const char(*)[MAX_PATTERN_LENGTH])game_patterns)) {
                apply_profile(PROFILE_GAME, &last_applied_profile);
            } else {
                apply_profile(PROFILE_BALANCED, &last_applied_profile);
            }
        } else {
            // Screen is off, apply balanced profile and sleep longer to conserve power
            sleep_delay_seconds = 10;
            apply_profile(PROFILE_BALANCED, &last_applied_profile);
        }
        
        sleep(sleep_delay_seconds);
    }

    return 0; // Unreachable
}


// --- FUNCTION IMPLEMENTATIONS ---

/**
 * @brief Gets the last modification time of a file.
 * @param path The path to the file.
 * @return The last modification time (time_t), or 0 on error.
 */
time_t get_file_mod_time(const char* path) {
    struct stat attr;
    if (stat(path, &attr) == 0) {
        return attr.st_mtime;
    }
    perror("stat");
    return 0;
}

/**
 * @brief Loads game package patterns from the GAME_LIST file into memory.
 * @param patterns A 2D array to store the loaded patterns.
 * @return The number of patterns loaded, or -1 on error.
 */
int load_game_patterns(char patterns[MAX_PATTERNS][MAX_PATTERN_LENGTH]) {
    FILE *file = fopen(GAME_LIST, "r");
    if (!file) {
        fprintf(stderr, "Error: Could not open %s\n", GAME_LIST);
        return -1;
    }

    int count = 0;
    char line[BUFFER_SIZE];
    while (fgets(line, sizeof(line), file) && count < MAX_PATTERNS) {
        line[strcspn(line, "\n")] = '\0'; // Remove newline character

        // Skip empty lines or lines with spaces
        if (line[0] == '\0' || strchr(line, ' ') != NULL) {
            continue;
        }

        strncpy(patterns[count], line, MAX_PATTERN_LENGTH - 1);
        patterns[count][MAX_PATTERN_LENGTH - 1] = '\0';
        count++;
    }

    fclose(file);
    return count;
}

/**
 * @brief Checks if the device screen is currently on.
 * @return True if the screen is on, false otherwise.
 */
bool is_screen_on(void) {
    // This command is generally reliable and efficient for checking screen state.
    FILE *pipe = popen("dumpsys input_method | grep -q 'mInteractive=true'", "r");
    if (pipe) {
        int status = pclose(pipe);
        // WEXITSTATUS extracts the return code. 0 means grep found a match (screen is on).
        return (WEXITSTATUS(status) == 0);
    }
    // Fallback: Assume screen is on if the command fails to run.
    return true;
}

/**
 * @brief Retrieves the package name of the currently focused application.
 * @param app_buffer The buffer to store the focused app name.
 * @param buffer_size The size of the app_buffer.
 */
void get_focused_app(char* app_buffer, size_t buffer_size) {
    // This command is a more direct way to get the currently focused app component.
    const char* cmd = "dumpsys window | grep 'mCurrentFocus' | cut -d ' ' -f 5 | cut -d '}' -f 1";
    FILE *pipe = popen(cmd, "r");
    if (!pipe) {
        perror("popen failed for get_focused_app");
        return;
    }

    if (fgets(app_buffer, buffer_size, pipe)) {
        app_buffer[strcspn(app_buffer, "\n")] = '\0'; // Remove newline character
    }
    pclose(pipe);
}

/**
 * @brief Checks if the focused app matches any of the game patterns.
 * @param focused_app The package name of the focused app.
 * @param num_patterns The total number of game patterns.
 * @param patterns A 2D array containing the game patterns.
 * @return True if a match is found, false otherwise.
 */
bool is_game_focused(const char* focused_app, int num_patterns, const char patterns[MAX_PATTERNS][MAX_PATTERN_LENGTH]) {
    for (int i = 0; i < num_patterns; i++) {
        // strstr checks if the pattern exists anywhere in the focused_app string.
        if (strstr(focused_app, patterns[i]) != NULL) {
            return true;
        }
    }
    return false;
}

/**
 * @brief Applies a new performance profile, avoiding redundant script executions.
 * @param new_profile The desired profile (PROFILE_GAME or PROFILE_BALANCED).
 * @param last_profile A pointer to the currently active profile.
 */
void apply_profile(ProfileType new_profile, ProfileType* last_profile) {
    // If the desired profile is already active, do nothing. This is key for efficiency.
    if (new_profile == *last_profile) {
        return;
    }

    char command[BUFFER_SIZE];
    if (new_profile == PROFILE_GAME) {
        printf("Game detected. Applying PERFORMANCE profile.\n");
        snprintf(command, sizeof(command), "sh %s", PERFORMANCE_SCRIPT);
    } else { // PROFILE_BALANCED
        printf("No game detected. Applying BALANCED profile.\n");
        snprintf(command, sizeof(command), "sh %s", BALANCED_SCRIPT);
    }

    system(command);
    *last_profile = new_profile;
}