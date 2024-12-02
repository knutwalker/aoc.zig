alias i := input
alias d := day
alias t := test
alias m := measure
alias b := bench

input DAY=shell('date +%-d'):
    curl --cookie "session=${AOC_SESSION_COOKIE}" "https://adventofcode.com/2024/day/{{DAY}}/input" > src/data/day{{DAY}}.txt
    bat src/data/day{{DAY}}.txt

day DAY=shell('date +%-d'):
    watchexec zig build day{{DAY}}

test DAY=shell('date +%-d'):
    watchexec zig build test_day{{DAY}}

measure DAY=shell('date +%-d'):
    zig build -Dbench -Doptimize=ReleaseFast day{{DAY}}

bench DAY=shell('date +%-d'):
    @> benches_day{{DAY}}.jsonld
    @zig build -Dbench -Doptimize=ReleaseFast day{{DAY}} >/dev/null 2>benches_day{{DAY}}.jsonld
    @zig build -Dbench -Doptimize=ReleaseFast day{{DAY}} >/dev/null 2>benches_day{{DAY}}.jsonld
    @zig build -Dbench -Doptimize=ReleaseFast day{{DAY}} >/dev/null 2>benches_day{{DAY}}.jsonld
    @zig build -Dbench -Doptimize=ReleaseFast day{{DAY}} >/dev/null 2>benches_day{{DAY}}.jsonld
    @zig build -Dbench -Doptimize=ReleaseFast day{{DAY}} >/dev/null 2>benches_day{{DAY}}.jsonld

    @jq -s -r 'group_by(.label) | map(. | [.[0].label, ( [.[] | .wall_time_ns] | add/length/1000000), ( [.[] | .user_time_ns] | add/length/1000000), ( [.[] | .heap_bytes] | add/length/1024/1024) ]) | [["label", "wall_ms", "user_ms", "heap_mb"], (.[] | map(values))] | .[] | @csv' benches_day{{DAY}}.jsonld

