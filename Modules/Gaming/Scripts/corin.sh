tweak() {
    if [ -e "$2" ]; then
        chmod 644 "$2" >/dev/null 2>&1
        echo "$1" > "$2" 2>/dev/null
        chmod 444 "$2" >/dev/null 2>&1
    fi
}

corin_perf() {
# FreakZy Storage

tweak "deadline" "$deviceio/queue/scheduler"
tweak 1 "$queue/rq_affinity"

# Settings Set | Supposed All Devices Have

# Optimize Priority
settings put secure high_priority 1
settings put secure low_priority 0

# From MTKVest

cmd power set-adaptive-power-saver-enabled false
cmd power set-fixed-performance-mode-enabled true

# From Corin 
cmd looper_stats disable

# Power Save Mode Off
settings put global low_power 0
}

corin_balanced() {
# FreakZy Storage

tweak "deadline" "$deviceio/queue/scheduler"
tweak 1 "$queue/rq_affinity"

# Settings Set | Supposed All Devices Have

# Optimize Priority
settings put secure high_priority 1
settings put secure low_priority 0

# From MTKVest

cmd power set-adaptive-power-saver-enabled false
cmd power set-fixed-performance-mode-enabled false

# From Corin 
cmd looper_stats enable

# Power Save Mode Off
settings put global low_power 0
}

corin_powersave() {
# FreakZy Storage

tweak "deadline" "$deviceio/queue/scheduler"
tweak 2 "$queue/rq_affinity"

# Settings Set | Supposed All Devices Have

# Optimize Priority
settings put secure high_priority 0
settings put secure low_priority 1

# From MTKVest

cmd power set-adaptive-power-saver-enabled true
cmd power set-fixed-performance-mode-enabled false

# From Corin 
cmd looper_stats enable

# Power Save Mode On
settings put global low_power 1
}