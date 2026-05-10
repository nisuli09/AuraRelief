from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
import os

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# Load trained model
model = joblib.load("migraine_model.pkl")


@app.route("/predict", methods=["POST"])
def predict():

    try:
        data = request.json

        features = np.array([[
    data['sleep_hours'],
    data['stress_level'],
    data['hydration_level'],
    data['screen_time'],
    data['mood_level']
]])

        # ML Prediction
        prediction = int(model.predict(features)[0])

        therapies = []

        # Stress
        if data['stress_level'] >= 7:
            therapies.append("Stress Relief Meditation")

        # Sleep
        if data['sleep_hours'] <= 5:
            therapies.append("Sleep Improvement Therapy")

        # Hydration
        if data['hydration_level'] <= 3:
            therapies.append("Hydration Therapy")

        # Screen time
        if data['screen_time'] >= 7:
            therapies.append("Eye Relaxation Exercise")

        # Mood
        if data['mood_level'] <= 3:
            therapies.append("Mood Relaxation Therapy")

        # Severity-based therapies
        if prediction == 1:
            therapies.extend([
                "Hydration & Rest Therapy",
                "Light Stretching",
                "Short Nap Therapy"
            ])

        elif prediction == 2:
            therapies.extend([
                "Breathing & Relaxation Therapy",
                "Meditation",
                "Mindfulness Exercise"
            ])

        else:
            therapies.extend([
                "Stress Relief & Dark Room Therapy",
                "Cold Compress Therapy",
                "Digital Detox"
            ])

        # Remove duplicates
        therapies = list(set(therapies))

        return jsonify({
            "severity": int(prediction),
            "therapies": therapies
        })

    except Exception as e:
        print("ERROR:", e)
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)