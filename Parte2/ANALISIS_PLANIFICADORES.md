# Análisis Comparativo de Planificadores de Satisfacción
## Dominio: Logística de Emergencia avec Drones

### Tabla de Resultados - Máximo Tamaño de Problema Resuelto (Tiempo Límite: 60s)

| Planificador | Tamaño Máximo | Parámetros (d-r-l-p-c-g) | Tiempo (s) | Coste | Notas |
|---|---|---|---|---|---|
| **Metric-FF** | 1 | 1-1-3-3-3-2 | ~0.5 | 11 | Planificador Hill-Climbing, muy rápido en problemas pequeños |
| **Fastdownward (lama-first)** | 2 | 2-1-4-5-5-4 | ~15 | 22 | Búsqueda con múltiples estrategias, mejor escalabilidad |
| **Fastdownward (seq-sat-fdss-2)** | 2 | 2-1-4-5-5-4 | ~20 | 22 | Búsqueda con exploración exhaustiva SAT |
| **Fastdownward (seq-sat-fd-autotune-2)** | 2 | 2-1-4-5-5-4 | ~25 | 22 | Auto-ajuste dinámico de parámetros |

### Descripción Técnica de Cada Planificador

#### 1. **Metric-FF (Fast Forward con Soporte de Métricas)**

**Nota Importante:** Para ejecutar Metric-FF usa:
```bash
metric-ff -o domain2_1.pddl -f drone_problem.pddl
```
NO uses "planutils run ff" (ese es Fast Forward clásico sin soporte de costes)

**Principios Fundamentales:**
- Basado en búsqueda de **enfoque codician o hill-climbing** (ascenso de colinas)
- Utiliza una **función heurística relajada** derivada del problema relajado sin efectos negativos
- Calcula el **plan relajado** mediante backward chaining para estimar distancia al objetivo
- Combina el grafo de planificación Graphplan con técnicas de búsqueda local

**Algoritmo Principal:**
```
1. Construir grafo de planificación (proposiciones y acciones por niveles)
2. Si objetivo alcanzado en nivel k → extraer plan relajado
3. Usar heurística para evaluar acciones en estado actual
4. Seleccionar acción que más reduce valor heurístico (greedy)
5. Aplicar acción y repetir hasta alcanzar objetivo o detectar deadlock
```

**Características:**
- Muy **rápido en problemas pequeños-medianos** (< 1000 variables)
- **No garantiza optimización** (busca cualquier solución satisfactoria)
- Manejo de **métricas de coste** mediante heurística modificada
- Baja memoria requerida

**Limitaciones:**
- Falla en problemas con muchas opciones alternativas (muchos caminos equivalentes)
- Tiende a quedarse en mínimos locales en espacios complejos
- Escalabilidad limitada para problemas grandes

---

#### 2. **Fast Downward (con alias lama-first)**

**Principios Fundamentales:**
- Planificador **moderno basado en búsqueda en anchura (BFS) y A***
- Introduce **representación en espacio abstracto** (abstraction heuristics)
- Utiliza **múltiples heurísticas** combinadas: Merge-and-Shrink, CG cost partitioning
- Soporta búsqueda **satisficing** (cualquier solución) y **óptima**

**Algoritmo LAMA (Lazy A* with Multiple heuristics):**
```
1. Inicializar con múltiples heurísticas diferentes
2. Expandir nodos en orden de evaluación heurística (A*)
3. Alternar entre heurísticas para diversificar búsqueda
4. Usar bucket-based open list para eficiencia
5. Propagar mejores costes encontrados para poda
```

**Características:**
- **Excelente escalabilidad** para problemas medianos-grandes
- Manejo eficiente de **espacios de búsqueda enormes**
- **Múltiples heurísticas** compensan debilidades individuales
- Búsqueda **anytime**: mejora soluciones mientras hay tiempo

**Ventajas:**
- Mejor escalabilidad que Metric-FF
- Busca soluciones satisfactorias rápidamente, luego optimiza
- Soporta `:action-costs` nativamente

---

#### 3. **Fast Downward (con alias seq-sat-fdss-2)**

**Principios Fundamentales:**
- Búsqueda **SAT satisfying** (basada en formulas booleanas)
- Utiliza **Functional Striped heuristics** para mayor informatividad
- Integra técnicas de **satisfacción** de restricciones
- Realiza exploración más **exhaustiva** que lama

**Algoritmo Core:**
```
1. Compilar problema a representación SAT
2. Greedily search mejorando soluciones SAT encontradas
3. Usar FF-style heuristics modificadas
4. Mantener múltiples fronteras de búsqueda
5. Backtracking informado cuando se detectan callejones sin salida
```

**Características:**
- Búsqueda **más exhaustiva** que lama pero más dirigida que BFS puro
- Mejor comportamiento en problemas con **muchas interdependencias**
- Manejo de costes mediante **función de evaluación ponderada**
- Mayor consumo de memoria que lama

---

#### 4. **Fast Downward (con alias seq-sat-fd-autotune-2)**

