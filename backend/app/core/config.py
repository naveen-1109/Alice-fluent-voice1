from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "FluentVoice AI API"
    VERSION: str = "2.1.0"
    API_V1_STR: str = "/api/v1"
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"]
    
    # Supabase (Optional if backend saves directly)
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    
    # Whisper
    WHISPER_MODEL: str = "base"
    
    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
