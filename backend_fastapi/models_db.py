from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
from db import Base

class AnalysisResult(Base):
    __tablename__ = "analysis_results"

    id = Column(Integer, primary_key=True, index=True)
    text = Column(String)
    tone = Column(String)
    burnout = Column(Integer)
    risk = Column(String)


  
    distress_level = Column(String)
    final_status = Column(String)

    team = Column(String)

    created_at = Column(DateTime(timezone=True), server_default=func.now())



class Letter(Base):
    __tablename__ = "letters"

    id = Column(Integer, primary_key=True, index=True)
    content = Column(String, nullable=False)
    is_shared = Column(Boolean, default=False)
    team = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