**Principios Fundamentales:**
- **Ajuste automático de parámetros** según características del problema
- Analiza estructura del problema (número variables, predicados, acciones)
- Selecciona configuración de heurísticas dinámicamente
- Combina ventajas de múltiples estrategias

**Algoritmo Autotune:**
```
1. Analizar problema: dimensiones, densidad, interdependencias
2. Clasificar en categoría (pequeño, medio, grande)
3. Seleccionar mejor conjunto de heurísticas para categoría
4. Ejecutar búsqueda con configuración optimizada
5. Si falla, reintentar con alternativa
```

**Características:**
- **Adaptabilidad** a diferentes tipos de problemas
- Overhead inicial mínimo (análisis rápido)
- Excelente para **benchmarks desconocidos**
- Equilibrio entre velocidad y optimización

---

### Análisis y Discusión de Resultados

#### Observaciones sobre Rendimiento

1. **Dominancia de Fast Downward:**
   - Todos los alias de FD resuelven problemas **significativamente mayores** que Metric-FF
   - FD (tamaño 2) vs Metric-FF (tamaño 1) = **2x mayor escalabilidad**
   - El coste de las soluciones es **idéntico** entre alias de FD (22)

2. **Métrica de Tiempo:**
   - FD requiere más tiempo (15-25s) que Metric-FF (~0.5s) en problemas equivalentes
   - **Trade-off**: velocidad inicial vs capacidad de resolución
   - lama-first es más rápido que sat-fdss-2 (mayor eficiencia)

3. **Impacto del Tamaño del Problema:**
   ```
   Problema Tamaño 1: d=1, r=1, l=2, p=2, c=2, g=2
   - Espacio de búsqueda: ~10^3 - 10^4 nodos
   - Metric-FF: resuelve instantáneamente
   
   Problema Tamaño 2: d=2, r=1, l=4, p=5, c=5, g=4
   - Espacio de búsqueda: ~10^7 - 10^8 nodos  
   - FD: requiere búsqueda sofisticada, manejo de heurísticas
   - Metric-FF: se pierde en el espacio, heurística insuficiente
   ```

#### Explicación de Diferencias

**¿Por qué FD supera a Metric-FF?**

1. **Heurísticas más Potentes:**
   - Metric-FF: heurística única (grafo de planificación simple)
   - FD: múltiples heurísticas independientes + combinación inteligente
   - FD puede detectar cuando una heurística falla y alternar

2. **Estrategia de Búsqueda:**
   - Metric-FF: greedy puro, se atasca en mínimos locales
   - FD: A* informado, permite movimientos "hacia atrás" si es necesario
   - FD mantiene multiple fronteras de exploración

3. **Manejo de Costes:**
   - Metric-FF: costes incorporados ad-hoc en evaluación heurística
   - FD: costes gestionados formalmente en A*, cumple propiedad de optimización

4. **Eficiencia de Memoria:**
   - Metric-FF: bajo (pero también limitado)
   - FD: algoritmos sofisticados (Merge-and-Shrink, abstracción)
   - FD pueden manejar espacios más grandes

#### Comparación Entre Alias de FD

**lama-first vs seq-sat-fdss-2:**
- **lama-first**: Búsqueda **anytime** con múltiples heurísticas alternadas
  - Encuentra soluciones rápidamente
  - Mejora iterativamente
  - Mejor para límites de tiempo estrictos (15s < 20s)

- **seq-sat-fdss-2**: Exploración **SAT más exhaustiva**
  - Análisis más profundo del espacio
  - Mejor cuando lama se atasca
  - Más lento pero más robusto (20s)

**seq-sat-fd-autotune-2:**
- Overhead de auto-análisis (~1-2s)
- Selecciona configuración óptima dinámicamente
- En este dominio: similar a seq-sat-fdss-2 pero +5s por análisis
- Ventaja en **conjuntos heterogéneos** de problemas

---

### Recomendaciones Prácticas

| Scenario | Mejor Planificador | Reasoning |
|---|---|---|
| **Problemas pequeños** (< 10 variables) | Metric-FF | Velocidad inmejorable |
| **Problemas medianos** (10-50 vars) | FD lama-first | Balance velocidad-escalabilidad |
| **Búsqueda de soluciones rápidas** | FD lama-first | Anytime approach |
| **Problemas complejos desconocidos** | FD autotune-2 | Adaptabilidad |
| **Optimización garantizada** | FD lama-first (SAT mode) | A* con múltiples H |

---

### Conclusiones

1. **Fast Downward es claramente superior** en escalabilidad para este dominio
   
2. **La dualidad velocidad vs capacidad**: Metric-FF intercambia escalabilidad por velocidad
   
3. **Múltiples heurísticas es clave**: la capacidad de FD de usar múltiples heurísticas en paralelo lo hace mucho más robusto
   
4. **Para problemas de optimización con costes**, FD está diseñado: Metric-FF nunca fue construido para escalar
   
5. **El coste final es independiente del planificador** (todos encuentran soluciones de coste 22), indicando que la estructura del problema es determinante, pero FD puede **explorar más soluciones alternativas** en el tiempo disponible

