# model/main.py
from fastapi import FastAPI, HTTPException
import traceback
from model.data_loader import load_freelancers_from_db
from model.matching import match_freelancers
from model.models import MatchRequest, FreelancerOut

app = FastAPI(title="Rule-based Matching Service (Freelancer Search)")

# โหลด data จาก DB ตอน startup
ROWS = load_freelancers_from_db()

@app.post("/match_freelancers", response_model=list[FreelancerOut])
def api_match(req: MatchRequest):
    try:
        # เตรียม filters
        filters = {}
        if req.filters:
            filters = {k: v for k, v in req.filters.dict().items() if v is not None}
        top_k = req.top_k or 10

        # เรียกฟังก์ชัน matching
        raw_results = match_freelancers(ROWS, req.search_text, filters=filters, top_k=top_k)

        # แปลงแต่ละ result ให้ตรงกับ FreelancerOut
        results: list[FreelancerOut] = []
        for r in raw_results:
            results.append(FreelancerOut(
                freelancer_id=r.get("user_id"),  # map user_id -> freelancer_id
                name=r.get("name", ""),
                score=r.get("score", 0.0),
                rate=r.get("rate"),
                avg_rating=r.get("avg_rating", 0.0),
                job_count=r.get("job_count", 0),
                location=r.get("location", ""),
                reason=str(r.get("reason", "")),
                details=r.get("details", {})   # ถ้ามี field details
            ))

        return results

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
