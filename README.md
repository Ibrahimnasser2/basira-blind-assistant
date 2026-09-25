# BASIRA AI (بصيرة)

Voice-first assistive Flutter application for blind and visually impaired users.

## MVP Features

- Real-time OCR with Arabic/English reading via TTS.
- Real-time object detection for nearby obstacles and objects.
- Face detection with spoken face count.
- Barcode scanning + product lookup.
- Currency detection module with local TFLite integration contract.
- Accessible home with large controls, haptics, and voice commands.

## Run

1. `flutter pub get`
2. `flutter run`

## Currency Model (EGP) Training Pipeline

This app expects:
- Model: `assets/models/egp_currency.tflite`
- Labels: `assets/labels/egp_labels.txt`
- Target classes: `5 EGP, 10 EGP, 20 EGP, 50 EGP, 100 EGP, 200 EGP`

### 1) Collect dataset

- Download an Egyptian banknotes dataset from Kaggle or Roboflow.
- Ensure balanced images for each class and real-world lighting.

### 2) Train YOLOv8 baseline

```bash
pip install ultralytics
yolo task=detect mode=train model=yolov8n.pt data=egp.yaml imgsz=640 epochs=60
```

### 3) Export to TFLite

```bash
yolo export model=runs/detect/train/weights/best.pt format=tflite int8=True
```

### 4) Integrate into app

- Copy exported model as `assets/models/egp_currency.tflite`.
- Add `assets/labels/egp_labels.txt` with one label per line in class order.
- Confirm input size and quantization preprocessing match training export.

## Manual Test Matrix

- OCR Arabic signs, English labels, short/long text.
- Object detection in indoor/outdoor scenes with different distances.
- Face detection single/multiple/no faces.
- Barcode on food package and non-readable barcodes.
- Currency detection: each EGP class with front/back and varied lighting.
