# Captioning

`wsu_caption.py` makes WebVTT (`.vtt`) caption files for audio and video. It
uses a local [Whisper](https://github.com/SYSTRAN/faster-whisper) speech-to-text
model, so there is no cloud account, API key, upload size limit, or per-minute
cost. Links are downloaded with [yt-dlp](https://github.com/yt-dlp/yt-dlp).

It replaces the older IBM Watson workflow (`caption-crunch.sh`,
`vid2watson.rb`, `watson2vtt.rb`), which is still in the git history.

## Setup

Requires Python 3.10+. No separate ffmpeg install is needed.

```bash
python3 -m venv .venv
.venv/bin/pip install -r captioning/requirements.txt
```

The first run downloads the chosen Whisper model (`small.en` is about 500 MB)
into the Hugging Face cache, `~/.cache/huggingface`.

## Usage

```bash
# Local files or whole directories
.venv/bin/python captioning/wsu_caption.py lecture.mp4 interviews/

# Links, given directly or one per line in a text file (# starts a comment)
.venv/bin/python captioning/wsu_caption.py https://youtu.be/XXXX --links links.txt
```

Each input produces these files in the output directory (`./captions` unless
you pass `-o DIR`):

| File | What it is |
| --- | --- |
| `<name>.en.vtt` | The captions. The language code comes from `--language`. |
| `<name>.words.json` | Every word with its start and end time. Keep it to rebuild captions later. |
| `<name>.<ext>` | The downloaded media, for link inputs only. Audio only unless you pass `--video`. |

To preview, put the `.vtt` next to the video with the same base name and open
the video in VLC.

**Rerunning is safe.** Inputs that already have a `.vtt` in the output directory
are skipped, so an interrupted batch can be restarted. Use `--overwrite` to redo
them.

**Changing the caption layout without re-transcribing.** Pass the
`.words.json` files back in with new layout options. This takes seconds:

```bash
.venv/bin/python captioning/wsu_caption.py captions/*.words.json --max-chars 32
```

## Options

| Option | Default | Notes |
| --- | --- | --- |
| `--model` | `small.en` | Accuracy vs speed: `base.en` < `small.en` < `medium.en` < `distil-large-v3` / `large-v3`. Names ending in `.en` are English only. |
| `--language` | `en` | Use `auto` to detect the language, or a code such as `es`. Either needs a multilingual model, e.g. `--model small`. |
| `--max-chars` | 42 | Characters per caption line. |
| `--max-lines` | 2 | Lines per caption. |
| `--max-duration` | 6 | Longest a caption stays on screen, in seconds. |
| `--min-duration` | 1 | Shortest a caption stays on screen. Short captions extend into the silence after them. |
| `--threads` | all cores | CPU threads for the model. |
| `--video` | off | Download full video rather than audio only. |

A new caption also starts after a sentence ends or after a pause longer than
one second. When a caption gets too long, the script splits it at a comma or
other clause break when there is one.

## Performance

It runs on the CPU by default and uses an NVIDIA GPU automatically if one is
available. On a 4-core laptop, `small.en` runs at about real time: an hour of
audio takes roughly an hour. Use `base.en` for quick drafts, and a larger model
for captions that will be published without heavy editing.

Machine captions still need human review before they are used for
accessibility compliance, especially for names, technical terms, and
recordings with more than one speaker.

## Tests

```bash
.venv/bin/pip install pytest
.venv/bin/python -m pytest captioning/tests
```
