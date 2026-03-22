#!/usr/bin/env python3
"""
Script de benchmarking automatizado para Optic planner.
Prueba diferentes tamaños de problema (personas, localizaciones, cajas, metas)
para configuraciones de 1-5 drones con timeout de 60 segundos.
"""

import subprocess
import sys
import os
import re
import time
from pathlib import Path
from datetime import datetime

TIMEOUT_SEGUNDOS = 60
MAX_DRONES = 5

class PlanMetrics:
    def __init__(self, metric_time, num_steps):
        self.metric_time = metric_time
        self.num_steps = num_steps

def generar_problema(drones, transportadores, localizaciones, personas, cajas, metas):
    """Ejecuta generador_problemas3.py para crear un problema PDDL"""
    
    cmd = [
        'python3', 'generador_problemas3.py',
        '-d', str(drones),
        '-r', str(transportadores),
        '-l', str(localizaciones),
        '-p', str(personas),
        '-c', str(cajas),
        '-g', str(metas)
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        
        # El generador crea un archivo .pddl con nombre específico
        problem_file = f"drone_problem_d{drones}_r{transportadores}_l{localizaciones}_p{personas}_c{cajas}_g{metas}_ct2.pddl"
        
        if Path(problem_file).exists():
            return problem_file
        else:
            return None
    except Exception as e:
        return None

def extraer_planes(output_optic):
    """Extrae todas las soluciones encontradas por Optic"""
    planes = []
    lineas = output_optic.split('\n')
    
    for i, linea in enumerate(lineas):
        if "Plan found with metric" in linea:
            try:
                # Extraer métrica
                partes = linea.split("metric")
                if len(partes) >= 2:
                    valor_metrica = float(partes[-1].strip())
                    
                    # Contar pasos del plan
                    num_pasos = 0
                    plan_empezado = False
                    j = i + 1
                    while j < len(lineas):
                        siguiente = lineas[j].strip()
                        # Patrón: "XXX.XXX: (accion ...)"
                        if re.match(r'^\d+\.?\d*:', siguiente) and '(' in siguiente:
                            num_pasos += 1
                            plan_empezado = True
                            j += 1
                        elif not plan_empezado:
                            # Antes de la primera acción, saltar cabeceras/comentarios
                            j += 1
                        elif siguiente == "" or siguiente.startswith(";") or "All goal" in siguiente:
                            # Tras empezar el plan, esto marca su final
                            break
                        else:
                            j += 1
                    
                    if num_pasos > 0:
                        planes.append(PlanMetrics(valor_metrica, num_pasos))
            except (ValueError, IndexError):
                pass
    
    return planes

def ejecutar_optic(archivo_dominio, archivo_problema):
    """Ejecuta Optic con timeout y captura output"""
    
    cmd = f"timeout {TIMEOUT_SEGUNDOS} bash -c 'source ./venv/bin/activate && planutils run optic {archivo_dominio} {archivo_problema}'"
    
    inicio = time.time()
    try:
        resultado = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=TIMEOUT_SEGUNDOS+5)
        elapsed = time.time() - inicio
        output = resultado.stdout + resultado.stderr
        timeout_alcanzado = (resultado.returncode == 124)
        return output, elapsed, timeout_alcanzado
    except subprocess.TimeoutExpired:
        elapsed = time.time() - inicio
        return "", elapsed, True
    except Exception as e:
        return str(e), 0, False

def probar_tamaño_problema(drones, localizaciones, personas, cajas, metas):
    """Prueba un tamaño de problema específico"""
    
    transportadores = drones
    
    intentos = 3
    for intento in range(1, intentos + 1):
        # Generar problema
        problema = generar_problema(drones, transportadores, localizaciones, personas, cajas, metas)

        if problema is None:
            if intento == intentos:
                print(f"  L:{localizaciones} P:{personas} C:{cajas} M:{metas} ... ERROR generación")
                return None
            continue

        # Ejecutar Optic
        output, elapsed, timeout = ejecutar_optic("domain3.pddl", problema)

        # Extraer planes
        planes = extraer_planes(output)

        # Limpiar archivo generado
        try:
            os.remove(problema)
        except Exception:
            pass

        if planes:
            break

        if intento == intentos:
            if "unsolvable" in output.lower() or "unreachable" in output.lower():
                print(f"  L:{localizaciones} P:{personas} C:{cajas} M:{metas} ... INSOLVIBLE")
            else:
                print(f"  L:{localizaciones} P:{personas} C:{cajas} M:{metas} ... SIN SOLUCIÓN")
            return None

    if not planes:
        print(f"  L:{localizaciones} P:{personas} C:{cajas} M:{metas} ... SIN SOLUCIÓN")
        return None
    
    primer_plan = planes[0]
    ultimo_plan = planes[-1]
    
    estado = "OK" if not timeout else "TIMEOUT"
    print(f"  L:{localizaciones} P:{personas} C:{cajas} M:{metas} ... {estado} ({len(planes)} planes en {elapsed:.1f}s)")
    
    return {
        'drones': drones,
        'localizaciones': localizaciones,
        'personas': personas,
        'cajas': cajas,
        'metas': metas,
        'primer_pasos': primer_plan.num_steps,
        'primer_tiempo': primer_plan.metric_time,
        'ultimo_pasos': ultimo_plan.num_steps,
        'ultimo_tiempo': ultimo_plan.metric_time,
        'num_planes': len(planes),
        'tiempo_total': elapsed,
        'timeout': timeout
    }

