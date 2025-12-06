import numpy as np
import cv2
import pickle
import tensorflow as tf
from flask import Flask, request, jsonify
from skimage import feature

app = Flask(__name__)

MODEL_PATH = 'models/ethnicity_ann_model.h5'
SCALER_PATH = 'models/scaler_ann.pkl'

CLASS_NAMES = ['asian', 'africa', 'eropa']

model = None
scaler = None

try:
    model = tf.keras.models.load_model(MODEL_PATH)
    with open(SCALER_PATH, 'rb') as f:
        scaler = pickle.load(f)
    print("✅ System Loaded Successfully")
except Exception as e:
    print(f"❌ Error loading system: {e}")

cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
face_cascade = cv2.CascadeClassifier(cascade_path)


def detect_and_crop_face(image):
    if image is None:
        return None, None
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.1, 5, minSize=(30, 30))
    if len(faces) > 0:
        faces = sorted(faces, key=lambda x: x[2] * x[3], reverse=True)
        x, y, w, h = faces[0]
        return gray[y:y + h, x:x + w], (x, y, w, h)
    return None, None


def preprocess_image_pipeline(image, output_size=(64, 64)):
    resized = cv2.resize(image, output_size)
    return cv2.equalizeHist(resized)


def extract_lbp_features(image):
    lbp = feature.local_binary_pattern(image, 8, 1, method='uniform')
    hist, _ = np.histogram(lbp.ravel(), bins=59, range=(0, 59))
    hist = hist.astype("float")
    return hist / (hist.sum() + 1e-7)


def extract_hog_features(image):
    return feature.hog(image, orientations=9, pixels_per_cell=(8, 8),
                       cells_per_block=(2, 2), block_norm='L2-Hys',
                       visualize=False, feature_vector=True)


def fuse_features(lbp, hog):
    return np.concatenate([lbp, hog])


@app.route('/predict', methods=['POST'])
def predict():
    try:
        file = request.files.get('file')
        if file is None:
            return jsonify(success=False, message="No image uploaded"), 400

        img_original = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)

        if img_original is None:
            return jsonify(success=False, message="Invalid image format"), 400

        face_img, rect = detect_and_crop_face(img_original)
        if face_img is None:
            return jsonify(success=False, message="Face not detected"), 422

        processed = preprocess_image_pipeline(face_img)
        lbp_feat = extract_lbp_features(processed)
        hog_feat = extract_hog_features(processed)

        features = fuse_features(lbp_feat, hog_feat).reshape(1, -1)
        features = scaler.transform(features)

        preds = model.predict(features)
        class_idx = np.argmax(preds[0])
        confidence = float(np.max(preds[0]) * 100)

        return jsonify(
            success=True,
            prediction=CLASS_NAMES[class_idx],
            confidence=confidence
        )

    except Exception as e:
        return jsonify(success=False, message=str(e)), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=7860)