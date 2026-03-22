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

echo "Sistema de prueba con incremento progresivo hasta timeout..."
echo "Tu planificador se probará con tamaños crecientes hasta que tome >60 segundos"
echo "========================================"
echo ""

# Tracking de qué planificadores han hecho timeout
declare -A PLANNER_TIMED_OUT=(
    ["metric-ff"]=0
    ["fd-lama"]=0
    ["fd-sat-fdss2"]=0
    ["fd-sat-autotune2"]=0
    ["fd-opt-lmcut"]=0
    ["fd-opt-bjolp"]=0
    ["fd-opt-fdss2"]=0
)

# Función para extraer coste del output
extract_cost() {
    echo "$1" | grep -oP 'total cost|cost: \K[0-9]+|Plan cost: \K[0-9]+' | head -1
}

# Función para extraer tiempo
extract_time() {
    echo "$1" | grep -oP 'Time: \K[0-9.]+|time: \K[0-9.]+' | head -1
}

# Función para contar cuántos planificadores aún no han hecho timeout
all_timed_out() {
    for val in "${PLANNER_TIMED_OUT[@]}"; do
        if [ "$val" -eq 0 ]; then
            return 1  # Al menos uno no ha hecho timeout
        fi
    done
    return 0  # Todos han hecho timeout
}

# Parámetros iniciales de tamaño
# "Tamaño" se refiere a personas, cajas, localizaciones y metas con el mismo valor
# Tamaño 1 = 1 persona, 1 caja, 1 localización, 1 meta
# Tamaño 2 = 2 personas, 2 cajas, 2 localizaciones, 2 metas, etc.
DRONES=1
TRANSPORTERS=1
SIZE=1  # Variable de tamaño principal

echo ""
echo "Ejecutando pruebas con incremento progresivo hasta timeout..."
echo "Tamaño = número de personas = número de cajas = número de localizaciones = número de metas"
echo "========================================"
echo ""

