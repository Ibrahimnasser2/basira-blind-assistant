"""Builds the BASIRA AI demo video.

Steps (run from the project root):
  python tool/demo_video/make_video.py narration   # neural TTS clips (needs internet)
  python tool/demo_video/make_video.py record      # records the fullscreen demo tour
  python tool/demo_video/make_video.py render      # mixes audio and encodes the final MP4
  python tool/demo_video/make_video.py all

Requires: pip install edge-tts imageio-ffmpeg numpy
The app must be built first:
  flutter build windows --release --dart-define=DEMO_TOUR=true
"""

import asyncio
import os
import subprocess
import sys
import time
import wave
from pathlib import Path

import imageio_ffmpeg
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "tool" / "demo_video" / "out"
AUDIO = OUT / "audio"
RAW_VIDEO = OUT / "raw_capture.mp4"
FINAL_VIDEO = OUT / "BASIRA_AI_Demo.mp4"
APP_EXE = ROOT / "build" / "windows" / "x64" / "runner" / "Release" / "basira_ai.exe"
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()

SR = 44100
FPS = 30

# Mirrors TourTiming in lib/demo_tour/demo_tour.dart.
MARKER, PRE_ROLL = 1.5, 0.5
INTRO, TITLE, HOME, USAGE, OUTRO = 8.0, 3.5, 10.0, 16.5, 9.0
PUSH_AT = 1.4
DEMO_INITIAL, DEMO_HOLD = 1.2, 4.2
HOME_TITLE_START = INTRO
HOME_START = HOME_TITLE_START + TITLE
FEATURE_COUNT = 10


def feature_start(i: int) -> float:
    return HOME_START + HOME + i * (TITLE + USAGE)


OUTRO_START = feature_start(FEATURE_COUNT)
TOTAL = OUTRO_START + OUTRO

NARRATOR = "en-GB-RyanNeural"
APP_VOICE_AR = "ar-EG-SalmaNeural"
APP_VOICE_EN = "en-US-JennyNeural"

# (feature narration, analyzing seconds per result, [(voice, spoken result), ...])
FEATURES = [
    (
        "Feature one: Scene Description. AI describes the surroundings, obstacles, and safe paths.",
        1.8,
        [
            (APP_VOICE_AR, "أمامك رصيف مشاة واسع. على يمينك مقعد خشبي، وعلى يسارك مقهى. المسار آمن."),
            (APP_VOICE_AR, "يسير شخصان أمامك، وتوجد سيارة متوقفة على اليمين."),
        ],
    ),
    (
        "Feature two: Currency Recognition. A model trained on Egyptian banknotes works on the device, even offline.",
        2.4,
        [(APP_VOICE_AR, "تم التعرف على مئة جنيه مصري، بنسبة سبعة وتسعين بالمئة.")],
    ),
    (
        "Feature three: Text Reader. Medicine boxes, signs and documents are read aloud, in Arabic and English.",
        1.8,
        [
            (APP_VOICE_EN, "Paracetamol, 500 milligrams."),
            (APP_VOICE_EN, "Paracetamol, 500 milligrams. Take one tablet every six hours. Ten tablets."),
        ],
    ),
    (
        "Feature four: Object Detection. Everyday objects are detected and named instantly.",
        1.8,
        [
            (APP_VOICE_AR, "تم اكتشاف حاسوب محمول، كوب، زجاجة."),
            (APP_VOICE_AR, "تم اكتشاف كرسي، طاولة، نبات."),
        ],
    ),
    (
        "Feature five: Face Detection. Basira tells the user how many people are in front of them.",
        2.2,
        [(APP_VOICE_AR, "عدد الوجوه: اثنان. شخصان أمامك مباشرة.")],
    ),
    (
        "Feature six: Color Recognition. Helpful when choosing clothes, it announces the dominant color.",
        1.8,
        [(APP_VOICE_AR, "اللون الغالب: أزرق.")],
    ),
    (
        "Feature seven: Barcode Scanner. Scan any product to hear its name.",
        2.4,
        [(APP_VOICE_AR, "تم مسح الباركود. المنتج: شوكولاتة بالبندق للدهن.")],
    ),
    (
        "Feature eight: Walking Assistant. Stairs, barriers and walls trigger an instant voice and vibration warning.",
        1.4,
        [
            (APP_VOICE_AR, "تحذير: يوجد سلالم أمامك. تحرك بحذر."),
            (APP_VOICE_AR, "تحذير: يوجد حاجز على يمينك. يمكنك الاستناد إلى الدرابزين."),
        ],
    ),
    (
        "Feature nine: Time and Location. One tap announces the day, the date, the time, and the current place.",
        -DEMO_INITIAL,
        [(APP_VOICE_AR, "اليوم الخميس، الأول من أكتوبر، الساعة العاشرة والنصف صباحاً. أنت في مدينة نصر، القاهرة.")],
    ),
    (
        "Feature ten: Settings. Choose the language, adjust the speech speed, and securely add the AI key.",
        0.0,
        [],
    ),
]

