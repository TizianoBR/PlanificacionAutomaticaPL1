#!/usr/bin/env python3
"""
Script de prueba para comparar planificadores de satisfacción
en múltiples tamaños de problemas.
"""

import subprocess
import os
import time
import sys
from pathlib import Path

# Tamaños de problemas a probar (d, r, l, p, c, g)
problem_sizes = [
    (1, 1, 2, 2, 2, 2),   # Pequeño
    (1, 1, 3, 3, 3, 2),   # Pequeño-Medio
    (2, 1, 3, 4, 4, 3),   # Medio
    (2, 1, 4, 5, 5, 4),   # Medio-Grande
    (3, 1, 5, 6, 6, 5),   # Grande
]

# Planificadores a probar con timeout de 60 segundos
planners = {
    'metric-ff': 'metric-ff -o {domain} -f {problem}',
    'downward-lama': 'planutils run downward -- --alias lama-first --overall-time-limit 60 {domain} {problem}',
    'downward-sat-fdss': 'planutils run downward -- --alias seq-sat-fdss-2 --overall-time-limit 60 {domain} {problem}',
    'downward-sat-auto': 'planutils run downward -- --alias seq-sat-fd-autotune-2 --overall-time-limit 60 {domain} {problem}',
}

def generate_problem(d, r, l, p, c, g):
    """Generar un problema con los parámetros dados."""
    cmd = f'python3 generador_problemas2.py -d {d} -r {r} -l {l} -p {p} -c {c} -g {g}'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=os.getcwd())
    if result.returncode != 0:
        print(f"Error generando problema: {result.stderr}")
        return None
    # El generador crea un archivo con nombre drone_problem_d*_r*_l*_p*_c*_g*.pddl
    problem_file = f'drone_problem_d{d}_r{r}_l{l}_p{p}_c{c}_g{g}_ct2.pddl'
    return problem_file

def run_planner(planner_name, planner_cmd, domain_file, problem_file):
    """Ejecutar un planificador y registrar el tiempo y coste."""
    cmd = planner_cmd.format(domain=domain_file, problem=problem_file)
    
    start_time = time.time()
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=65,  # 60 + buffer
            cwd=os.getcwd()
        )
        elapsed_time = time.time() - start_time
        
        # Buscar coste en la salida
        cost = None
        output = result.stdout + result.stderr
        
        # Diferentes formatos de salida según el planificador
        if 'metric-ff' in planner_name:
            # Metric-FF muestra: ff: solution found
            if 'solution found' in output or 'cost' in output:
                for line in output.split('\n'):
                    if 'cost' in line.lower():
                        try:
                            cost = int(line.split()[-1])
                        except:
                            pass
        else:
            # Downward  muestra el coste en el plan
            if 'Plan length' in output or 'total cost' in output:
                for line in output.split('\n'):
                    if 'Plan length' in line or 'total cost' in line:
                        try:
                            parts = line.split(':')
                            if len(parts) > 1:
                                cost = int(parts[-1].strip())
                        except:
                            pass
        
        success = result.returncode == 0
        return success, elapsed_time, cost
        
    except subprocess.TimeoutExpired:
        return False, 60.0, None
    except Exception as e:
        print(f"Error ejecutando {planner_name}: {e}")
        return False, -1, None

def main():
    domain_file = 'domain2_1.pddl'
    
    if not os.path.exists(domain_file):
        print(f"Error: {domain_file} no encontrado")
        sys.exit(1)
    
    results = {}
    
    for planner_name in planners.keys():
        results[planner_name] = []
    
    for size_idx, (d, r, l, p, c, g) in enumerate(problem_sizes):
        print(f"\n{'='*70}")
        print(f"Tamaño {size_idx+1}: drones={d}, transporters={r}, locations={l}, persons={p}, crates={c}, goals={g}")
        print(f"{'='*70}")
        
        # Generar el problema
        problem_file = generate_problem(d, r, l, p, c, g)
        if not problem_file:
            print("Error generando problema, saltando...")
            continue
        
        # Probar cada planificador
        for planner_name, planner_cmd in planners.items():
            print(f"\nProbando {planner_name}...", end=" ", flush=True)
            success, elapsed_time, cost = run_planner(planner_name, planner_cmd, domain_file, problem_file)
            
            if success:
                print(f"✓ Resuelto en {elapsed_time:.2f}s (coste: {cost})")
                results[planner_name].append({
                    'size': size_idx + 1,
                    'params': (d, r, l, p, c, g),
                    'time': elapsed_time,
                    'cost': cost,
                    'solved': True
                })
            else:
                print(f"✗ No resuelto en 60s")
                results[planner_name].append({
                    'size': size_idx + 1,
                    'params': (d, r, l, p, c, g),
                    'time': 60.0,
                    'cost': None,
                    'solved': False
                })
    
    # Imprimir tabla de resultados
    print(f"\n\n{'='*100}")
    print("TABLA DE RESULTADOS")
    print(f"{'='*100}\n")
    
    print(f"{'Planificador':<25} {'Tamaño':<8} {'Params':<30} {'Tiempo (s)':<12} {'Coste':<8} {'Resuelto':<10}")
    print(f"{'-'*100}")
    
    for planner_name in sorted(results.keys()):
        for result in results[planner_name]:
            params_str = f"d{result['params'][0]}-r{result['params'][1]}-l{result['params'][2]}-p{result['params'][3]}-c{result['params'][4]}-g{result['params'][5]}"
            time_str = f"{result['time']:.2f}" if result['time'] >= 0 else "ERROR"
            cost_str = str(result['cost']) if result['cost'] else "N/A"
            solved_str = "Sí" if result['solved'] else "No"
            print(f"{planner_name:<25} {result['size']:<8} {params_str:<30} {time_str:<12} {cost_str:<8} {solved_str:<10}")
    
    # Resumen
    print(f"\n{'='*100}")
    print("RESUMEN - Máximo tamaño resuelto por planificador:")
    print(f"{'='*100}\n")
    
    for planner_name in sorted(results.keys()):
        solved_results = [r for r in results[planner_name] if r['solved']]
        if solved_results:
            max_result = max(solved_results, key=lambda x: x['size'])
            print(f"{planner_name:<25}: Tamaño {max_result['size']} - {max_result['params']} (coste: {max_result['cost']}, tiempo: {max_result['time']:.2f}s)")
        else:
            print(f"{planner_name:<25}: No resolvió ningún problema")

if __name__ == '__main__':
    main()