def buscar_tamaño_maximo(drones):
    """Incrementa tamaño del problema hasta que sea insolvible en 60s"""
    
    print(f"\n{'='*70}")
    print(f"Probando {drones} dron(es) con {drones} transportador(es)")
    print(f"{'='*70}")
    
    resultados = []
    tamaño = 2
    max_iteraciones = 5
    
    while True:
        # Estrategia: aumentar localizaciones como factor principal
        localizaciones = tamaño
        personas = tamaño
        cajas = tamaño
        metas = tamaño
        
        resultado = probar_tamaño_problema(drones, localizaciones, personas, cajas, metas)
        
        if resultado:
            resultados.append(resultado)
            tamaño += 1
        else:
            # Si falla uno, no intentes tamaños mayores
            break
    
    return resultados

def imprimir_tabla_resultados(todos_resultados):
    """Imprime tabla con resultados de todas las configuraciones"""
    
    print("\n\n" + "="*120)
    print("RESULTADOS DE BENCHMARKING - Optic Planner (timeout 60 segundos)")
    print("="*120)
    
    for drones, resultados in todos_resultados:
        if not resultados:
            print(f"\nNinguna solución encontrada para {drones} dron(es)")
            continue
        
        print(f"\n{'-'*116}")
        print(f"Configuración: {drones} Dron(es) / {drones} Transportador(es)")
        print(f"{'-'*116}")
        print(f"{'L':<3} {'P':<3} {'C':<4} {'M':<4} {'1er-Pasos':<10} {'1er-Tiempo':<12} {'Últ-Pasos':<10} {'Últ-Tiempo':<12} {'#Planes':<8} {'Mejora T%':<10}")
        print(f"{'-'*116}")
        
        for res in resultados:
            mejora_t = ((res['primer_tiempo'] - res['ultimo_tiempo']) / res['primer_tiempo'] * 100) if res['primer_tiempo'] > 0 else 0
            
            print(f"{res['localizaciones']:<3} {res['personas']:<3} {res['cajas']:<4} {res['metas']:<4} "
                  f"{res['primer_pasos']:<10} {res['primer_tiempo']:<12.1f} "
                  f"{res['ultimo_pasos']:<10} {res['ultimo_tiempo']:<12.1f} "
                  f"{res['num_planes']:<8} {mejora_t:+.1f}%")
    
    print(f"{'='*116}\n")

def guardar_resultados(todos_resultados, nombre_archivo):
    """Guarda resultados en archivo de texto"""
    
    with open(nombre_archivo, 'w') as f:
        f.write("BENCHMARKING AUTOMATIZADO - Optic Planner\n")
        f.write(f"Generado: {datetime.now()}\n")
        f.write(f"Timeout: {TIMEOUT_SEGUNDOS} segundos\n")
        f.write(f"Max Drones: {MAX_DRONES}\n")
        f.write("="*120 + "\n\n")
        
        for drones, resultados in todos_resultados:
            if not resultados:
                f.write(f"\nNinguna solución para {drones} dron(es)\n")
                continue
            
            f.write(f"\n{'-'*116}\n")
            f.write(f"Configuración: {drones} Dron(es) / {drones} Transportador(es)\n")
            f.write(f"{'-'*116}\n")
            f.write(f"{'L':<3} {'P':<3} {'C':<4} {'M':<4} {'1er-Pasos':<10} {'1er-Tiempo':<12} {'Últ-Pasos':<10} {'Últ-Tiempo':<12} {'#Planes':<8}\n")
            f.write(f"{'-'*116}\n")
            
            for res in resultados:
                mejora_t = ((res['primer_tiempo'] - res['ultimo_tiempo']) / res['primer_tiempo'] * 100) if res['primer_tiempo'] > 0 else 0
                
                f.write(f"{res['localizaciones']:<3} {res['personas']:<3} {res['cajas']:<4} {res['metas']:<4} "
                        f"{res['primer_pasos']:<10} {res['primer_tiempo']:<12.1f} "
                        f"{res['ultimo_pasos']:<10} {res['ultimo_tiempo']:<12.1f} "
                        f"{res['num_planes']:<8}\n")

def main():
    print("\n" + "="*70)
    print("BENCHMARKING AUTOMATIZADO - Optic Planner")
    print(f"Probando 1-{MAX_DRONES} drones, aumentando tamaño")
    print(f"Timeout: {TIMEOUT_SEGUNDOS} segundos por problema")
    print("="*70)
    
    todos_resultados = []
    
    # Probar cada configuración de drones
    for drones in range(1, MAX_DRONES + 1):
        resultados = buscar_tamaño_maximo(drones)
        todos_resultados.append((drones, resultados))
        time.sleep(0.5)
    
    # Mostrar resultados
    imprimir_tabla_resultados(todos_resultados)
    
    # Guardar en archivo
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    archivo_salida = f"benchmark_resultados_{timestamp}.txt"
    guardar_resultados(todos_resultados, archivo_salida)
    
    print(f"Resultados guardados en: {archivo_salida}")

if __name__ == '__main__':
    main()
