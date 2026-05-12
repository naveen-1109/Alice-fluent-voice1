# FluentVoice ML Backend

A Python FastAPI server that performs **real-time speech fluency analysis** using acoustic ML techniques.

## What it detects

| Feature | Description |
|---|---|
| Fluency Score | 0–100% based on acoustic analysis |
| Blocks | Silence gaps ≥ 250ms within speech |
| Prolongations | Sustained voiced sounds (low ZCR + active RMS) |
| Repetitions | Self-similarity in MFCC feature space |
| Speech Rate | Estimated words per minute |
| Insights | Personalized actionable feedback |

## How to run

### Windows (double-click):
```
start_backend.bat
```

### Manual steps:
```bash
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate       # Windows
# source venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Start the server
python main.py
```

The API will be available at: **http://localhost:8000**

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Status check |
| GET | `/health` | Health check |
| POST | `/analyze` | Upload audio file for analysis |

## Test the API (Swagger UI)

Open in browser: **http://localhost:8000/docs**

You can upload a WAV/MP3 file and see the full analysis response.

## Supported audio formats

- `.wav`
- `.mp3`
- `.m4a`
- `.ogg`
- `.flac`
- `.webm`
