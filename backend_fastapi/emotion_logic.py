import torch


NEGATIVE = [
    "anger", "annoyance", "sadness",
    "fear", "disappointment", "nervousness"
]

POSITIVE = [
    "joy", "gratitude", "love", "excitement",
    "optimism", "admiration", "pride", "amusement"
]

NEUTRAL = [
    "neutral", "relief", "approval", "curiosity", "caring"
]

BURNOUT_KEYWORDS = [
    "exhausted",
    "drained",
    "burned out",
    "burnt out",
    "overwhelmed",
    "mentally overloaded",
    "emotionally exhausted",
    "too much stress",
    "can't focus anymore",
    "constant pressure",
    "exhausting",
    "feels heavy",
    "heavy and exhausting"
]

# --- Level 3: confidence dampening ---
def apply_confidence_dampening(burnout, probs, keyword_hit):
    """
    Reduce burnout slightly when the model is uncertain.
    Never reduce if keyword booster triggered.
    """
    if keyword_hit:
        return burnout  # safety first

    max_prob = float(probs.max())

    # Model unsure → soften score
    if max_prob < 0.50:
        burnout *= 0.75
    elif max_prob < 0.65:
        burnout *= 0.90

    return burnout

def derive_tone_from_probs(probs, emotion_cols):
    emo_dict = {
        emotion_cols[i]: float(probs[i])
        for i in range(len(emotion_cols))
    }

    neg = sum(emo_dict.get(e, 0) for e in NEGATIVE)
    pos = sum(emo_dict.get(e, 0) for e in POSITIVE)
    neu = sum(emo_dict.get(e, 0) for e in NEUTRAL)

    if neg >= pos and neg >= neu:
        return "negative"
    elif pos >= neg and pos >= neu:
        return "positive"
    else:
        return "neutral"
    

def burnout_risk_level(percent):
    if percent < 30:
        return "low"
    elif percent < 65:
        return "medium"
    else:
        return "high"



def compute_burnout_from_probs(probs, emotion_cols):
    """
    Compute burnout directly from raw model probabilities.
    More stable than threshold-based scoring.
    """

    emo_dict = {
        emotion_cols[i]: float(probs[i])
        for i in range(len(emotion_cols))
    }

    burnout_score = (
        0.45 * emo_dict.get("nervousness", 0) +
        0.35 * emo_dict.get("sadness", 0) +
        0.20 * emo_dict.get("fear", 0)
    )

    return int(burnout_score * 100)

def analyze_text(text, model, tokenizer, emotion_cols, thresholds):
    inputs = tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        padding=True,
        max_length=128
    )

    with torch.no_grad():
        outputs = model(**inputs)
        print("TYPE OF OUTPUT:", type(outputs))
        
        if isinstance(outputs, dict):
            logits = outputs["logits"]
        else:
            logits = outputs.logits


    probs = torch.sigmoid(logits).cpu().numpy()[0]

    predictions = []
    for i, emotion in enumerate(emotion_cols):
        if probs[i] >= thresholds[emotion]:
            predictions.append((emotion, float(round(probs[i], 2))))

    predictions.sort(key=lambda x: x[1], reverse=True)

    tone = derive_tone_from_probs(probs, emotion_cols)
    burnout = compute_burnout_from_probs(probs, emotion_cols)

# --- Level 2: keyword booster ---
    text_lower = text.lower()
    keyword_hit = any(k in text_lower for k in BURNOUT_KEYWORDS)

    if keyword_hit:
        burnout = max(burnout, 45)

# --- Level 3: confidence awareness ---
    burnout = apply_confidence_dampening(burnout, probs, keyword_hit)

    burnout = int(burnout)
    risk = burnout_risk_level(burnout)

    return {
        "tone": tone,
        "burnout": burnout,
        "risk": risk,
        "top_emotions": predictions[:3]
    }



