#!/bin/bash

echo "=== LIMPIANDO Y GENERANDO PROBLEMAS (Tamaños 2 al 10) ==="
rm -f drone_problem_*.pddl
rm -f errores_pyperplan.log
for i in {2..10}; do
    python3 generador_problemas2.py -d 1 -r 0 -l $i -p $i -c $i -g $i > /dev/null 2>&1
done

es_optimo() {
    alg=$1
    heur=$2
    if [[ "$alg" == "bfs" || "$alg" == "ids" ]]; then echo "Sí"; return; fi
    if [[ "$alg" == "astar" && ( "$heur" == "hmax" || "$heur" == "lmcut" || "$heur" == "none" ) ]]; then echo "Sí"; return; fi
    echo "No"
}

printf "\n%-18s | %-12s | %-12s | %-10s | %-10s\n" "Algoritmo" "Tam. Probl." "Tiempo" "Acciones" "Es óptimo?"
printf -- "-%.0s" {1..74}
printf "\n"

probar() {
    search=$1
    heuristic=$2
    optimo=$(es_optimo $search $heuristic)
    
    alg_name_display=$search
    if [ "$search" == "gbf" ]; then alg_name_display="gbfs"; fi
    if [ "$search" == "ehs" ]; then alg_name_display="ehc"; fi

    if [ "$heuristic" == "none" ]; then
        alg_name="$alg_name_display"
    else
        alg_name="${alg_name_display} + ${heuristic}"
    fi

    for size in {2..10}; do
        file="drone_problem_d1_r0_l${size}_p${size}_c${size}_g${size}_ct2.pddl"
        
        if [ "$heuristic" == "none" ]; then
            cmd="pyperplan -s $search domain2_1_no_cost.pddl $file"
        else
            cmd="pyperplan -s $search -H $heuristic domain2_1_no_cost.pddl $file"
        fi
        
        # 1. Imprimimos el inicio de la fila SIN salto de línea
        printf "%-18s | %-12s | " "$alg_name" "$size"
        
        # 2. Ejecutamos el comando
        timeout 60s $cmd > salida_tmp.log 2>&1
        estado=$?
        
        # 3. Imprimimos el resultado completando la fila
        if [ $estado -eq 124 ]; then
            printf "%-12s | %-10s | %-10s\n" "> 60s (TO)" "-" "-"
            break
        elif [ $estado -eq 0 ]; then
            tiempo=$(grep "Search time" salida_tmp.log | grep -oE '[0-9]+\.[0-9]+' | head -1)
            pasos=$(grep "Plan length" salida_tmp.log | grep -oE '[0-9]+' | tail -1)
            
            if [ -z "$tiempo" ]; then tiempo="N/A"; fi
            if [ -z "$pasos" ]; then pasos="N/A"; fi

            printf "%-12s | %-10s | %-10s\n" "${tiempo}s" "$pasos" "$optimo"
        else
            printf "%-12s | %-10s | %-10s\n" "ERROR" "-" "-"
            echo "--- ERROR EN: $alg_name (Tamaño $size) ---" >> errores_pyperplan.log
            cat salida_tmp.log >> errores_pyperplan.log
            echo -e "\n" >> errores_pyperplan.log
            break
        fi
    done
}

# --- PARTE 1.3.1 ---
probar "bfs" "none"
probar "ids" "none"
probar "astar" "hmax"
probar "gbf" "hmax"

echo ""
echo ">>> PARTE 1.3.2: Satisficing (Fijado al tamaño 5 para comparar)"
for alg in "gbf" "ehs"; do
    for h in "hmax" "hadd" "hff" "landmark"; do
        optimo=$(es_optimo $alg $h)
        
        alg_name_display=$alg
        if [ "$alg" == "gbf" ]; then alg_name_display="gbfs"; fi
        if [ "$alg" == "ehs" ]; then alg_name_display="ehc"; fi
        alg_name="${alg_name_display} + ${h}"
        
        file="drone_problem_d1_r0_l7_p7_c7_g7_ct2.pddl"
        
        printf "%-18s | %-12s | " "$alg_name" "7"
        
        timeout 60s pyperplan -s $alg -H $h domain2_1_no_cost.pddl $file > salida_tmp.log 2>&1
        estado=$?
        
        if [ $estado -eq 124 ]; then
            printf "%-12s | %-10s | %-10s\n" "> 60s (TO)" "-" "$optimo"
        elif [ $estado -eq 0 ]; then
            tiempo=$(grep "Search time" salida_tmp.log | grep -oE '[0-9]+\.[0-9]+' | head -1)
            pasos=$(grep "Plan length" salida_tmp.log | grep -oE '[0-9]+' | tail -1)
            printf "%-12s | %-10s | %-10s\n" "${tiempo}s" "$pasos" "$optimo"
        else
            printf "%-12s | %-10s | %-10s\n" "ERROR" "-" "-"
        fi
    done
done
echo ""

# --- PARTE 1.3.3 ---
echo ">>> PARTE 1.3.3: Óptimos (A* con heurísticas admisibles)"
probar "astar" "hmax"
probar "astar" "lmcut"

rm -f salida_tmp.log