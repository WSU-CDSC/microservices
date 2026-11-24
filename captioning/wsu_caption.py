#!/usr/bin/env python3
"""Generate WebVTT captions for audio/video with a local Whisper model.

Replaces the old caption-crunch.sh / vid2watson.rb / watson2vtt.rb workflow.

    python wsu_caption.py lecture.mp4 https://youtu.be/... --links links.txt

Each input becomes ``<out>/<name>.<lang>.vtt`` plus ``<out>/<name>.words.json``
(word-level timestamps). Passing a ``.words.json`` back in rebuilds the VTT with
the current cue settings without re-running the model.
"""

from __future__ import annotations

import argparse
import json
import logging
import math
import sys
import textwrap
from dataclasses import asdict, dataclass
from pathlib import Path

log = logging.getLogger("wsu_caption")

MEDIA_EXTS = {
    ".mp4", ".mkv", ".mov", ".avi", ".webm", ".m4v", ".mpg", ".mpeg", ".wmv",
    ".mp3", ".m4a", ".wav", ".flac", ".ogg", ".opus", ".aac", ".wma",
}
WORDS_SUFFIX = ".words.json"
CLAUSE_END = ",;:"
SENTENCE_END = ".?!"


@dataclass(frozen=True)
class Word:
    text: str
    start: float
    end: float


@dataclass
class Cue:
    start: float
    end: float
    text: str


@dataclass(frozen=True)
class CueRules:
    max_chars_per_line: int = 42
    max_lines: int = 2
    max_duration: float = 6.0
    min_duration: float = 1.0
    max_pause: float = 1.0  # silence longer than this always starts a new cue
    min_gap: float = 0.1  # space left before the next cue when extending one


# --------------------------------------------------------------------------
# Cue building (pure functions, no model needed)
# --------------------------------------------------------------------------


def _join(words: list[Word]) -> str:
    return " ".join(w.text for w in words)


def _clause_split(words: list[Word]) -> int:
    """Index to split an over-full cue at: after the last clause punctuation in
    its second half, otherwise after the last word."""
    for i in range(len(words) - 1, len(words) // 2 - 1, -1):
        if words[i].text[-1] in CLAUSE_END + SENTENCE_END:
            return i + 1
    return len(words)


def build_cues(words: list[Word], rules: CueRules = CueRules()) -> list[Cue]:
    """Group timed words into caption cues that respect ``rules``."""
    max_chars = rules.max_chars_per_line * rules.max_lines
    groups: list[list[Word]] = []
    current: list[Word] = []

    for raw in words:
        text = raw.text.strip()
        if not text:
            continue
        word = Word(text, raw.start, raw.end)
        if current:
            prev = current[-1]
            pause = word.start - prev.end > rules.max_pause
            sentence_done = (
                prev.text[-1] in SENTENCE_END
                and prev.end - current[0].start >= rules.min_duration
            )
            too_long = (
                word.end - current[0].start > rules.max_duration
                or len(_join(current)) + 1 + len(word.text) > max_chars
            )
            if pause or sentence_done:
                groups.append(current)
                current = []
            elif too_long:
                cut = _clause_split(current)
                groups.append(current[:cut])
                current = current[cut:]
        current.append(word)
    if current:
        groups.append(current)

    cues = [
        Cue(g[0].start, g[-1].end, wrap_lines(_join(g), rules)) for g in groups
    ]
    _fix_timing(cues, rules)
    return cues


def _fix_timing(cues: list[Cue], rules: CueRules) -> None:
    """Remove overlaps and stretch short cues into the following silence."""
    for i, cue in enumerate(cues):
        limit = cues[i + 1].start - rules.min_gap if i + 1 < len(cues) else math.inf
        if cue.end - cue.start < rules.min_duration:
            cue.end = cue.start + rules.min_duration
        cue.end = min(cue.end, limit)
        if cue.end <= cue.start:  # next cue starts almost immediately
            cue.end = cue.start + 0.01


def wrap_lines(text: str, rules: CueRules) -> str:
    """Break cue text into at most ``max_lines`` lines of similar length."""
    limit = rules.max_chars_per_line
    if len(text) <= limit or rules.max_lines == 1:
        return text
    needed = min(rules.max_lines, math.ceil(len(text) / limit))
    for width in range(math.ceil(len(text) / needed), limit + 1):
        lines = textwrap.wrap(text, width, break_long_words=False)
        if len(lines) <= rules.max_lines:
            return "\n".join(lines)
    return "\n".join(textwrap.wrap(text, limit, break_long_words=False))


def vtt_timestamp(seconds: float) -> str:
    ms = round(max(seconds, 0) * 1000)
    h, ms = divmod(ms, 3_600_000)
    m, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d}.{ms:03d}"


