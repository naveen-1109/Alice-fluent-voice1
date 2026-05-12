from pydantic import BaseModel, Field
from typing import List, Optional, Dict

class DisfluencyEvent(BaseModel):
    time: str
    type: str
    word: Optional[str] = None
    confidence: float = Field(default=0.8, ge=0.0, le=1.0)

class EventBreakdown(BaseModel):
    interjections: int = 0
    blocks: int = 0
    prolongations: int = 0
    repetitions: int = 0

class AnalysisResponse(BaseModel):
    fluency_score: int
    severity: str
    duration_seconds: float
    speech_rate_wpm: int
    events_per_min: float
    total_events: int
    average_gap: float
    longest_gap: float
    event_breakdown: EventBreakdown
    event_timeline: List[DisfluencyEvent]
    insights: List[str]
    transcript: Optional[str] = None
    from_ml: bool = True
    whisper_used: bool = False

class AnalysisRequest(BaseModel):
    # Meta data that might be needed if backend persists data
    patient_id: Optional[str] = None
    goal: Optional[str] = None
    notes: Optional[str] = None
