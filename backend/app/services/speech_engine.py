import io
import os
import tempfile
import numpy as np
import librosa
import soundfile as sf
import math
import logging
from typing import List, Tuple, Optional, Dict, Any
from app.models.analysis import AnalysisResponse, DisfluencyEvent, EventBreakdown
from app.core.config import settings

logger = logging.getLogger(__name__)

class SpeechAnalysisService:
    def __init__(self):
        self._whisper_model = None
        self.SR = 22050
        self.HOP = 512
        self.SILENCE_DB = -38
        self.BLOCK_MIN_S = 0.25
        self.PROLONG_ZCR = 0.04
        self.PROLONG_S = 0.30
        self.INTERJECTION_WORDS = {
            "um", "uh", "er", "ah", "eh", "hmm", "hm", "mm",
            "like", "you know", "i mean", "kind of", "sort of",
            "basically", "actually", "literally", "right", "okay", "so",
        }

    def _get_whisper(self):
        if self._whisper_model is None:
            try:
                import whisper
                logger.info(f"Loading Whisper model: {settings.WHISPER_MODEL}")
                self._whisper_model = whisper.load_model(settings.WHISPER_MODEL)
            except Exception as e:
                logger.error(f"Whisper load failed: {e}")
                self._whisper_model = "unavailable"
        return None if self._whisper_model == "unavailable" else self._whisper_model

    def analyze_audio(self, audio_bytes: bytes) -> AnalysisResponse:
        logger.info("Starting audio analysis")
        y, sr = self._load_audio(audio_bytes)
        duration = librosa.get_duration(y=y, sr=sr)

        # Acoustic features
        rms = librosa.feature.rms(y=y, hop_length=self.HOP)[0]
        zcr = librosa.feature.zero_crossing_rate(y, hop_length=self.HOP)[0]
        mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13, hop_length=self.HOP)

        silence_mask = self._silence_mask(rms)
        blocks = self._find_blocks(silence_mask, sr)
        prolongations = self._find_prolongations(zcr, rms, sr)

        transcript = None
        word_segments = []
        whisper_used = False
        wpm = self._estimate_wpm(silence_mask, duration)

        whisper = self._get_whisper()
        if whisper:
            try:
                transcript, word_segments = self._transcribe(whisper, audio_bytes)
                wpm = self._wpm_from_transcript(transcript, duration)
                whisper_used = True
            except Exception as e:
                logger.error(f"Transcription error: {e}")

        # Extract disfluency events
        repetitions = []
        interjections_list = []
        if whisper_used:
            repetitions = self._find_repetitions(word_segments)
            interjections_list = self._find_interjections(word_segments)
        else:
            repetitions = self._find_acoustic_repetitions(mfccs, sr)

        # Build timeline
        event_timeline = self._build_timeline(blocks, prolongations, repetitions, interjections_list)
        
        # Metrics
        total_events = len(event_timeline)
        breakdown = self._build_breakdown(event_timeline)
        epm = (total_events / (duration / 60)) if duration > 0 else 0.0
        
        block_durs = [b[1] for b in blocks] if blocks else [0.0]
        avg_gap = round(sum(block_durs) / len(block_durs), 2) if block_durs else 0.0
        longest_gap = round(max(block_durs), 2) if block_durs else 0.0

        score = self._calculate_fluency_score(duration, blocks, prolongations, total_events)
        severity = "Severe" if score < 60 else ("Moderate" if score < 78 else "Mild")
        
        insights = self._generate_insights(score, breakdown, wpm, transcript)

        return AnalysisResponse(
            fluency_score=score,
            severity=severity,
            duration_seconds=round(duration, 2),
            speech_rate_wpm=wpm,
            events_per_min=round(epm, 1),
            total_events=total_events,
            average_gap=avg_gap,
            longest_gap=longest_gap,
            event_breakdown=breakdown,
            event_timeline=event_timeline[:40],
            insights=insights,
            transcript=transcript,
            whisper_used=whisper_used
        )

    def _load_audio(self, audio_bytes: bytes):
        buf = io.BytesIO(audio_bytes)
        try:
            y, sr = librosa.load(buf, sr=self.SR, mono=True)
        except Exception:
            buf.seek(0)
            data, sr = sf.read(buf)
            if data.ndim > 1: data = data.mean(axis=1)
            y = librosa.resample(data.astype(np.float32), orig_sr=sr, target_sr=self.SR)
            sr = self.SR
        return y, sr

    def _silence_mask(self, rms):
        db = librosa.amplitude_to_db(rms + 1e-9, ref=np.max)
        return db < self.SILENCE_DB

    def _find_blocks(self, silence_mask, sr):
        fd = self.HOP / sr
        min_f = int(self.BLOCK_MIN_S / fd)
        out, in_s, start = [], False, 0
        for i, s in enumerate(silence_mask):
            if s and not in_s: in_s, start = True, i
            elif not s and in_s:
                in_s = False
                if (i - start) >= min_f: out.append((start * fd, (i - start) * fd))
        return out

    def _find_prolongations(self, zcr, rms, sr):
        fd = self.HOP / sr
        min_f = int(self.PROLONG_S / fd)
        rms_n = rms / (rms.max() + 1e-9)
        mask = (zcr < self.PROLONG_ZCR) & (rms_n > 0.12)
        out, in_p, start = [], False, 0
        for i, a in enumerate(mask):
            if a and not in_p: in_p, start = True, i
            elif not a and in_p:
                in_p = False
                if (i - start) >= min_f: out.append((start * fd, (i - start) * fd))
        return out

    def _transcribe(self, model, audio_bytes: bytes):
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            f.write(audio_bytes)
            tmp_path = f.name
        try:
            result = model.transcribe(tmp_path, word_timestamps=True, language="en")
        finally:
            if os.path.exists(tmp_path): os.unlink(tmp_path)
        
        transcript = result.get("text", "").strip()
        segments = result.get("segments", [])
        words = []
        for seg in segments:
            for w in seg.get("words", []):
                words.append((w.get("start", 0.0), w.get("word", "").strip()))
        return transcript, words

    def _wpm_from_transcript(self, transcript, duration):
        count = len(transcript.split())
        mins = duration / 60
        return max(30, int(count / mins)) if mins > 0 else 100

    def _find_repetitions(self, word_segs):
        out = []
        words = [(t, w.lower().strip(".,!?, ")) for t, w in word_segs if w.strip()]
        i = 0
        while i < len(words) - 1:
            w1, w2 = words[i][1], words[i+1][1]
            if w1 == w2 or (len(w1) >= 3 and len(w2) >= 3 and w1[:3] == w2[:3]):
                out.append((words[i][0], "repetition", w1))
                i += 2
            else: i += 1
        return out

    def _find_interjections(self, word_segs):
        out = []
        for ts, word in word_segs:
            clean = word.lower().strip(".,!?, ")
            if clean in self.INTERJECTION_WORDS:
                out.append((ts, "interjection", clean))
        return out

    def _find_acoustic_repetitions(self, mfccs, sr):
        # Fallback acoustic method
        return []

    def _estimate_wpm(self, silence_mask, duration):
        ratio = 1.0 - silence_mask.mean()
        return max(60, int(ratio * 150))

    def _build_timeline(self, blocks, prolongs, reps, inters):
        timeline = []
        for b in blocks: timeline.append(DisfluencyEvent(time=self._fmt(b[0]), type="block"))
        for p in prolongs: timeline.append(DisfluencyEvent(time=self._fmt(p[0]), type="prolongation"))
        for r in reps: timeline.append(DisfluencyEvent(time=self._fmt(r[0]), type="repetition", word=r[2]))
        for i in inters: timeline.append(DisfluencyEvent(time=self._fmt(i[0]), type="interjection", word=i[2]))
        timeline.sort(key=lambda e: self._parse_time(e.time))
        return timeline

    def _build_breakdown(self, timeline):
        counts = {"block": 0, "prolongation": 0, "repetition": 0, "interjection": 0}
        for e in timeline:
            if e.type in counts: counts[e.type] += 1
        return EventBreakdown(
            interjections=counts["interjection"],
            blocks=counts["block"],
            prolongations=counts["prolongation"],
            repetitions=counts["repetition"]
        )

    def _calculate_fluency_score(self, duration, blocks, prolongs, total):
        score = 100
        rate = total / max(duration / 60, 0.1)
        score -= min(40, rate * 5)
        score -= len([b for b in blocks if b[1] > 0.5]) * 3
        prolong_s = sum(p[1] for p in prolongs)
        score -= min(20, (prolong_s / max(duration, 1)) * 100)
        return max(0, min(100, int(score)))

    def _generate_insights(self, score, breakdown, wpm, transcript):
        ins = []
        if score >= 85: ins.append("🎉 Excellent session! Your fluency is in the top range.")
        elif score >= 70: ins.append("👍 Good session. Keep practicing to reach the top.")
        else: ins.append("💪 Every practice session builds resilience. Stay focused!")
        
        if breakdown.blocks > 0: ins.append(f"🔴 {breakdown.blocks} blocks detected. Try diaphragmatic breathing.")
        if breakdown.prolongations > 0: ins.append(f"🟡 {breakdown.prolongations} prolongations found. Focus on easy-onset.")
        if wpm > 140: ins.append("🚀 Rate was fast. Slowing to 100-120 WPM can help.")
        return ins

    def _fmt(self, s):
        m, s = divmod(int(s), 60)
        return f"{m}:{s:02d}"

    def _parse_time(self, t):
        parts = t.split(":")
        return int(parts[0]) * 60 + int(parts[1]) if len(parts) == 2 else 0.0

# Singleton instance
speech_service = SpeechAnalysisService()
