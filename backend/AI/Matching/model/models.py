# app/models.py
from pydantic import BaseModel
from typing import List, Optional

class MatchFilters(BaseModel):
    min_rate: Optional[float] = None
    max_rate: Optional[float] = None
    min_rating: Optional[float] = None
    location: Optional[str] = None

class MatchRequest(BaseModel):
    search_text: str
    filters: Optional[MatchFilters] = None
    top_k: Optional[int] = 10

class FreelancerOut(BaseModel):
    freelancer_id: int
    name: Optional[str]
    score: float
    rate: Optional[float]
    avg_rating: Optional[float]
    job_count: Optional[int]
    location: Optional[str]
    reason: Optional[str]
