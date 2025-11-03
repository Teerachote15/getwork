# model/matching.py
from typing import List, Dict
import re

def match_freelancers(
    freelancers: List[Dict],
    search_text: str,
    filters: Dict = None,
    top_k: int = 10
) -> List[Dict]:
    """
    Match freelancers based on search_text and optional filters.
    freelancers: list of dicts (from DB)
    search_text: string to search in name, description, categories, posts
    filters: optional dict of {field_name: value}
    top_k: max number of results to return
    """
    if filters is None:
        filters = {}

    results = []

    search_words = [w.lower() for w in re.findall(r"\w+", search_text)]

    for f in freelancers:
        score = 0
        reason = []

        # Apply filters
        skip = False
        for k, v in filters.items():
            if k not in f or f[k] is None:
                skip = True
                break
            # Support simple substring match
            if isinstance(f[k], str):
                if v.lower() not in f[k].lower():
                    skip = True
                    break
            else:
                if f[k] != v:
                    skip = True
                    break
        if skip:
            continue

        # Match search_text
        text_fields = " ".join([
            f.get("name", ""),
            f.get("description", ""),
            f.get("categories", ""),
            f.get("posts", "")
        ]).lower()

        for word in search_words:
            if word in text_fields:
                score += 1
                reason.append(word)

        if score > 0:
            result = f.copy()
            result["score"] = score
            result["reason"] = ", ".join(reason)
            result["details"] = {
                "matched_words": reason
            }
            results.append(result)

    # Sort by score desc, then avg_rating desc
    results.sort(key=lambda x: (x["score"], x.get("avg_rating", 0)), reverse=True)

    return results[:top_k]
