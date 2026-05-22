import torch
from transformers import DistilBertTokenizerFast, DistilBertForSequenceClassification

device = torch.device("cpu")

MODEL_PATH = "model2_mental_distress_results/model"

tokenizer = DistilBertTokenizerFast.from_pretrained(MODEL_PATH)
model = DistilBertForSequenceClassification.from_pretrained(MODEL_PATH)
model.to(device)
model.eval()


def predict_distress(text, low=0.60, high=0.85):
    inputs = tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        padding=True,
        max_length=128
    )

    with torch.no_grad():
        outputs = model(**inputs)

    probs = torch.softmax(outputs.logits, dim=1)
    p = probs[0, 1].item()

    if p >= high:
        level = "high_distress"
    elif p >= low:
        level = "moderate_distress"
    else:
        level = "no_distress"

    return {
        "distress_probability": round(p, 3),
        "distress_level": level
    }
