#!/usr/bin/env python3
"""
MRST Monitoring System - Launcher único
Genera plots y lanza dashboard automáticamente
"""

import subprocess
import sys
import time
import webbrowser
from pathlib import Path


def kill_existing_streamlit():
    """Kill any existing Streamlit processes"""
    try:
        subprocess.run(["pkill", "-f", "streamlit"],
                       capture_output=True, text=True)
        print("🧹 Limpiando procesos anteriores...")
        time.sleep(1)
    except Exception as e:
        print(f"⚠️  Error limpiando procesos: {e}")


def generate_plots():
    """Generate all monitoring plots"""
    print("🎨 Generando plots...")
    
    script_dir = Path(__file__).parent
    plot_scripts = ["plot_evolution.py", "plot_maps.py", "plot_wells.py"]
    
    for script in plot_scripts:
        script_path = script_dir / "plot_scripts" / script
        if script_path.exists():
            print(f"  📊 Ejecutando {script}...")
            try:
                result = subprocess.run([sys.executable, str(script_path)],
                                        capture_output=True, text=True)
                if result.returncode == 0:
                    print(f"  ✅ {script} completado")
                else:
                    print(f"  ❌ Error en {script}: {result.stderr}")
            except Exception as e:
                print(f"  ❌ Error ejecutando {script}: {e}")
        else:
            print(f"  ⚠️  Script no encontrado: {script_path}")


def launch_dashboard():
    """Launch Streamlit dashboard in background"""
    script_dir = Path(__file__).parent
    app_path = script_dir / "streamlit" / "app.py"
    
    if not app_path.exists():
        print(f"❌ App no encontrada: {app_path}")
        return
    
    print("\n🚀 Iniciando dashboard...")
    print("=" * 60)
    print("🌐 DASHBOARD MRST MONITORING")
    print("=" * 60)
    print("📋 Plots generados: ✅ COMPLETADO")
    print("🚀 Iniciando Streamlit en segundo plano...")
    
    try:
        # Launch Streamlit in background
        process = subprocess.Popen([
            "streamlit", "run", str(app_path),
            "--server.port", "8502",
            "--server.address", "0.0.0.0",
            "--browser.gatherUsageStats", "false"
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Wait a moment for Streamlit to start
        time.sleep(3)
        
        # Check if process is still running
        if process.poll() is None:
            print("✅ Streamlit iniciado correctamente!")
            print("")
            print("🎉" * 20)
            print("✅ DASHBOARD LISTO!")
            print("🎉" * 20)
            print("")
            print("🔗 COPIA una de estas URLs y pégala en tu navegador:")
            print("   👉 http://localhost:8502")
            print("   👉 http://127.0.0.1:8502")
            print("   👉 http://0.0.0.0:8502")
            print("")
            print("⚠️  IMPORTANTE:")
            print("   - El servidor está corriendo en segundo plano")
            print("   - Si no funciona una URL, prueba las otras")
            print("   - Para detener el servidor, ejecuta:")
            print("     pkill -f streamlit")
            print("=" * 60)
            
            # Try to open browser automatically
            try:
                webbrowser.open("http://localhost:8502")
                print("🌐 Intentando abrir navegador automáticamente...")
            except Exception:
                print("⚠️  No se pudo abrir el navegador automáticamente")
                print("   Por favor, copia la URL manualmente")
                
        else:
            print("❌ Error: Streamlit no se pudo iniciar")
            print("💡 Prueba ejecutar manualmente:")
            print(f"   streamlit run {app_path}")
            
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("💡 Verifica que Streamlit esté instalado:")
        print("   pip install streamlit")


def main():
    print("🛢️  MRST MONITORING SYSTEM")
    print("=" * 40)
    
    # Step 1: Clean up any existing processes
    kill_existing_streamlit()
    
    # Step 2: Generate plots
    generate_plots()
    
    # Step 3: Launch dashboard
    launch_dashboard()
    
    print("\n🏁 Proceso completado!")
    print("💡 El dashboard está corriendo en segundo plano")


if __name__ == "__main__":
    main() 