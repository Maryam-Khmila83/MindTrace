# MindTrace — AI-Powered Employee Burnout Detection System

## Overview

MindTrace is an AI-powered mobile application designed to monitor employee emotional wellbeing and burnout risk in workplace environments.

The system combines:

* emotion recognition
* mental distress detection
* burnout risk estimation
* history-based emotional analysis

to generate meaningful wellness insights for both employees and HR teams.

The project includes:

* 📱 Flutter mobile app
* ⚡ FastAPI backend
* 🤖 Custom NLP models
* 📊 HR analytics dashboard
* 💌 Anonymous employee feedback system

## 🎥 Demo

🔗 Watch the demo on LinkedIn:  

https://www.linkedin.com/posts/maryam-khmila-5011132b0_ai-nlp-flutter-ugcPost-7462963894182080513-N_EH?utm_source=share&utm_medium=member_desktop&rcm=ACoAAErEdBEBmg0zraDrtmro6_IiLernnl7tex8


# Features


## Employee Mode

* Emotion analysis from text
* Burnout risk estimation
* Personal emotional history
* Insights dashboard
* Anonymous HR letter sharing
* Team selection system


## HR Dashboard

* Team-based analytics
* Burnout trend visualization
* Shared anonymous feedback
* Workforce wellbeing overview



# AI Architecture

MindTrace uses two separate NLP models:

### 1️⃣ Emotion Analysis Model

Fine-tuned DistilBERT model trained on emotional text data for:

* multi-label emotion detection
* emotional tone analysis
* burnout estimation



### 2️⃣ Mental Distress Detection Model

DistilBERT-based classifier trained to identify:

* emotional distress
* stress-related patterns



### 🔄 Fusion Logic

The backend combines outputs from both models using custom reasoning logic to generate:

* final emotional status
* burnout risk level
* persistent stress detection

The system also applies temporal smoothing using recent emotional history to improve stability and realism of predictions.


# Tech Stack

## Frontend

* Flutter
* Dart

## Backend

* FastAPI
* SQLAlchemy
* SQLite

## AI / ML

* PyTorch
* Transformers
* DistilBERT