GENERAL = [
    ("intro", 0.8, "Meet Basira: an AI-powered vision assistant, built for blind and visually impaired people."),
    ("home_title", HOME_TITLE_START + 0.4, "The home screen."),
    ("home", HOME_START + 0.4, "Ten services, with large high-contrast controls, haptic feedback, and hands-free voice commands in Arabic."),
    ("outro", OUTRO_START + 0.9, "Basira. Seeing the world through AI. Thank you for watching."),
]


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, **kw)


def clip_path(name: str) -> Path:
    return AUDIO / f"{name}.mp3"


def load_audio(path: Path) -> np.ndarray:
    raw = run(
        [FFMPEG, "-v", "error", "-i", str(path), "-f", "s16le", "-ac", "1", "-ar", str(SR), "-"],
        capture_output=True,
    ).stdout
    audio = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    voiced = np.flatnonzero(np.abs(audio) > 0.01)
    if len(voiced) == 0:
        return audio
    return audio[: min(len(audio), voiced[-1] + int(0.15 * SR))]


def all_clips():
    """Yields (name, voice, text)."""
    for name, _, text in GENERAL:
        yield name, NARRATOR, text
    for i, (narration, _, results) in enumerate(FEATURES):
        yield f"f{i + 1:02d}_narration", NARRATOR, narration
        for j, (voice, text) in enumerate(results):
            yield f"f{i + 1:02d}_result{j + 1}", voice, text


async def _synthesize():
    import edge_tts

    AUDIO.mkdir(parents=True, exist_ok=True)
    for name, voice, text in all_clips():
        rate = "+0%" if voice == NARRATOR else "+6%"
        await edge_tts.Communicate(text, voice, rate=rate).save(str(clip_path(name)))
        print(f"  {name}: {len(load_audio(clip_path(name))) / SR:.2f}s")


def narration():
    print("Generating voice clips...")
    asyncio.run(_synthesize())


def schedule():
    """Returns [(start_seconds, clip_name)] with results never overlapping speech."""
    events = [(start, name) for name, start, _ in GENERAL]
    for i, (_, analyzing, results) in enumerate(FEATURES):
        s = feature_start(i)
        events.append((s + 0.4, f"f{i + 1:02d}_narration"))
        busy_until = s + 0.4 + len(load_audio(clip_path(f"f{i + 1:02d}_narration"))) / SR
        shown = s + TITLE + PUSH_AT + DEMO_INITIAL + analyzing
        segment_end = s + TITLE + USAGE - 0.3
        for j in range(len(results)):
            start = max(shown + 0.25, busy_until + 0.35)
            name = f"f{i + 1:02d}_result{j + 1}"
            end = start + len(load_audio(clip_path(name))) / SR
            if end > segment_end:
                print(f"  feature {i + 1}: skipping spoken result {j + 1} (would overrun by {end - segment_end:.1f}s)")
                break
            events.append((start, name))
            busy_until = end
            shown += DEMO_HOLD + analyzing
    return sorted(events)


def music_bed(duration: float) -> np.ndarray:
    """Slow ambient pad (Am - F - C - G) with a soft sub bass."""
    n = int(duration * SR)
    t = np.arange(n) / SR
    out = np.zeros((n, 2), dtype=np.float32)
    chords = [
        (110.00, [220.00, 261.63, 329.63, 440.00]),
        (87.31, [174.61, 220.00, 261.63, 349.23]),
        (130.81, [196.00, 261.63, 329.63, 392.00]),
        (98.00, [196.00, 246.94, 293.66, 392.00]),
    ]
    chord_len = 8.0
    fade = 2.5
    k = 0
    start = 0.0
    while start < duration:
        root, notes = chords[k % len(chords)]
        a = int(max(0, start - fade) * SR)
        b = min(n, int((start + chord_len + fade) * SR))
        seg_t = t[a:b]
        local = seg_t - (start - fade)
        env = np.clip(local / fade, 0, 1) * np.clip((chord_len + 2 * fade - local) / fade, 0, 1)
        env = np.sin(env * np.pi / 2) ** 2
        left = np.zeros_like(seg_t)
        right = np.zeros_like(seg_t)
        for idx, f in enumerate(notes):
            detune = 1.0 + 0.0015 * (idx - 1.5)
            wobble = 1 + 0.08 * np.sin(2 * np.pi * (0.07 + idx * 0.013) * seg_t)
            tone = np.sin(2 * np.pi * f * detune * seg_t) + 0.18 * np.sin(2 * np.pi * 2 * f * seg_t)
            pan = 0.35 + 0.3 * (idx / 3)
            left += tone * wobble * (1 - pan)
            right += tone * wobble * pan
        bass = 0.9 * np.sin(2 * np.pi * root * seg_t)
        out[a:b, 0] += (left * 0.11 + bass * 0.22) * env
        out[a:b, 1] += (right * 0.11 + bass * 0.22) * env
        start += chord_len
        k += 1
    return out / np.max(np.abs(out)) * 0.5


