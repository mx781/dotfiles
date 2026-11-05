#!/bin/sh
# Each layout lists only the outputs it wants enabled. Disable everything else
# reported by X, including outputs added by a dock or another provider.
set -eu

query=$(xrandr --query)
outputs=$(printf '%s\n' "$query" | awk '$2 == "connected" || $2 == "disconnected" { print $1, $2 }')
enabled=
previous=
for argument do
    if [ "$previous" = --output ]; then
        if ! printf '%s\n' "$outputs" | awk -v output="$argument" '
            $1 == output && $2 == "connected" { found = 1 }
            END { exit !found }
        '; then
            printf 'Screen layout: output %s is not connected\n' "$argument" >&2
            exit 1
        fi
        enabled="$enabled $argument"
    fi
    previous=$argument
done

if [ -z "$enabled" ]; then
    printf 'Screen layout: no outputs selected\n' >&2
    exit 1
fi

for output in $(printf '%s\n' "$outputs" | awk '{ print $1 }'); do
    case " $enabled " in
        *" $output "*) ;;
        *) set -- "$@" --output "$output" --off ;;
    esac
done

exec xrandr "$@"
