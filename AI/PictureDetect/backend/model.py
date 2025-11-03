import os
import numpy as np
import pandas as pd
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout
from tensorflow.keras.optimizers import Adam

# Config
IMG_SIZE = (224, 224)   # ขนาดมาตรฐานดีอยู่แล้ว
BATCH_SIZE = 6          # น้ำหนักการ เทรน
EPOCHS = 20             # เพิ่มจำนวนรอบ
BASE_DIR = r"C:\Users\USER\Desktop\AI\PictureDetect\backend\data"
CLASSES = ["safe", "nudity", "violence"]


# 📌 สร้าง DataFrame จากโฟลเดอร์
filepaths, labels = [], []
for idx, cls in enumerate(CLASSES):
    folder = os.path.join(BASE_DIR, cls)
    for fname in os.listdir(folder):
        fpath = os.path.join(folder, fname)
        if os.path.isfile(fpath):
            filepaths.append(fpath)
            one_hot = [0] * len(CLASSES)
            one_hot[idx] = 1
            labels.append(one_hot)

df = pd.DataFrame({"filepath": filepaths, "label": labels})
print("Total images:", len(df))

# Generator
def dataframe_generator(df, batch_size=BATCH_SIZE):
    while True:
        df = df.sample(frac=1)  # shuffle
        for start in range(0, len(df), batch_size):
            batch_df = df[start:start+batch_size]
            X, y = [], []
            for _, row in batch_df.iterrows():
                img = load_img(row['filepath'], target_size=IMG_SIZE)
                img = img_to_array(img) / 255.0
                X.append(img)
                y.append(row['label'])
            yield np.array(X), np.array(y)

# Split train/val
train_df = df.sample(frac=0.8, random_state=42)
val_df = df.drop(train_df.index)

train_gen = dataframe_generator(train_df, BATCH_SIZE)
val_gen = dataframe_generator(val_df, BATCH_SIZE)

# Model
model = Sequential([
    Conv2D(32, (3,3), activation='relu', input_shape=(IMG_SIZE[0], IMG_SIZE[1], 3)),
    MaxPooling2D(2,2),
    Conv2D(64, (3,3), activation='relu'),
    MaxPooling2D(2,2),
    Flatten(),
    Dense(128, activation='relu'),
    Dropout(0.5),
    Dense(len(CLASSES), activation='sigmoid')  # multi-label
])

model.compile(optimizer=Adam(1e-4),
              loss='binary_crossentropy',
              metrics=['accuracy'])

# Train
steps_per_epoch = len(train_df) // BATCH_SIZE
validation_steps = len(val_df) // BATCH_SIZE

model.fit(
    train_gen,
    steps_per_epoch=steps_per_epoch,
    epochs=EPOCHS,
    validation_data=val_gen,
    validation_steps=validation_steps
)

# Save model
model.save("multi_label_model.h5")
print("✅ Model saved as multi_label_model.h5")
