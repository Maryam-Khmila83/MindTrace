from fastapi import FastAPI
from sqlalchemy.orm import Session
from db import SessionLocal
from models_db import AnalysisResult, Letter

from fastapi import Depends
import torch
from transformers import DistilBertTokenizerFast

from model_definition import DistilBertForMultiLabelWeighted
from emotion_logic import analyze_text

from distress_logic import predict_distress

from pydantic import BaseModel, field_validator

# ---------------------------
# Load model ONCE
# ---------------------------
MODEL_PATH = "goemotion_training_artifacts/model"

tokenizer = DistilBertTokenizerFast.from_pretrained(MODEL_PATH)
model = DistilBertForMultiLabelWeighted.from_pretrained(
    MODEL_PATH,
    pos_weights=torch.ones(26)
)
model.eval()

emotion_cols = [
    'anger','annoyance','nervousness','sadness','disappointment','fear',
    'admiration','amusement','approval','caring','curiosity','desire',
    'excitement','gratitude','joy','love','optimism','pride','relief',
    'neutral'
]

thresholds = {
    "anger": 0.30, "annoyance": 0.25, "nervousness": 0.30,
    "sadness": 0.30, "disappointment": 0.25, "fear": 0.30,
    "admiration": 0.35, "amusement": 0.40, "approval": 0.25,
    "caring": 0.30, "curiosity": 0.30, "desire": 0.30,
    "excitement": 0.30, "gratitude": 0.50, "joy": 0.35,
    "love": 0.40, "optimism": 0.30, "pride": 0.30,
    "relief": 0.30, "neutral": 0.20
}

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def decide_final_status(tone, burnout, distress_level):
    # --- improved fusion guardrails ---

    if tone in ["positive", "neutral"] and burnout < 25 and distress_level == "no_distress":
         return "healthy"

    elif distress_level == "high_distress" and burnout >= 30:
         return "burnout_risk"

    elif burnout >= 65:
         return "burnout_risk"
    
    # 🟠 distress but not full burnout
    elif distress_level == "high_distress" and burnout < 30:
        return "mild_stress"

    elif burnout >= 35:
         return "mild_stress"

    else:
         return "temporary_negative_mood"


def fused_risk_level(burnout, distress_level):
    if burnout >= 65:
        return "high"
    elif burnout >= 35 or distress_level == "moderate_distress":
        return "medium"
    else:
        return "low"

def adjust_with_history(current_burnout, distress_level, db: Session):
    """
    Level 4: temporal smoothing using recent history
    """

    recent = (
        db.query(AnalysisResult)
        .order_by(AnalysisResult.created_at.desc())
        .limit(5)
        .all()
    )

    if not recent:
        return current_burnout, distress_level

    # --- compute average burnout ---
    avg_burnout = sum(r.burnout for r in recent) / len(recent)

    # --- count high distress ---
    high_distress_count = sum(
        1 for r in recent if r.distress_level == "high_distress"
    )

    adjusted_burnout = current_burnout

    # 🔹 smoothing toward recent average
    adjusted_burnout = int((0.7 * current_burnout) + (0.3 * avg_burnout))
    # 🔹 safety clamp
    adjusted_burnout = max(0, min(100, adjusted_burnout))

    # 🔹 persistence escalation
    if high_distress_count >= 3 and adjusted_burnout >= 35:
        distress_level = "high_distress"

    return adjusted_burnout, distress_level


# ---------------------------
# FastAPI app
# ---------------------------
app = FastAPI(title="Emotion & Burnout API")


class TextRequest(BaseModel):
    text: str
    team: str

class LetterRequest(BaseModel):
    content: str
    is_shared: bool = False
    team: str = None

    @field_validator("content")
    def content_not_empty(cls, v):
        if not v.strip():
            raise ValueError("Content cannot be empty")
        return v    

