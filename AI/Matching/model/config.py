# app/config.py

# Weighting config for rule-based matching (tweakable)
WEIGHTS = {
    "w_about": 0.4,         # weight for matches in about_me
    "w_work": 0.4,          # weight for matches in work_experience
    "w_posts": 0.2,         # weight for matches in post_titles or post_details
    # boosts / filters
    "boost_rating": 0.05,   # multiply score by (1 + boost_rating * (avg_rating - 4)) for rating > 4
    "job_count_boost": 0.02 # small boost per 10 jobs (example)
}

# Matching thresholds / options
DEFAULTS = {
    "top_k": 10,
    "min_score_for_recommend": 5.0  # minimal normalized score (0..100) to show
}
