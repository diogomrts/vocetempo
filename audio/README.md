# Vocetempo - Audio clips

Speech clips for the DFPlayer Mini. Files live in `mp3/` named `0001.mp3`,
`0002.mp3`, ... and are addressed by index from the firmware
(`audio.playIndex(n)` -> `/mp3/000n.mp3`).

## microSD layout

Copy the `mp3/` folder to the root of a FAT32-formatted card, then strip
macOS metadata before using it in the DFPlayer:

```sh
cp -R mp3 "/Volumes/<CARD>/mp3"
dot_clean "/Volumes/<CARD>"
# remove Spotlight/fseventsd dirs and disable indexing:
rm -rf "/Volumes/<CARD>/.Spotlight-V100" "/Volumes/<CARD>/.fseventsd"
mdutil -i off "/Volumes/<CARD>"
diskutil eject "/Volumes/<CARD>"
```

## Generating clips (macOS)

Clips are synthesized with the built-in `say` TTS and boosted for loudness so
they are clearly audible through the small speaker at DFPlayer volume 30.

Example (the current `0001.mp3`, "It is"):

```sh
say -v Samantha -o tmp.aiff "It is"
ffmpeg -y -i tmp.aiff \
  -af "acompressor=threshold=-20dB:ratio=6:attack=3:release=80:makeup=8,volume=6dB,alimiter=level_in=1:level_out=1:limit=0.97" \
  -ar 44100 -ac 1 -b:a 128k mp3/0001.mp3
rm tmp.aiff
```

The compressor + gain + limiter chain raises the average level (mean volume
about -9.5 dB, peaks at 0 dB) without hard clipping. Check levels with:

```sh
ffmpeg -i mp3/0001.mp3 -af volumedetect -f null /dev/null 2>&1 | grep volume
```

## Clip set (full pre-rendered phrases)

The clock speaks each time as ONE complete pre-rendered sentence, so playback
is gapless and naturally intonated (the DFPlayer is slow at chaining files,
which made the earlier word-by-word approach sound choppy).

Index scheme (files mp3/NNNN.mp3), 12-hour format:

    index = hour24 * 60 + minute + 1      (range 1..1440)

Examples:
    00:00 -> 0001.mp3  "It is midnight"
    12:00 -> 0721.mp3  "It is noon"
    09:05 -> 0546.mp3  "It is nine oh five A.M."
    22:45 -> 1366.mp3  "It is ten forty-five P.M."

The firmware's speakTime() (src/Audio.cpp) computes this index and plays the
single file. The formula there MUST match generate_phrases.py.

Regenerate all 1440 phrases:

```sh
cd audio
python3 generate_phrases.py --voice Samantha --workers 8
```

(generate_clips.py is the older modular word-clip generator, kept for
reference but no longer used.)