@app.post("/analyze")
def analyze(request: TextRequest, db: Session = Depends(get_db)):

    #  Emotion model
    emotion_result = analyze_text(
        request.text,
        model,
        tokenizer,
        emotion_cols,
        thresholds
    )

    #  Distress model
    distress_result = predict_distress(request.text)

    #  Level 4 temporal adjustment 
    adjusted_burnout, adjusted_distress = adjust_with_history(
        emotion_result["burnout"],
        distress_result["distress_level"],
        db
    )

    emotion_result["burnout"] = adjusted_burnout
    distress_result["distress_level"] = adjusted_distress

    # FUSED RISK
    fused_risk = fused_risk_level(
        emotion_result["burnout"],
        distress_result["distress_level"]
    ) 

    # overwrite emotion risk (important)
    emotion_result["risk"] = fused_risk

    #  Final decision
    final_status = decide_final_status(
        emotion_result["tone"],
        emotion_result["burnout"],
        distress_result["distress_level"]
)

    #  Save to DB
    record = AnalysisResult(
        text=request.text,
        tone=emotion_result["tone"],
        burnout=emotion_result["burnout"],
        risk=fused_risk,  # ✅ FIXED
        distress_level=distress_result["distress_level"],
        final_status=final_status,
        team=request.team
    )

    db.add(record)
    db.commit()
    db.refresh(record)

    # API response
    return {
        "text": request.text,
        "emotions": emotion_result,
        "distress": distress_result,
        "final_status": final_status
    }



@app.get("/history")
def get_history(team: str = None, limit: int = 50, db: Session = Depends(get_db)):

    # Start with base query
    query = db.query(AnalysisResult)

    # Filter by team if provided
    if team and team.strip():
        query = query.filter(AnalysisResult.team == team)

    # Order by created_at descending and limit results
    records = query.order_by(AnalysisResult.created_at.desc()).limit(limit).all()

    return [
        {
            "id": r.id,
            "text": r.text,
            "tone": r.tone,
            "burnout": r.burnout,
            "risk": r.risk,
            "team": r.team,
            "distress_level": r.distress_level,
            "final_status": r.final_status, 
            "created_at": r.created_at
        }
        for r in records
    ]


@app.post("/letters")
def create_letter(request: LetterRequest, db: Session = Depends(get_db)):

    #  Create DB object
    letter = Letter(
        content=request.content,
        is_shared=request.is_shared,
        team=request.team
    )

    #  Save to DB
    db.add(letter)
    db.commit()
    db.refresh(letter)

    #  Return response
    return {
        "message": "Letter saved successfully",
        "letter": {
            "id": letter.id,
            "content": letter.content,
            "is_shared": letter.is_shared,
            "team": letter.team,
            "created_at": letter.created_at
        }
    }


@app.get("/letters/shared")
def get_shared_letters(db: Session = Depends(get_db)):
    letters = (
        db.query(Letter)
        .filter(Letter.is_shared == True)
        .order_by(Letter.created_at.desc())
        .all()
    )

    return [
        {
            "id": l.id,
            "content": l.content,
            "team": l.team,
            "created_at": l.created_at
        }
        for l in letters
    ]

@app.get("/letters/user")
def get_user_letters(team: str = None, db: Session = Depends(get_db)):
    # Get all letters (for now - all letters are visible to the user)
    # In a real app with authentication, you'd filter by user_id
    query = db.query(Letter)

    # Filter by team if provided
    if team and team.strip():
        query = query.filter(Letter.team == team)

    letters = query.order_by(Letter.created_at.desc()).all()
    
    return [
        {
            "id": l.id,
            "content": l.content,
            "is_shared": l.is_shared,
            "team": l.team,
            "created_at": l.created_at
        }
        for l in letters
    ]

@app.get("/history/all")
def get_history_all(limit: int = 500, db: Session = Depends(get_db)):
    records = (
        db.query(AnalysisResult)
        .order_by(AnalysisResult.created_at.desc())
        .limit(limit)
        .all()
    )

    return [
        {
            "id": r.id,
            "text": r.text,
            "tone": r.tone,
            "burnout": r.burnout,
            "risk": r.risk,
            "distress_level": r.distress_level,
            "final_status": r.final_status,
            "team": r.team,
            "created_at": r.created_at
        }
        for r in records
    ]