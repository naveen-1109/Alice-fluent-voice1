from fastapi import APIRouter, File, UploadFile, HTTPException, BackgroundTasks
from app.models.analysis import AnalysisResponse
from app.services.speech_engine import speech_service
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/analyze", response_model=AnalysisResponse)
async def analyze_audio(
    file: UploadFile = File(...)
):
    """
    Analyze uploaded audio for speech disfluencies.
    """
    logger.info(f"Received analysis request for file: {file.filename}")
    
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")
        
    try:
        audio_bytes = await file.read()
        if len(audio_bytes) < 100:
            raise HTTPException(status_code=400, detail="Audio file too small or empty")
            
        result = speech_service.analyze_audio(audio_bytes)
        return result
    except Exception as e:
        logger.error(f"Analysis failed: {e}")
        raise HTTPException(status_code=500, detail=f"Internal analysis error: {str(e)}")
