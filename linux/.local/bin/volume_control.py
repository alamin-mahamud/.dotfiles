#!/usr/bin/env python3
import subprocess
import sys
from typing import List


def run_command(command: str) -> List[str]:
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    return result.stdout.strip().split("\n")


def get_active_sink() -> str:
    return run_command("pacmd list-sinks | grep '* index' | awk '{print $3}'")[0]


def get_volume() -> int:
    return int(
        run_command(
            'amixer -D pulse get Master | grep -o "[.*%]" | grep -o "[0-9]*" | head -n1'
        )[0]
    )


def set_volume(percentage: int) -> None:
    run_command(f"pactl set-sink-volume {get_active_sink()} {percentage}%")
    emit_signal()
    send_notification()


def toggle_volume() -> None:
    run_command("amixer -D pulse set Master Playback Switch toggle")
    emit_signal()
    send_notification()


def is_muted() -> bool:
    return not bool(
        run_command('amixer -D pulse get Master | grep -o "\[on\]" | head -n1')
    )


def write(message: str) -> None:
    sys.stdout.write(message)
    sys.stdout.flush()


def trim_to_range(volume: int) -> int:
    return max(0, min(200, volume))


def status() -> str:
    return "muted" if get_volume() == 0 or is_muted() else "on"


def emit_signal() -> None:
    run_command("pkill -RTMIN+1 i3blocks")


def send_notification() -> None:
    volume = get_volume()
    if volume == 0:
        icon_name = "volume-off"
    elif volume < 10:
        icon_name = "volume-low"
    elif volume < 30:
        icon_name = "volume-low"
    elif volume < 70:
        icon_name = "volume-medium"
    else:
        icon_name = "volume-high"

    icon_path = f"/path/to/icons/{icon_name}.svg"
    subprocess.run(
        [
            "dunstify",
            f"Volume: {volume}",
            "-i",
            icon_path,
            "-t",
            "2000",
            "--replace=555",
        ]
    )


def main() -> None:
    if len(sys.argv) < 2:
        write(
            "Usage: "
            + sys.argv[0]
            + " [set|up|down|toggle|read|status|i3blocks|signal] [value]\n"
        )
        return

    command = sys.argv[1]

    if command == "set" and len(sys.argv) == 3:
        set_volume(trim_to_range(int(sys.argv[2])))
    elif command == "up" and len(sys.argv) == 3:
        new_volume = trim_to_range(get_volume() + int(sys.argv[2]))
        set_volume(new_volume)
    elif command == "down" and len(sys.argv) == 3:
        new_volume = trim_to_range(get_volume() - int(sys.argv[2]))
        set_volume(new_volume)
    elif command == "toggle":
        toggle_volume()
    elif command == "read":
        write(str(get_volume()))
    elif command == "status":
        write(status())
    elif command == "i3blocks":
        output = get_volume()
        if is_muted():
            output += "\n\n#cc241d"
        write(output)
    elif command == "signal":
        emit_signal()
    else:
        write(
            "Usage: "
            + sys.argv[0]
            + " [set|up|down|toggle|read|status|i3blocks|signal] [value]\n"
        )


if __name__ == "__main__":
    main()
