import torch
import torch.nn as nn
from transformers import (
    DistilBertModel,
    DistilBertPreTrainedModel
)

class DistilBertForMultiLabelWeighted(DistilBertPreTrainedModel):
    def __init__(self, config, pos_weights=None):
        super().__init__(config)
        self.distilbert = DistilBertModel(config)
        self.classifier = nn.Linear(config.hidden_size, config.num_labels)
        self.init_weights()

    def forward(self, input_ids=None, attention_mask=None):
        outputs = self.distilbert(
            input_ids=input_ids,
            attention_mask=attention_mask
        )
        pooled = outputs.last_hidden_state[:, 0]
        logits = self.classifier(pooled)
        return {"logits": logits}