def chime(length: float = 2.5) -> np.ndarray:
    t = np.arange(int(length * SR)) / SR
    tone = sum(
        amp * np.sin(2 * np.pi * f * t) * np.exp(-t * decay)
        for f, amp, decay in [(987.77, 0.5, 2.2), (1479.98, 0.3, 3.0), (1975.53, 0.15, 4.0), (493.88, 0.35, 1.6)]
    )
    attack = np.clip(t / 0.005, 0, 1)
    return (tone * attack).astype(np.float32)


def moving_average(x: np.ndarray, width: int) -> np.ndarray:
    c = np.concatenate(([0.0], np.cumsum(x, dtype=np.float64)))
    half = width // 2
    idx = np.arange(len(x))
    lo = np.clip(idx - half, 0, len(x))
    hi = np.clip(idx + half + 1, 0, len(x))
    return ((c[hi] - c[lo]) / (hi - lo)).astype(np.float32)


def build_mix(path: Path):
    n = int(TOTAL * SR)
    voice = np.zeros(n, dtype=np.float32)
    for start, name in schedule():
        clip = load_audio(clip_path(name))
        a = int(start * SR)
        b = min(n, a + len(clip))
        voice[a:b] += clip[: b - a]

    fx = np.zeros(n, dtype=np.float32)
    bell = chime()
    for start in [HOME_TITLE_START] + [feature_start(i) for i in range(FEATURE_COUNT)] + [OUTRO_START, 0.0]:
        a = int((start + 0.05) * SR)
        b = min(n, a + len(bell))
        fx[a:b] += bell[: b - a]

    # Duck the music under speech.
    level = moving_average(np.abs(voice), int(0.25 * SR))
    speaking = moving_average(np.clip(level / 0.02, 0, 1), int(0.6 * SR))
    music = music_bed(TOTAL)
    music_gain = (0.30 - 0.20 * speaking)[:, None]

    mix = music * music_gain + (voice * 0.95)[:, None] + (fx * 0.10)[:, None]
    fade_out = int(2.5 * SR)
    mix[-fade_out:] *= np.linspace(1, 0, fade_out)[:, None]
    mix = mix / max(1.0, np.max(np.abs(mix)) / 0.97)

    with wave.open(str(path), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((mix * 32767).astype(np.int16).tobytes())


def record():
    if not APP_EXE.exists():
        sys.exit(f"App not built: {APP_EXE}")
    OUT.mkdir(parents=True, exist_ok=True)
    seconds = TOTAL + MARKER + PRE_ROLL + 12
    env = dict(os.environ, BASIRA_FULLSCREEN="1")
    print(f"Recording {seconds:.0f}s of the demo tour. Do not touch the mouse or keyboard.")
    ffmpeg = subprocess.Popen(
        [
            FFMPEG, "-y", "-v", "error", "-f", "gdigrab", "-framerate", str(FPS), "-draw_mouse", "0",
            "-i", "desktop", "-t", f"{seconds:.1f}", "-c:v", "libx264", "-preset", "ultrafast",
            "-crf", "12", "-pix_fmt", "yuv420p", str(RAW_VIDEO),
        ]
    )
    time.sleep(1.0)
    app = subprocess.Popen([str(APP_EXE)], env=env, cwd=APP_EXE.parent)
    ffmpeg.wait()
    app.terminate()
    print(f"Saved {RAW_VIDEO}")


def find_tour_start() -> float:
    """Returns the time the intro starts: end of the magenta marker plus the pre-roll."""
    w, h = 16, 9
    raw = run(
        [FFMPEG, "-v", "error", "-i", str(RAW_VIDEO), "-vf", f"fps={FPS},scale={w}:{h}",
         "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
        capture_output=True,
    ).stdout
    frames = np.frombuffer(raw, dtype=np.uint8).reshape(-1, h, w, 3).astype(int)
    mean = frames.mean(axis=(1, 2))
    magenta = (mean[:, 0] > 200) & (mean[:, 1] < 70) & (mean[:, 2] > 200)
    idx = np.flatnonzero(magenta)
    if len(idx) == 0:
        sys.exit("Marker not found in the recording.")
    return (idx[-1] + 1) / FPS + PRE_ROLL


def render():
    start = find_tour_start()
    print(f"Tour starts at {start:.2f}s in the capture.")
    mix = OUT / "mix.wav"
    build_mix(mix)
    run(
        [
            FFMPEG, "-y", "-v", "error", "-ss", f"{start:.3f}", "-i", str(RAW_VIDEO), "-i", str(mix),
            "-t", f"{TOTAL:.3f}", "-map", "0:v", "-map", "1:a",
            "-vf", f"scale=1920:1080:flags=lanczos,fade=t=in:st=0:d=0.8,fade=t=out:st={TOTAL - 1.5:.2f}:d=1.5",
            "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p", "-r", str(FPS),
            "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(FINAL_VIDEO),
        ]
    )
    print(f"Done: {FINAL_VIDEO}  ({int(TOTAL // 60)}:{TOTAL % 60:04.1f})")


if __name__ == "__main__":
    step = sys.argv[1] if len(sys.argv) > 1 else "all"
    if step in ("narration", "all"):
        narration()
    if step in ("record", "all"):
        record()
    if step in ("render", "all"):
        render()
