import json

CLASS_NAMES = ["safe", "nudity", "violence"]

# ตั้งค่า threshold เป็น 0.5 ทุก class
thresholds = {c: 0.5 for c in CLASS_NAMES}

with open("thresholds.json", "w") as f:
    json.dump(thresholds, f)

print("✅ thresholds.json created with default values")
