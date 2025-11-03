# app/utils.py
import re

def normalize_text(s: str) -> str:
    """Lowercase, remove punctuation (keep unicode letters and numbers), collapse spaces."""
    if not s:
        return ""
    s = s.lower()
    # allow letters (including thai range), numbers and spaces
    s = re.sub(r"[^a-z0-9\u0E00-\u0E7F\s]+", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

def count_keyword_matches(text: str, keywords: list) -> int:
    """Count how many keywords appear in text (exact substring match after normalize)."""
    if not text or not keywords:
        return 0
    t = normalize_text(text)
    count = 0
    for k in keywords:
        if not k:
            continue
        k_norm = normalize_text(k)
        if k_norm in t:
            count += 1
    return count

def parse_csv_list_field(field_value: str) -> str:
    """Return text combined (field_value may already be plain string or comma-separated)."""
    if field_value is None:
        return ""
    if isinstance(field_value, str):
        return field_value
    return str(field_value)
