from flask import Flask, request, jsonify
import numpy as np
import joblib
import cv2

app = Flask(__name__)

# Load model ANN sementara
try:
    scaler = joblib.load("models/scaler_ann.pkl")
    print("✔ scaler_ann.pkl loaded")
except:
    scaler = None
    print("❌ scaler_ann.pkl NOT FOUND — running dummy processing")


def preprocess_image(image):
    """
    Preprocessing minimal untuk mobile testing
    - resize ke 64x64
    - grayscale
    - reshape ke 1D vector (4096 dim)
    """
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    resized = cv2.resize(gray, (64, 64))
    flat = resized.flatten().astype("float32") / 255.0
    return flat.reshape(1, -1)


@app.route("/predict", methods=["POST"])
def predict():
    file = request.files.get("image")

    if not file:
        return jsonify(success=False, error="No image uploaded")

    npimg = np.frombuffer(file.read(), np.uint8)
    img = cv2.imdecode(npimg, cv2.IMREAD_COLOR)

    if img is None:
        return jsonify(success=False, error="Invalid image format")

    features = preprocess_image(img)

    if scaler is not None:
        try:
            scaled = scaler.transform(features)
            result = "processed_with_model"
        except Exception as e:
            return jsonify(success=False, error=str(e))

    else:
        scaled = features  # fallback dummy
        result = "dummy_processed"

    return jsonify(success=True, status=result, features_dim=scaled.shape[1])


if __name__ == "__main__":
    print("✔ API Ready for Mobile Testing")
    app.run(debug=True)