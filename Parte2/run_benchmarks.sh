#!/bin/bash
# Script para probar planificadores en diferentes tamaños de problema
# Crea tabla CSV con resultados

DOMAIN="domain2_1.pddl"
TIMEOUT=60
OUTPUT_FILE="resultados_planificadores.csv"

# Crear archivo CSV con encabezado
cat > "$OUTPUT_FILE" << EOF
Planificador,Tamaño,Drones,Transporters,Locations,Persons,Crates,Goals,Resuelto,Tiempo(s),Coste
EOF

echo "Generando problemas de prueba..."

# Tamaños de problema: drones, transporters, locations, persons, crates, goals
declare -a SIZES=(
    "1 1 2 2 2 2"
    "1 1 3 3 3 2"  
    "1 1 4 4 4 3"
    "2 1 3 4 4 3"
    "2 1 4 5 5 4"
)

# Generar problemas
for i in "${!SIZES[@]}"; do
    read d r l p c g <<< "${SIZES[$i]}"
    echo "Generando problema $((i+1)): d=$d r=$r l=$l p=$p c=$c g=$g"
    python3 generador_problemas2.py -d "$d" -r "$r" -l "$l" -p "$p" -c "$c" -g "$g" > /dev/null 2>&1
done

echo ""
echo "Ejecutando planificadores..."
echo "========================================"

# Función para extraer coste del output
extract_cost() {
    echo "$1" | grep -oP 'total cost|cost: \K[0-9]+|Plan length: \K[0-9]+' | head -1
}

# Función para extraer tiempo
extract_time() {
    echo "$1" | grep -oP 'Time: \K[0-9.]+|time: \K[0-9.]+' | head -1
}

# Probar cada tamaño con cada planificador
for i in "${!SIZES[@]}"; do
    read d r l p c g <<< "${SIZES[$i]}"
    PROBLEM="drone_problem_d${d}_r${r}_l${l}_p${p}_c${c}_g${g}_ct2.pddl"
    
    if [ ! -f "$PROBLEM" ]; then
        echo "Problema no encontrado: $PROBLEM"
        continue
    fi
    
    SIZE=$((i+1))
    echo "Tamaño $SIZE: $PROBLEM"
    
    # Metric-FF
    echo -n "  Metric-FF... " >&2
    START=$(date +%s.%N)
    OUTPUT=$(timeout $TIMEOUT metric-ff -o "$DOMAIN" -f "$PROBLEM" 2>&1)
    EXITCODE=$?
    END=$(date +%s.%N)
    TIME=$(echo "$END - $START" | bc)
    
    if [ $EXITCODE -eq 0 ]; then
        COST=$(extract_cost "$OUTPUT")
        echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
        echo "metric-ff,$SIZE,$d,$r,$l,$p,$c,$g,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
    else
        echo "TIMEOUT" >&2
        echo "metric-ff,$SIZE,$d,$r,$l,$p,$c,$g,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
    fi
    
    # Fastdownward lama-first
    echo -n "  Fastdownward (lama-first)... " >&2
    START=$(date +%s.%N)
    OUTPUT=$(timeout $((TIMEOUT+5)) planutils run downward -- --alias lama-first --overall-time-limit $TIMEOUT "$DOMAIN" "$PROBLEM" 2>&1)
    EXITCODE=$?
    END=$(date +%s.%N)
    TIME=$(echo "$END - $START" | bc)
    
    if [ $EXITCODE -eq 0 ] && echo "$OUTPUT" | grep -q "Solution found"; then
        COST=$(extract_cost "$OUTPUT")
        echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
        echo "fd-lama,$SIZE,$d,$r,$l,$p,$c,$g,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
    else
        echo "NO" >&2
        echo "fd-lama,$SIZE,$d,$r,$l,$p,$c,$g,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
    fi
    
    # Fastdownward seq-sat-fdss-2
    echo -n "  Fastdownward (seq-sat-fdss-2)... " >&2
    START=$(date +%s.%N)
    OUTPUT=$(timeout $((TIMEOUT+5)) planutils run downward -- --alias seq-sat-fdss-2 --overall-time-limit $TIMEOUT "$DOMAIN" "$PROBLEM" 2>&1)
    EXITCODE=$?
    END=$(date +%s.%N)
    TIME=$(echo "$END - $START" | bc)
    
    if [ $EXITCODE -eq 0 ] && echo "$OUTPUT" | grep -q "Solution found"; then
        COST=$(extract_cost "$OUTPUT")
        echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
        echo "fd-sat-fdss2,$SIZE,$d,$r,$l,$p,$c,$g,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
    else
        echo "NO" >&2
        echo "fd-sat-fdss2,$SIZE,$d,$r,$l,$p,$c,$g,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
    fi
    
    # Fastdownward seq-sat-fd-autotune-2
    echo -n "  Fastdownward (seq-sat-fd-autotune-2)... " >&2
    START=$(date +%s.%N)
    OUTPUT=$(timeout $((TIMEOUT+5)) planutils run downward -- --alias seq-sat-fd-autotune-2 --overall-time-limit $TIMEOUT "$DOMAIN" "$PROBLEM" 2>&1)
    EXITCODE=$?
    END=$(date +%s.%N)
    TIME=$(echo "$END - $START" | bc)
    
    if [ $EXITCODE -eq 0 ] && echo "$OUTPUT" | grep -q "Solution found"; then
        COST=$(extract_cost "$OUTPUT")
        echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
        echo "fd-sat-autotune2,$SIZE,$d,$r,$l,$p,$c,$g,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
    else
        echo "NO" >&2
        echo "fd-sat-autotune2,$SIZE,$d,$r,$l,$p,$c,$g,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
    fi
    
done

echo ""
echo "Resultados guardados en: $OUTPUT_FILE"
echo ""
echo "Tabla de resultados:"
column -t -s',' "$OUTPUT_FILE"
