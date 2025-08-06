#!/usr/bin/env python3
"""
Test TensorFlow GPU functionality
"""

import tensorflow as tf
import time
import os

def test_tensorflow_gpu():
    print("🔷 TensorFlow GPU Test")
    print("=" * 50)
    
    # Suppress TensorFlow warnings for cleaner output
    os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
    
    # Basic info
    print(f"TensorFlow version: {tf.__version__}")
    print(f"Built with CUDA: {tf.test.is_built_with_cuda()}")
    
    # GPU detection
    gpus = tf.config.list_physical_devices('GPU')
    print(f"Physical GPUs: {len(gpus)}")
    
    if gpus:
        for i, gpu in enumerate(gpus):
            print(f"GPU {i}: {gpu}")
            
        # GPU details
        gpu_details = tf.config.experimental.get_device_details(gpus[0])
        print(f"GPU name: {gpu_details.get('device_name', 'Unknown')}")
        
        # Memory info
        try:
            memory_info = tf.config.experimental.get_memory_info('GPU:0')
            print(f"GPU memory: {memory_info['peak'] / 1024**3:.1f} GB peak")
        except:
            print("GPU memory info not available")
        
        # Test GPU computation
        print("\n🧪 GPU Computation Test:")
        
        with tf.device('/GPU:0'):
            # Create random matrices
            x = tf.random.normal([1000, 1000])
            y = tf.random.normal([1000, 1000])
            
            # Time matrix multiplication
            start_time = time.time()
            z = tf.matmul(x, y)
            # Force execution
            _ = z.numpy()
            gpu_time = time.time() - start_time
            
            print(f"✅ GPU matrix multiply (1000x1000): {gpu_time:.4f}s")
            print(f"   Result shape: {z.shape}")
            print(f"   Result sum: {tf.reduce_sum(z).numpy():.2f}")
            
            # Test different operations
            print("\n🔬 Additional GPU Tests:")
            
            # Convolution test
            start_time = time.time()
            conv_input = tf.random.normal([1, 224, 224, 3])
            conv_filter = tf.random.normal([3, 3, 3, 32])
            conv_result = tf.nn.conv2d(conv_input, conv_filter, strides=1, padding='SAME')
            _ = conv_result.numpy()
            conv_time = time.time() - start_time
            print(f"✅ GPU convolution (224x224x3): {conv_time:.4f}s")
            
            # Reduction test
            start_time = time.time()
            large_tensor = tf.random.normal([10000, 1000])
            reduction_result = tf.reduce_mean(large_tensor, axis=1)
            _ = reduction_result.numpy()
            reduction_time = time.time() - start_time
            print(f"✅ GPU reduction (10000x1000): {reduction_time:.4f}s")
        
        # Memory usage
        try:
            memory_info = tf.config.experimental.get_memory_info('GPU:0')
            print(f"\n📊 GPU Memory Usage:")
            print(f"   Current: {memory_info['current'] / 1024**2:.1f} MB")
            print(f"   Peak: {memory_info['peak'] / 1024**2:.1f} MB")
        except:
            print("\n📊 GPU Memory info not available")
        
        return True
    else:
        print("❌ No GPUs detected")
        
        # Test CPU fallback
        print("\n🔄 Testing CPU fallback:")
        x = tf.random.normal([100, 100])
        y = tf.random.normal([100, 100])
        z = tf.matmul(x, y)
        print(f"✅ CPU matrix multiply works: {z.shape}")
        
        return False

if __name__ == "__main__":
    test_tensorflow_gpu()