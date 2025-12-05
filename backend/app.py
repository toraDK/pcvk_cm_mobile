from flask import Flask, request, jsonify
import cv2
import numpy as np
from PIL import Image
import io
import base64
from sklearn import svm
import joblib  # untuk load/save model SVM

app = Flask(__name__)

# ==== Load Haar Cascade ====
cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
face_cascade = cv2.CascadeClassifier(cascade_path)
if face_cascade.empty():
    print("❌ Haar Cascade XML not found!")
else:
    print("✅ Haar Cascade loaded successfully")

# ==== Dummy SVM Model / Load Model Sebenarnya ====
# Contoh: kalau belum punya model, kita bikin dummy SVM
# nanti diganti dengan model hasil training
try:
    svm_model = joblib.load("svm_model.pkl")
    print("✅ SVM model loaded")
except:
    # buat dummy model sementara
    svm_model = svm.SVC()
    print("⚠️ SVM model belum ada, prediksi dummy")

# ==== Fungsi deteksi wajah ====
def detect_and_crop_face(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(
        gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30)
    )
    if len(faces) > 0:
        faces = sorted(faces, key=lambda x: x[2]*x[3], reverse=True)
        x, y, w, h = faces[0]
        cropped_face = gray[y:y+h, x:x+w]
        return cropped_face
    return None

# ==== Endpoint API ====
@app.route("/predict", methods=["POST"])
def predict():
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files["file"]
    image_bytes = file.read()
    pil_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    open_cv_image = np.array(pil_image)[:, :, ::-1].copy()  # RGB -> BGR

    cropped_face = detect_and_crop_face(open_cv_image)
    if cropped_face is None:
        return jsonify({"kelas": "No face detected"})

    # ==== Preprocessing untuk SVM ====
    resized_face = cv2.resize(cropped_face, (100, 100))  # contoh ukuran
    flat_face = resized_face.flatten().reshape(1, -1)

    # ==== Prediksi kelas ====
    try:
        predicted_class = svm_model.predict(flat_face)[0]  # Asia/Afrika/Eropa
    except:
        predicted_class = "Asia"  # dummy sementara

    # ==== Optional: encode cropped face ke base64 untuk preview di Flutter ====
    _, buffer = cv2.imencode('.jpg', cropped_face)
    face_b64 = base64.b64encode(buffer).decode('utf-8')

    return jsonify({
        "kelas": predicted_class,
        "face_crop": face_b64
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
