#!/bin/bash
echo "📊 Iniciando TensorBoard..."
tensorboard --logdir=/workspace/logs --host=0.0.0.0 --port=6006
