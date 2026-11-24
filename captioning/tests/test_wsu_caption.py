import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from wsu_caption import (  # noqa: E402
    CueRules,
    Word,
    build_cues,
    gather_inputs,
    glob_escape,
    load_words,
    parse_args,
    render_vtt,
    save_words,
    stem_of,
    vtt_timestamp,
    wrap_lines,
)


def timed(text: str, start: float = 0.0, step: float = 0.3) -> list[Word]:
    """Words spaced evenly, Whisper-style with leading spaces."""
    return [
        Word(f" {w}", start + i * step, start + i * step + step * 0.8)
        for i, w in enumerate(text.split())
    ]


def test_timestamp_format():
    assert vtt_timestamp(0) == "00:00:00.000"
    assert vtt_timestamp(3725.4567) == "01:02:05.457"
    assert vtt_timestamp(-1) == "00:00:00.000"


def test_short_speech_is_one_cue_and_strips_spaces():
    cues = build_cues(timed("hello there everyone"))
    assert [c.text for c in cues] == ["hello there everyone"]


def test_breaks_after_sentence():
    cues = build_cues(timed("This is the first sentence. And here is a second one."))
    assert [c.text for c in cues] == ["This is the first sentence.", "And here is a second one."]


def test_tiny_sentence_is_not_split_off():
    cues = build_cues(timed("Yes. That is right."))
    assert len(cues) == 1


def test_long_pause_starts_new_cue():
    words = timed("before the pause") + timed("after it", start=10)
    assert [c.text for c in build_cues(words)] == ["before the pause", "after it"]


def test_respects_char_and_line_limits():
    rules = CueRules(max_chars_per_line=20, max_lines=2, max_duration=100)
    text = " ".join(["word"] * 40)
    for cue in build_cues(timed(text), rules):
        lines = cue.text.split("\n")
        assert len(lines) <= 2
        assert all(len(line) <= 20 for line in lines)


def test_respects_max_duration():
    rules = CueRules(max_duration=3, max_chars_per_line=200)
    cues = build_cues(timed(" ".join(["w"] * 50)), rules)
    assert len(cues) > 1
    assert all(c.end - c.start <= 3 + 1e-9 for c in cues)


def test_prefers_clause_boundary_when_full():
    rules = CueRules(max_chars_per_line=30, max_lines=1, max_duration=100)
    text = "we went to the store, and then we bought apples"
    cues = build_cues(timed(text), rules)
    assert cues[0].text == "we went to the store,"


def test_short_cue_extended_but_not_into_next():
    words = [Word("Hi.", 0.0, 0.2), Word("Next", 0.6, 0.9)]
    rules = CueRules(min_duration=1.0, max_pause=0.1)
    first, second = build_cues(words, rules)
    assert first.end == pytest.approx(0.5)  # next start minus min_gap
    assert second.end == pytest.approx(1.6)  # nothing follows, full min_duration


def test_overlapping_whisper_timestamps_are_clamped():
    words = [Word("One.", 0.0, 2.0), Word("Two.", 1.5, 3.0)]
    first, second = build_cues(words, CueRules(min_duration=0.5))
    assert first.end <= second.start
    assert first.end > first.start


def test_wrap_balances_lines():
    rules = CueRules(max_chars_per_line=42, max_lines=2)
    text = "the quick brown fox jumps over the lazy dog and keeps running"
    a, b = wrap_lines(text, rules).split("\n")
    assert abs(len(a) - len(b)) <= 8


def test_render_vtt():
    out = render_vtt(build_cues(timed("hello world")))
    assert out.startswith("WEBVTT\n\n00:00:00.000 --> ")
    assert out.endswith("hello world\n")


def test_words_roundtrip(tmp_path):
    path = tmp_path / "talk.words.json"
    words = timed("a b c")
    save_words(path, words, "en", "talk.mp4")
    assert load_words(path) == (words, "en")
    assert stem_of(path) == "talk"
    assert stem_of(tmp_path / "talk.v2.mp4") == "talk.v2"


def test_gather_inputs(tmp_path):
    (tmp_path / "a.mp4").touch()
    (tmp_path / "notes.txt").touch()
    links = tmp_path / "links.txt"
    links.write_text("# comment\nhttps://example.org/v\n\n")
    urls, files = gather_inputs([str(tmp_path)], links)
    assert urls == ["https://example.org/v"]
    assert files == [tmp_path / "a.mp4"]
    with pytest.raises(SystemExit):
        gather_inputs(["missing.mp4"], None)


def test_glob_escape_handles_ytdlp_ids(tmp_path):
    stem = "Lecture [abc123]"
    (tmp_path / f"{stem}.en.vtt").touch()
    assert list(tmp_path.glob(f"{glob_escape(stem)}.*.vtt"))


def test_english_model_rejects_other_language():
    with pytest.raises(SystemExit):
        parse_args(["x.mp4", "--language", "es"])
    assert parse_args(["x.mp4", "--model", "small", "--language", "auto"]).language == "auto"
