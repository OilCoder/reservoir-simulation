#!/usr/bin/env python3
"""
Test PyTorch GPU functionality
"""

import torch
import time

def test_pytorch_gpu():
    print("🔥 PyTorch GPU Test")
    print("=" * 50)
    
    # Basic info
    print(f"PyTorch version: {torch.__version__}")
    print(f"CUDA available: {torch.cuda.is_available()}")
    
    if torch.cuda.is_available():
        print(f"CUDA version: {torch.version.cuda}")
        print(f"GPU count: {torch.cuda.device_count()}")
        print(f"Current GPU: {torch.cuda.current_device()}")
        print(f"GPU name: {torch.cuda.get_device_name(0)}")
        
        # Memory info
        print(f"GPU memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
        
        # Simple computation test
        print("\n🧪 GPU Computation Test:")
        device = torch.device('cuda:0')
        
        # Create tensors
        x = torch.randn(1000, 1000, device=device)
        y = torch.randn(1000, 1000, device=device)
        
        # Time matrix multiplication
        start_time = time.time()
        z = torch.matmul(x, y)
        torch.cuda.synchronize()  # Wait for GPU
        gpu_time = time.time() - start_time
        
        print(f"✅ GPU matrix multiply (1000x1000): {gpu_time:.4f}s")
        print(f"   Result shape: {z.shape}")
        print(f"   Result sum: {z.sum().item():.2f}")
        
        # Test GPU memory
        print(f"\n📊 GPU Memory:")
        print(f"   Allocated: {torch.cuda.memory_allocated(0) / 1024**2:.1f} MB")
        print(f"   Cached: {torch.cuda.memory_reserved(0) / 1024**2:.1f} MB")
        
        return True
    else:
        print("❌ CUDA not available")
        return False

if __name__ == "__main__":
    test_pytorch_gpu()