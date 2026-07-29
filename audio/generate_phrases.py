#!/usr/bin/env python3
"""
Vocetempo - full-phrase speech generator (12-hour format).

Synthesizes ONE complete spoken sentence per time-of-day, so the clock speaks
with a single gapless playback (no clip chaining, natural prosody).

File index scheme (files in mp3/ named NNNN.mp3):
    index = hour24 * 60 + minute + 1     -> range 1..1440

Example: 22:45 -> index 1366 -> "It is ten forty-five P.M."

Runs `say` + ffmpeg in parallel for speed. Requires: say, ffmpeg.

Usage:  python3 generate_phrases.py [--voice Samantha] [--workers 8]
"""

import argparse
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

ONES = ["zero", "one", "two", "three", "four", "five", "six", "seven",
        "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
        "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
TENS = {20: "twenty", 30: "thirty", 40: "forty", 50: "fifty"}


def number_words(n: int) -> str:
    if n < 20:
        return ONES[n]
    tens, ones = (n // 10) * 10, n % 10
    return TENS[tens] if ones == 0 else f"{TENS[tens]}-{ONES[ones]}"


def phrase_for(hour24: int, minute: int) -> str:
    """Build the spoken sentence for a 12-hour clock."""
    if hour24 == 0 and minute == 0:
        return "It is midnight"
    if hour24 == 12 and minute == 0:
        return "It is noon"

    h12 = hour24 % 12
    if h12 == 0:
        h12 = 12
    ampm = "P.M." if hour24 >= 12 else "A.M."
    hw = number_words(h12)

    if minute == 0:
        return f"It is {hw} o'clock {ampm}"
    if minute < 10:
        return f"It is {hw} oh {number_words(minute)} {ampm}"
    return f"It is {hw} {number_words(minute)} {ampm}"


# Trim ONLY leading/trailing silence (never mid-phrase, so long sentences are
# not cut off), then moderate loudness for one speaker at DFPlayer volume ~18.
AUDIO_FILTER = (
    "silenceremove=start_periods=1:start_threshold=-40dB:start_silence=0.1,"
    "areverse,"
    "silenceremove=start_periods=1:start_threshold=-40dB:start_silence=0.1,"
    "areverse,"
    "acompressor=threshold=-20dB:ratio=4:attack=3:release=80:makeup=6,"
    "alimiter=level_in=1:level_out=1:limit=0.97"
)


def make_one(args):
    index, text, voice, out_dir = args
    aiff = os.path.join(out_dir, f"_p_{index}.aiff")
    mp3 = os.path.join(out_dir, f"{index:04d}.mp3")
    subprocess.run(["say", "-v", voice, "-o", aiff, text], check=True)
    subprocess.run(
        ["ffmpeg", "-y", "-i", aiff, "-af", AUDIO_FILTER,
         "-ar", "44100", "-ac", "1", "-b:a", "128k", mp3],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    os.remove(aiff)
    return index, text


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--voice", default="Samantha")
    ap.add_argument("--workers", type=int, default=8)
    args = ap.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    out_dir = os.path.join(here, "mp3")
    os.makedirs(out_dir, exist_ok=True)

    jobs = []
    for hour24 in range(24):
        for minute in range(60):
            index = hour24 * 60 + minute + 1
            jobs.append((index, phrase_for(hour24, minute), args.voice, out_dir))

    print(f"Generating {len(jobs)} phrases with '{args.voice}' "
          f"using {args.workers} workers...")

    done = 0
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(make_one, j) for j in jobs]
        for f in as_completed(futs):
            f.result()
            done += 1
            if done % 120 == 0:
                print(f"  {done}/{len(jobs)} done")

    print(f"Done. {done} files in {out_dir}")
    # Show a couple of samples.
    for hh, mm in [(0, 0), (12, 0), (22, 45), (9, 5)]:
        print(f"  {hh:02d}:{mm:02d} -> {hh*60+mm+1:04d}.mp3  \"{phrase_for(hh, mm)}\"")
    return 0


if __name__ == "__main__":
    sys.exit(main())