def render_vtt(cues: list[Cue]) -> str:
    blocks = ["WEBVTT"]
    for cue in cues:
        blocks.append(
            f"{vtt_timestamp(cue.start)} --> {vtt_timestamp(cue.end)}\n{cue.text}"
        )
    return "\n\n".join(blocks) + "\n"


# --------------------------------------------------------------------------
# Words JSON (lets cue settings be re-applied without re-transcribing)
# --------------------------------------------------------------------------


def save_words(path: Path, words: list[Word], language: str, source: str) -> None:
    payload = {"source": source, "language": language, "words": [asdict(w) for w in words]}
    path.write_text(json.dumps(payload, indent=1), encoding="utf-8")


def load_words(path: Path) -> tuple[list[Word], str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    return [Word(**w) for w in data["words"]], data["language"]


# --------------------------------------------------------------------------
# Download and transcription
# --------------------------------------------------------------------------


def download(urls: list[str], dest: Path, video: bool) -> tuple[list[Path], list[str]]:
    """Fetch each URL (or playlist) with yt-dlp. Returns (files, failed_urls)."""
    from yt_dlp import YoutubeDL
    from yt_dlp.utils import DownloadError

    opts = {
        "format": "bv*+ba/b" if video else "ba/b",
        "outtmpl": str(dest / "%(title).120B [%(id)s].%(ext)s"),
        "quiet": True,
        "no_warnings": True,
        "noprogress": True,
    }
    files: list[Path] = []
    failed: list[str] = []
    with YoutubeDL(opts) as ydl:
        for url in urls:
            log.info("Downloading %s", url)
            try:
                info = ydl.extract_info(url, download=True)
            except DownloadError as exc:
                log.error("Download failed for %s: %s", url, exc)
                failed.append(url)
                continue
            for entry in info.get("entries") or [info]:
                if not entry:
                    continue
                done = entry.get("requested_downloads") or [{}]
                files.append(Path(done[0].get("filepath") or ydl.prepare_filename(entry)))
    return files, failed


def load_model(name: str, threads: int):
    from faster_whisper import WhisperModel

    log.info("Loading Whisper model %s", name)
    return WhisperModel(name, device="auto", compute_type="auto", cpu_threads=threads)


def transcribe(model, media: Path, language: str | None) -> tuple[list[Word], str]:
    segments, info = model.transcribe(
        str(media),
        language=language,
        word_timestamps=True,
        vad_filter=True,
        condition_on_previous_text=False,  # avoids runaway repetition on long files
    )
    words = [
        Word(w.word, w.start, w.end)
        for seg in segments  # generator: decoding happens here
        for w in (seg.words or [])
    ]
    return words, info.language


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def stem_of(path: Path) -> str:
    name = path.name
    return name[: -len(WORDS_SUFFIX)] if name.endswith(WORDS_SUFFIX) else path.stem


def gather_inputs(items: list[str], links_file: Path | None) -> tuple[list[str], list[Path]]:
    """Split inputs into URLs and local files (directories are scanned)."""
    if links_file:
        lines = links_file.read_text(encoding="utf-8").splitlines()
        items = items + [ln.strip() for ln in lines if ln.strip() and not ln.lstrip().startswith("#")]
    urls: list[str] = []
    files: list[Path] = []
    for item in items:
        if item.startswith(("http://", "https://")):
            urls.append(item)
            continue
        path = Path(item)
        if path.is_dir():
            files.extend(
                sorted(p for p in path.rglob("*") if p.suffix.lower() in MEDIA_EXTS)
            )
        elif path.is_file():
            files.append(path)
        else:
            raise SystemExit(f"Not a URL, file, or directory: {item}")
    return urls, files


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Generate WebVTT captions with a local Whisper model.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument("inputs", nargs="*", help="media files, directories, URLs, or .words.json files")
    p.add_argument("--links", type=Path, help="text file with one URL per line (# comments allowed)")
    p.add_argument("-o", "--out", type=Path, default=Path("captions"), help="output directory")
    p.add_argument("--model", default="small.en", help="Whisper model name or local path")
    p.add_argument("--language", default="en", help="spoken language code, or 'auto' to detect")
    p.add_argument("--threads", type=int, default=0, help="CPU threads for the model (0 = all)")
    p.add_argument("--video", action="store_true", help="download full video, not just audio")
    p.add_argument("--overwrite", action="store_true", help="redo inputs that already have captions")
    g = p.add_argument_group("cue layout")
    g.add_argument("--max-chars", type=int, default=CueRules.max_chars_per_line, help="characters per line")
    g.add_argument("--max-lines", type=int, default=CueRules.max_lines, help="lines per cue")
    g.add_argument("--max-duration", type=float, default=CueRules.max_duration, help="seconds per cue")
    g.add_argument("--min-duration", type=float, default=CueRules.min_duration, help="seconds per cue")
    p.add_argument("-v", "--verbose", action="store_true")
    args = p.parse_args(argv)
    if not args.inputs and not args.links:
        p.error("give at least one input or --links")
    if args.model.endswith(".en") and args.language != "en":
        p.error(f"{args.model} is English-only; use a multilingual model for --language {args.language}")
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        datefmt="%H:%M:%S",
    )
    rules = CueRules(
        max_chars_per_line=args.max_chars,
        max_lines=args.max_lines,
        max_duration=args.max_duration,
        min_duration=args.min_duration,
    )
    language = None if args.language == "auto" else args.language
    out: Path = args.out
    out.mkdir(parents=True, exist_ok=True)

    urls, files = gather_inputs(args.inputs, args.links)
    failed: list[str] = []
    if urls:
        downloaded, failed = download(urls, out, args.video)
        files += downloaded

    model = None
    done = skipped = 0
    for path in files:
        stem = stem_of(path)
        try:
            if path.name.endswith(WORDS_SUFFIX):
                words, lang = load_words(path)
            else:
                existing = list(out.glob(f"{glob_escape(stem)}.*.vtt"))
                if existing and not args.overwrite:
                    log.info("Skipping %s (already captioned: %s)", path.name, existing[0].name)
                    skipped += 1
                    continue
                if model is None:
                    model = load_model(args.model, args.threads)
                log.info("Transcribing %s", path.name)
                words, lang = transcribe(model, path, language)
                save_words(out / f"{stem}{WORDS_SUFFIX}", words, lang, str(path))
            if not words:
                log.warning("No speech found in %s; no captions written", path.name)
                continue
            vtt = out / f"{stem}.{lang}.vtt"
            vtt.write_text(render_vtt(build_cues(words, rules)), encoding="utf-8")
            log.info("Wrote %s", vtt)
            done += 1
        except Exception:
            log.exception("Failed on %s", path)
            failed.append(str(path))

    log.info("Captioned %d, skipped %d, failed %d", done, skipped, len(failed))
    for item in failed:
        log.info("  failed: %s", item)
    return 1 if failed else 0


def glob_escape(text: str) -> str:
    """Escape glob metacharacters (yt-dlp names contain [video-id])."""
    return "".join(f"[{c}]" if c in "*?[]" else c for c in text)


if __name__ == "__main__":
    sys.exit(main())
