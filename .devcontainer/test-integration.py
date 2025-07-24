#!/usr/bin/env python3
"""
Integration test script to verify all components work together
"""

def test_imports():
    """Test that all major packages can be imported"""
    try:
        # Core scientific packages
        import numpy as np
        import pandas as pd
        import scipy
        print("✓ Core scientific packages (numpy, pandas, scipy)")
        
        # Machine Learning
        import sklearn
        print("✓ Scikit-learn")
        
        # Deep Learning frameworks
        import torch
        print(f"✓ PyTorch {torch.__version__}")
        
        import tensorflow as tf
        print(f"✓ TensorFlow {tf.__version__}")
        
        # Visualization
        import matplotlib.pyplot as plt
        import seaborn as sns
        import plotly
        print("✓ Visualization packages (matplotlib, seaborn, plotly)")
        
        # Optimization
        import optuna
        print("✓ Optuna")
        
        # Octave integration
        import oct2py
        print("✓ Oct2Py (Octave integration)")
        
        # Web tools
        import streamlit
        print("✓ Streamlit")
        
        return True
    except ImportError as e:
        print(f"✗ Import error: {e}")
        return False

def test_gpu():
    """Test GPU availability"""
    try:
        import torch
        import tensorflow as tf
        
        # PyTorch GPU test
        pytorch_gpu = torch.cuda.is_available()
        if pytorch_gpu:
            gpu_count = torch.cuda.device_count()
            gpu_name = torch.cuda.get_device_name(0)
            print(f"✓ PyTorch GPU: {gpu_count} device(s) - {gpu_name}")
        else:
            print("✗ PyTorch GPU: Not available")
        
        # TensorFlow GPU test
        tf_gpus = tf.config.list_physical_devices('GPU')
        if tf_gpus:
            print(f"✓ TensorFlow GPU: {len(tf_gpus)} device(s)")
        else:
            print("✗ TensorFlow GPU: Not available")
            
        return pytorch_gpu or len(tf_gpus) > 0
    except Exception as e:
        print(f"✗ GPU test error: {e}")
        return False

def test_octave():
    """Test Octave functionality"""
    try:
        from oct2py import octave
        
        # Test basic Octave operation
        result = octave.eval('2 + 3')
        if result == 5:
            print("✓ Octave basic operations")
        else:
            print("✗ Octave basic operations failed")
            return False
            
        # Test MRST path (if available)
        try:
            octave.eval('which startup')
            print("✓ Octave MRST integration available")
        except:
            print("ℹ MRST startup not found (normal if MRST not fully configured)")
            
        return True
    except Exception as e:
        print(f"✗ Octave test error: {e}")
        return False

if __name__ == "__main__":
    print("=" * 50)
    print("Integration Test for Reservoir Simulation Environment")
    print("=" * 50)
    
    tests_passed = 0
    total_tests = 3
    
    print("\n1. Testing package imports...")
    if test_imports():
        tests_passed += 1
    
    print("\n2. Testing GPU availability...")
    if test_gpu():
        tests_passed += 1
    
    print("\n3. Testing Octave integration...")
    if test_octave():
        tests_passed += 1
    
    print("\n" + "=" * 50)
    print(f"Tests passed: {tests_passed}/{total_tests}")
    
    if tests_passed == total_tests:
        print("🎉 All tests passed! Environment is ready for reservoir simulation.")
    else:
        print("⚠️  Some tests failed. Check the configuration.")
    print("=" * 50)