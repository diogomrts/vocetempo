#!/usr/bin/env python3
"""
Vocetempo - multilingual full-phrase generator.

Generates one complete spoken sentence per time-of-day, for each language, all
into the /mp3 folder using a per-language INDEX OFFSET (this DFPlayer clone
only supports playMp3Folder(n) -> /mp3/NNNN.mp3, not folder addressing).

Index scheme:
    within a language: slot = hour24 * 60 + minute + 1      (1..1440)
    file index        = language_offset + slot

    English    offset    0  -> 0001..1440
    Portuguese offset 2000  -> 2001..3440
    Spanish    offset 4000  -> 4001..5440

12-hour speech style in every language (matches the firmware's 12/24h toggle
default of 12h). Grammar handled per language.

Runs say + ffmpeg in parallel. Usage:
    python3 generate_multilang.py [--langs en pt es] [--workers 8]
"""

import argparse
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

# ---------------------------------------------------------------------------
# English
# ---------------------------------------------------------------------------
EN_ONES = ["zero", "one", "two", "three", "four", "five", "six", "seven",
           "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
           "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
EN_TENS = {20: "twenty", 30: "thirty", 40: "forty", 50: "fifty"}


def en_num(n):
    if n < 20:
        return EN_ONES[n]
    t, o = (n // 10) * 10, n % 10
    return EN_TENS[t] if o == 0 else f"{EN_TENS[t]}-{EN_ONES[o]}"


def en_phrase(h24, m):
    if h24 == 0 and m == 0:
        return "It is midnight"
    if h24 == 12 and m == 0:
        return "It is noon"
    h = h24 % 12 or 12
    ap = "P.M." if h24 >= 12 else "A.M."
    if m == 0:
        return f"It is {en_num(h)} o'clock {ap}"
    if m < 10:
        return f"It is {en_num(h)} oh {en_num(m)} {ap}"
    return f"It is {en_num(h)} {en_num(m)} {ap}"


# ---------------------------------------------------------------------------
# Portuguese (PT-PT). Time: "sao/e" (plural) vs "e" (1h). Minutes with "e".
#   1:00 -> "E uma hora"; 2:00 -> "Sao duas horas"; 10:45 -> "Sao dez e
#   quarenta e cinco"; uses "da manha/tarde/noite" for AM/PM feel is optional -
#   we keep it simple and clear.
# ---------------------------------------------------------------------------
PT_ONES = ["zero", "uma", "duas", "três", "quatro", "cinco", "seis", "sete",
           "oito", "nove", "dez", "onze", "doze", "treze", "catorze", "quinze",
           "dezasseis", "dezassete", "dezoito", "dezanove"]
PT_TENS = {20: "vinte", 30: "trinta", 40: "quarenta", 50: "cinquenta"}


def pt_num(n):
    if n < 20:
        return PT_ONES[n]
    t, o = (n // 10) * 10, n % 10
    return PT_TENS[t] if o == 0 else f"{PT_TENS[t]} e {PT_ONES[o]}"


def pt_phrase(h24, m):
    if h24 == 0 and m == 0:
        return "É meia-noite"
    if h24 == 12 and m == 0:
        return "É meio-dia"
    h = h24 % 12 or 12
    # "uma" for 1 o'clock (singular), otherwise plural.
    verb = "É" if h == 1 else "São"
    hora = "hora" if h == 1 else "horas"
    if m == 0:
        return f"{verb} {pt_num(h)} {hora}"
    return f"{verb} {pt_num(h)} e {pt_num(m)}"


# ---------------------------------------------------------------------------
# Spanish (es-MX). Time: "Es la una" (1h singular) vs "Son las dos" (plural).
#   Minutes joined with "y": "Son las diez y cuarenta y cinco".
# ---------------------------------------------------------------------------
ES_ONES = ["cero", "una", "dos", "tres", "cuatro", "cinco", "seis", "siete",
           "ocho", "nueve", "diez", "once", "doce", "trece", "catorce",
           "quince", "dieciséis", "diecisiete", "dieciocho", "diecinueve"]
ES_TENS = {20: "veinte", 30: "treinta", 40: "cuarenta", 50: "cincuenta"}


def es_num(n):
    if n < 20:
        return ES_ONES[n]
    t, o = (n // 10) * 10, n % 10
    if o == 0:
        return ES_TENS[t]
    # 21-29 has special contracted forms; use "veinti..." for 20s.
    if t == 20:
        veinti = {1: "veintiuno", 2: "veintidós", 3: "veintitrés",
                  4: "veinticuatro", 5: "veinticinco", 6: "veintiséis",
                  7: "veintisiete", 8: "veintiocho", 9: "veintinueve"}
        return veinti[o]
    return f"{ES_TENS[t]} y {ES_ONES[o]}"


def es_phrase(h24, m):
    if h24 == 0 and m == 0:
        return "Es medianoche"
    if h24 == 12 and m == 0:
        return "Es mediodía"
    h = h24 % 12 or 12
    verb = "Es la" if h == 1 else "Son las"
    if m == 0:
        return f"{verb} {es_num(h)} en punto"
    return f"{verb} {es_num(h)} y {es_num(m)}"


LANGS = {
    "en": {"offset": 0,    "voice": "Samantha", "fn": en_phrase},
    "pt": {"offset": 2000, "voice": "Joana",    "fn": pt_phrase},
    "es": {"offset": 4000, "voice": "Paulina",  "fn": es_phrase},
}

# Trim ONLY leading and trailing silence, never mid-phrase. We do this by
# trimming leading silence, then reversing and trimming the (new) leading
# silence, then reversing back. Using start_periods=1 with a modest threshold
# removes just the silence before the first/after the last sound, leaving the
# natural short gaps between words intact (so long phrases are not cut off).
AUDIO_FILTER = (
    "silenceremove=start_periods=1:start_threshold=-40dB:start_silence=0.1,"
    "areverse,"
    "silenceremove=start_periods=1:start_threshold=-40dB:start_silence=0.1,"
    "areverse,"
    "acompressor=threshold=-20dB:ratio=4:attack=3:release=80:makeup=6,"
    "alimiter=level_in=1:level_out=1:limit=0.97"
)


SKIP_EXISTING = False


def make_one(job):
    index, text, voice, out_dir = job
    mp3 = os.path.join(out_dir, f"{index:04d}.mp3")
    # Resume support: skip files that already exist and are non-empty.
    if SKIP_EXISTING and os.path.exists(mp3) and os.path.getsize(mp3) > 0:
        return index
    aiff = os.path.join(out_dir, f"_ml_{index}.aiff")
    subprocess.run(["say", "-v", voice, "-o", aiff, text], check=True)
    subprocess.run(
        ["ffmpeg", "-y", "-i", aiff, "-af", AUDIO_FILTER,
         "-ar", "44100", "-ac", "1", "-b:a", "128k", mp3],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(aiff)
    return index


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--langs", nargs="+", default=["pt", "es"],
                    help="languages to generate (en pt es)")
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--skip-existing", action="store_true",
                    help="skip files that already exist (resume a run)")
    args = ap.parse_args()

    global SKIP_EXISTING
    SKIP_EXISTING = args.skip_existing

    here = os.path.dirname(os.path.abspath(__file__))
    out_dir = os.path.join(here, "mp3")
    os.makedirs(out_dir, exist_ok=True)

    jobs = []
    for lang in args.langs:
        cfg = LANGS[lang]
        for h24 in range(24):
            for m in range(60):
                slot = h24 * 60 + m + 1
                index = cfg["offset"] + slot
                jobs.append((index, cfg["fn"](h24, m), cfg["voice"], out_dir))

    print(f"Generating {len(jobs)} files for langs={args.langs} "
          f"with {args.workers} workers...")
    done = 0
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(make_one, j) for j in jobs]
        for f in as_completed(futs):
            f.result()
            done += 1
            if done % 240 == 0:
                print(f"  {done}/{len(jobs)}")

    print(f"Done. {done} files.")
    # Samples.
    for lang in args.langs:
        cfg = LANGS[lang]
        for hh, mm in [(0, 0), (13, 45), (9, 5), (1, 0)]:
            idx = cfg["offset"] + hh * 60 + mm + 1
            print(f"  [{lang}] {hh:02d}:{mm:02d} -> {idx:04d}.mp3  "
                  f"\"{cfg['fn'](hh, mm)}\"")


if __name__ == "__main__":
    sys.exit(main())
