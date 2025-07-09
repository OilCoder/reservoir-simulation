#!/usr/bin/env python3
import torch
import tensorflow as tf

print("=== GPU Status ===")
print(f"PyTorch version: {torch.__version__}")
print(f"TensorFlow version: {tf.__version__}")
print(f"CUDA available (PyTorch): {torch.cuda.is_available()}")
print(f"GPU count (PyTorch): {torch.cuda.device_count()}")

if torch.cuda.is_available():
    for i in range(torch.cuda.device_count()):
        print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
        print(f"  Memory: {torch.cuda.get_device_properties(i).total_memory / 1024**3:.1f} GB")

print(f"GPU available (TensorFlow): {len(tf.config.list_physical_devices('GPU')) > 0}")
tf_gpus = tf.config.list_physical_devices('GPU')
for i, gpu in enumerate(tf_gpus):
    print(f"TensorFlow GPU {i}: {gpu}")