# Bucle principal: continuar hasta que todos los planificadores hagan timeout
while ! all_timed_out; do
    SIZE=$((SIZE + 1))
    # Los parámetros de tamaño se incrementan juntos
    LOCATIONS=$SIZE
    PERSONS=$SIZE
    CRATES=$SIZE
    GOALS=$SIZE
    PROBLEM="drone_problem_d${DRONES}_r${TRANSPORTERS}_l${LOCATIONS}_p${PERSONS}_c${CRATES}_g${GOALS}_ct2.pddl"
    
    echo "Generando problema Tamaño $SIZE: d=$DRONES r=$TRANSPORTERS l=$LOCATIONS p=$PERSONS c=$CRATES g=$GOALS..."
    python3 generador_problemas2.py -d "$DRONES" -r "$TRANSPORTERS" -l "$LOCATIONS" -p "$PERSONS" -c "$CRATES" -g "$GOALS" > /dev/null 2>&1
    
    if [ ! -f "$PROBLEM" ]; then
        echo "Error: no se pudo generar el problema $PROBLEM"
        break
    fi
    
    echo "Pruebas para Tamaño $SIZE: $PROBLEM"
    
    # Metric-FF
    if [ ${PLANNER_TIMED_OUT["metric-ff"]} -eq 0 ]; then
        echo -n "  Metric-FF... " >&2
        START=$(date +%s.%N)
        OUTPUT=$(timeout $TIMEOUT planutils run metric-ff "$DOMAIN" "$PROBLEM" 2>&1)
        EXITCODE=$?
        END=$(date +%s.%N)
        TIME=$(echo "$END - $START" | bc)
        
        if [ $EXITCODE -eq 0 ]; then
            COST=$(extract_cost "$OUTPUT")
            echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
            echo "metric-ff,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
        else
            echo "TIMEOUT" >&2
            echo "metric-ff,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
            PLANNER_TIMED_OUT["metric-ff"]=1
        fi
    fi
    
    # Fastdownward lama-first
    if [ ${PLANNER_TIMED_OUT["fd-lama"]} -eq 0 ]; then
        echo -n "  Fastdownward (lama-first)... " >&2
        START=$(date +%s.%N)
        OUTPUT=$(timeout $((TIMEOUT+5)) planutils run downward -- --alias lama-first --overall-time-limit $TIMEOUT "$DOMAIN" "$PROBLEM" 2>&1)
        EXITCODE=$?
        END=$(date +%s.%N)
        TIME=$(echo "$END - $START" | bc)
        
        if [ $EXITCODE -eq 0 ] && echo "$OUTPUT" | grep -q "Solution found"; then
            COST=$(extract_cost "$OUTPUT")
            echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
            echo "fd-lama,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
        else
            echo "TIMEOUT" >&2
            echo "fd-lama,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
            PLANNER_TIMED_OUT["fd-lama"]=1
        fi
    fi
    
    # Fastdownward seq-sat-fdss-2
    if [ ${PLANNER_TIMED_OUT["fd-sat-fdss2"]} -eq 0 ]; then
        echo -n "  Fastdownward (seq-sat-fdss-2)... " >&2
        START=$(date +%s.%N)
        OUTPUT=$(timeout $((TIMEOUT+5)) planutils run downward -- --alias seq-sat-fdss-2 --overall-time-limit $TIMEOUT "$DOMAIN" "$PROBLEM" 2>&1)
        EXITCODE=$?
        END=$(date +%s.%N)
        TIME=$(echo "$END - $START" | bc)
        
        if [ $EXITCODE -eq 0 ] && echo "$OUTPUT" | grep -q "Solution found"; then
            COST=$(extract_cost "$OUTPUT")
            echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
            echo "fd-sat-fdss2,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
        else
            echo "TIMEOUT" >&2
            echo "fd-sat-fdss2,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
            PLANNER_TIMED_OUT["fd-sat-fdss2"]=1
        fi
    fi
    
    # Fastdownward seq-sat-fd-autotune-2
    if [ ${PLANNER_TIMED_OUT["fd-sat-autotune2"]} -eq 0 ]; then
        echo -n "  Fastdownward (seq-sat-fd-autotune-2)... " >&2
        START=$(date +%s.%N)
        OUTPUT=$(timeout $((TIMEOUT+5)) planutils run downward -- --alias seq-sat-fd-autotune-2 --overall-time-limit $TIMEOUT "$DOMAIN" "$PROBLEM" 2>&1)
        EXITCODE=$?
        END=$(date +%s.%N)
        TIME=$(echo "$END - $START" | bc)
        
        if [ $EXITCODE -eq 0 ] && echo "$OUTPUT" | grep -q "Solution found"; then
            COST=$(extract_cost "$OUTPUT")
            echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
            echo "fd-sat-autotune2,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
        else
            echo "TIMEOUT" >&2
            echo "fd-sat-autotune2,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
            PLANNER_TIMED_OUT["fd-sat-autotune2"]=1
        fi
    fi
    
    # Fastdownward seq-opt-lmcut
    if [ ${PLANNER_TIMED_OUT["fd-opt-lmcut"]} -eq 0 ]; then
        echo -n "  Fastdownward (seq-opt-lmcut)... " >&2
        START=$(date +%s.%N)
        OUTPUT=$(timeout $((TIMEOUT+5)) planutils run downward -- --alias seq-opt-lmcut --overall-time-limit $TIMEOUT "$DOMAIN" "$PROBLEM" 2>&1)
        EXITCODE=$?
        END=$(date +%s.%N)
        TIME=$(echo "$END - $START" | bc)
        
        if [ $EXITCODE -eq 0 ] && echo "$OUTPUT" | grep -q "Solution found"; then
            COST=$(extract_cost "$OUTPUT")
            echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
            echo "fd-opt-lmcut,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
        else
            echo "TIMEOUT" >&2
            echo "fd-opt-lmcut,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
            PLANNER_TIMED_OUT["fd-opt-lmcut"]=1
        fi
    fi
    
    # Fastdownward seq-opt-bjolp
    if [ ${PLANNER_TIMED_OUT["fd-opt-bjolp"]} -eq 0 ]; then
        echo -n "  Fastdownward (seq-opt-bjolp)... " >&2
        START=$(date +%s.%N)
        OUTPUT=$(timeout $((TIMEOUT+5)) planutils run downward -- --alias seq-opt-bjolp --overall-time-limit $TIMEOUT "$DOMAIN" "$PROBLEM" 2>&1)
        EXITCODE=$?
        END=$(date +%s.%N)
        TIME=$(echo "$END - $START" | bc)
        
        if [ $EXITCODE -eq 0 ] && echo "$OUTPUT" | grep -q "Solution found"; then
            COST=$(extract_cost "$OUTPUT")
            echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
            echo "fd-opt-bjolp,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
        else
            echo "TIMEOUT" >&2
            echo "fd-opt-bjolp,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
            PLANNER_TIMED_OUT["fd-opt-bjolp"]=1
        fi
    fi
    
    # Fastdownward seq-opt-fdss2
    if [ ${PLANNER_TIMED_OUT["fd-opt-fdss2"]} -eq 0 ]; then
        echo -n "  Fastdownward (seq-opt-fdss2)... " >&2
        START=$(date +%s.%N)
        OUTPUT=$(timeout $((TIMEOUT+5)) planutils run downward -- --alias seq-opt-fdss2 --overall-time-limit $TIMEOUT "$DOMAIN" "$PROBLEM" 2>&1)
        EXITCODE=$?
        END=$(date +%s.%N)
        TIME=$(echo "$END - $START" | bc)
        
        if [ $EXITCODE -eq 0 ] && echo "$OUTPUT" | grep -q "Solution found"; then
            COST=$(extract_cost "$OUTPUT")
            echo "OK (coste: $COST, tiempo: ${TIME}s)" >&2
            echo "fd-opt-fdss2,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,Sí,$TIME,$COST" >> "$OUTPUT_FILE"
        else
            echo "TIMEOUT" >&2
            echo "fd-opt-fdss2,$SIZE,$DRONES,$TRANSPORTERS,$LOCATIONS,$PERSONS,$CRATES,$GOALS,No,${TIMEOUT},-" >> "$OUTPUT_FILE"
            PLANNER_TIMED_OUT["fd-opt-fdss2"]=1
        fi
    fi
    
    echo ""
    
done

echo ""
echo "Resultados guardados en: $OUTPUT_FILE"
echo ""
echo "Tabla de resultados:"
column -t -s',' "$OUTPUT_FILE"
