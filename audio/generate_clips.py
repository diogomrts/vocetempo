#!/usr/bin/env python3
"""
Vocetempo - speech clip generator.

Generates the modular speech clips used to speak the time, using the macOS
`say` TTS engine and ffmpeg for loudness-boosted MP3 output.

Clip index map (files land in mp3/000N.mp3):
    0001  "It is"
    0002  "oh"          (leading-zero minutes, e.g. "ten oh five")
    0003  "o'clock"
    0004  "AM"
    0005  "PM"
    0006  "midnight"
    0007  "noon"
    0010..0069  numbers 0..59  (index = 10 + N)

Re-run any time to regenerate. Requires: say, ffmpeg (brew install ffmpeg).

Usage:  python3 generate_clips.py [--voice Samantha]
"""

import argparse
import os
import subprocess
import sys

# Number words 0..59 (explicit words = reliable pronunciation).
ONES = ["zero", "one", "two", "three", "four", "five", "six", "seven",
        "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
        "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
TENS = {20: "twenty", 30: "thirty", 40: "forty", 50: "fifty"}


def number_words(n: int) -> str:
    if n < 20:
        return ONES[n]
    tens = (n // 10) * 10
    ones = n % 10
    if ones == 0:
        return TENS[tens]
    return f"{TENS[tens]}-{ONES[ones]}"


# Fixed-phrase clips by index.
PHRASES = {
    1: "It is",
    2: "oh",
    3: "o'clock",
    4: "A.M.",
    5: "P.M.",
    6: "midnight",
    7: "noon",
}

# Audio processing chain:
#  1. silenceremove: trim leading AND trailing silence so clips play back-to-
#     back with no dead air (the main cause of "slow" speech).
#  2. compressor + gain + limiter: even out and lift level so clips are clearly
#     audible without clipping (kept moderate now that one speaker is used).
AUDIO_FILTER = (
    "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.02:"
    "stop_periods=1:stop_threshold=-45dB:stop_silence=0.05:detection=peak,"
    "areverse,"
    "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.02:detection=peak,"
    "areverse,"
    "acompressor=threshold=-20dB:ratio=4:attack=3:release=80:makeup=6,"
    "alimiter=level_in=1:level_out=1:limit=0.97"
)


def make_clip(index: int, text: str, voice: str, out_dir: str) -> None:
    aiff = os.path.join(out_dir, f"_tmp_{index}.aiff")
    mp3 = os.path.join(out_dir, f"{index:04d}.mp3")

    subprocess.run(["say", "-v", voice, "-o", aiff, text], check=True)
    subprocess.run(
        ["ffmpeg", "-y", "-i", aiff, "-af", AUDIO_FILTER,
         "-ar", "44100", "-ac", "1", "-b:a", "128k", mp3],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    os.remove(aiff)
    print(f"  {index:04d}.mp3  <- \"{text}\"")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--voice", default="Samantha")
    args = parser.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    out_dir = os.path.join(here, "mp3")
    os.makedirs(out_dir, exist_ok=True)

    print(f"Generating clips with voice '{args.voice}' into {out_dir}")

    # Fixed phrases.
    for index, text in PHRASES.items():
        make_clip(index, text, args.voice, out_dir)

    # Numbers 0..59 -> index 10 + N.
    for n in range(0, 60):
        make_clip(10 + n, number_words(n), args.voice, out_dir)

    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
