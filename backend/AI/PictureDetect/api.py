import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

from flask import Flask, request, jsonify
from keras.models import load_model
from keras.utils import img_to_array
import numpy as np
from PIL import Image
import io
import json

app = Flask(__name__)

# โหลดโมเดล
MODEL_PATH = "multi_label_model.h5"
model = load_model(MODEL_PATH)
CLASS_NAMES = ["safe", "nudity", "violence"]

# โหลด threshold
with open("thresholds.json", "r") as f:
    thresholds = json.load(f)

# ตรวจสอบว่า threshold ครบทุก class
for cname in CLASS_NAMES:
    if cname not in thresholds:
        raise ValueError(f"Threshold for class '{cname}' not found in thresholds.json")

# ฟังก์ชัน preprocessing
def preprocess_image(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((224, 224))
    arr = img_to_array(img) / 255.0
    return np.expand_dims(arr, axis=0)

# Endpoint ตรวจรูปภาพ
@app.route("/check_profile_image", methods=["POST"])
def check_profile_image():
    if "file" not in request.files:
        return jsonify({"error": "No file part in request"}), 400

    file = request.files["file"]

    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    try:
        content = file.read()
        x = preprocess_image(content)
        probs = model.predict(x, verbose=0)[0].tolist()

        result = {}
        rejected = []

        for i, cname in enumerate(CLASS_NAMES):
            prob = float(probs[i])
            thr = thresholds[cname]
            predicted = 1 if prob >= thr else 0

            result[cname] = {
                "probability": prob,
                "threshold": thr,
                "predicted": predicted
            }

            if predicted == 1 and cname != "safe":
                rejected.append(cname)

        status = "rejected" if rejected else "approved"
        return jsonify({
            "status": status,
            "reasons": rejected,
            "results": result
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
