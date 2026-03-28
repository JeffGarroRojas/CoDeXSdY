import 'models/question.dart';

class MEPQuestionBank {
  static List<Question> getQuestions(int subjectIndex, int levelIndex) {
    switch (subjectIndex) {
      case 0:
        return _mathQuestions[levelIndex] ?? [];
      case 1:
        return _scienceQuestions[levelIndex] ?? [];
      case 2:
        return _socialQuestions[levelIndex] ?? [];
      case 3:
        return _spanishQuestions[levelIndex] ?? [];
      case 4:
        return _civicaQuestions[levelIndex] ?? [];
      default:
        return [];
    }
  }

  // MATEMÁTICAS - Resolución de problemas, Números, Geometría, Medidas, Relaciones, Álgebra, Estadística
  static final Map<int, List<Question>> _mathQuestions = {
    0: [
      // 10° Año
      _q(
        '¿Cuál es el resultado de resolver la ecuación 2x + 5 = 15?',
        ['x = 5', 'x = 10', 'x = 7', 'x = 4'],
        0,
        '2x = 15 - 5 → 2x = 10 → x = 5',
        'Álgebra - Ecuaciones lineales',
      ),
      _q(
        '¿Cuánto mide la suma de los ángulos internos de un triángulo?',
        ['90°', '180°', '360°', '270°'],
        1,
        'Por el teorema de la suma de ángulos internos, todo triángulo suma 180°.',
        'Geometría',
      ),
      _q(
        '¿Qué es la mediana en un conjunto de datos?',
        [
          'El valor máximo',
          'El valor mínimo',
          'El valor central cuando se ordena',
          'El promedio',
        ],
        2,
        'La mediana es el valor que queda exactamente en el centro al ordenar los datos.',
        'Estadística',
      ),
      _q(
        'Si un cuadrado tiene lado de 8 cm, ¿cuál es su perímetro?',
        ['64 cm', '32 cm', '16 cm', '24 cm'],
        1,
        'Perímetro = 4 × lado = 4 × 8 = 32 cm',
        'Geometría - Perímetro',
      ),
      _q(
        '¿Cuál es el resultado de √144?',
        ['11', '12', '13', '14'],
        1,
        '√144 = 12 porque 12 × 12 = 144',
        'Números - Raíces cuadradas',
      ),
      _q(
        '¿Qué tipo de número es π (pi)?',
        [
          'Número natural',
          'Número entero',
          'Número irracional',
          'Número racional',
        ],
        2,
        'π no puede expresarse como fracción de dos enteros, por lo tanto es irracional.',
        'Números',
      ),
      _q(
        'Si un auto viaja a 60 km/h durante 2 horas, ¿qué distancia recorre?',
        ['30 km', '120 km', '90 km', '60 km'],
        1,
        'Distancia = velocidad × tiempo = 60 × 2 = 120 km',
        'Medidas - Velocidad',
      ),
      _q(
        '¿Cuál es el área de un círculo con radio de 5 cm? (usa π = 3.14)',
        ['78.5 cm²', '31.4 cm²', '15.7 cm²', '25 cm²'],
        0,
        'Área = π × r² = 3.14 × 25 = 78.5 cm²',
        'Geometría - Área del círculo',
      ),
      _q(
        '¿Qué porcentaje representa 25 de 200?',
        ['12.5%', '25%', '50%', '5%'],
        0,
        '25/200 × 100 = 12.5%',
        'Números - Porcentajes',
      ),
      _q(
        '¿Cuál es el mínimo común múltiplo de 6 y 8?',
        ['24', '48', '12', '16'],
        0,
        'MCM(6,8) = 24 (6×4 = 24, 8×3 = 24)',
        'Números - MCM',
      ),
    ],
    1: [
      // 11° Año
      _q(
        '¿Cuál es la derivada de f(x) = x³?',
        ['x²', '3x²', '3x³', 'x⁴/4'],
        1,
        'Usando la regla de la potencia: d/dx(xⁿ) = n·xⁿ⁻¹, entonces d/dx(x³) = 3x²',
        'Álgebra - Derivadas',
      ),
      _q(
        '¿Qué es una función cuadrática?',
        [
          'f(x) = mx + b',
          'f(x) = ax² + bx + c, donde a ≠ 0',
          'f(x) = k',
          'f(x) = √x',
        ],
        1,
        'La función cuadrática tiene la forma general f(x) = ax² + bx + c.',
        'Álgebra - Funciones',
      ),
      _q(
        '¿Cuál es el teorema de Pitágoras?',
        ['a + b = c', 'a² + b² = c²', 'a × b = c', 'a/b = c'],
        1,
        'En un triángulo rectángulo: a² + b² = c², donde c es la hipotenusa.',
        'Geometría - Teorema de Pitágoras',
      ),
      _q(
        '¿Qué es el teorema del residuo?',
        [
          'Permite dividir polinomios',
          'Da el residuo al evaluar un polinomio',
          'Factoriza binomios',
          'Resuelve ecuaciones',
        ],
        1,
        'El teorema del residuo dice que P(a) es el residuo de dividir P(x) entre (x-a).',
        'Álgebra - Polinomios',
      ),
      _q(
        '¿Cuál es la solución de log₂(8)?',
        ['2', '3', '4', '8'],
        1,
        'log₂(8) = 3 porque 2³ = 8',
        'Álgebra - Logaritmos',
      ),
      _q(
        '¿Qué representa la pendiente de una recta?',
        [
          'El ángulo con el eje X',
          'El cambio en y dividido el cambio en x',
          'La distancia al origen',
          'El punto medio',
        ],
        1,
        'La pendiente m = (y₂ - y₁)/(x₂ - x₁) representa la inclinación de la recta.',
        'Relaciones - Funciones lineales',
      ),
      _q(
        '¿Cuál es la fórmula del área de un triángulo?',
        ['L × L', 'π × r²', '(b × h) / 2', '2πr'],
        2,
        'El área del triángulo es base por altura dividido entre 2.',
        'Geometría - Área',
      ),
      _q(
        '¿Qué es una progresión geométrica?',
        [
          'Sucesión con diferencia constante',
          'Sucesión donde cada término se multiplica por una constante',
          'Sucesión de números primos',
          'Sucesión alternada',
        ],
        1,
        'En una progresión geométrica, cada término se obtiene multiplicando el anterior por una razón constante.',
        'Relaciones - Sucesiones',
      ),
    ],
    2: [
      // 12° Año
      _q(
        '¿Cuál es la integral de 2x dx?',
        ['x² + C', 'x + C', '2x² + C', 'x²/2 + C'],
        0,
        '∫2x dx = 2(x²/2) + C = x² + C',
        'Álgebra - Integrales',
      ),
      _q(
        '¿Qué es el límite de una función?',
        [
          'El valor máximo',
          'El valor que toma la función cuando x se acerca a un valor',
          'La pendiente',
          'La derivada',
        ],
        1,
        'El límite describe el comportamiento de f(x) cuando x se aproxima a un valor específico.',
        'Álgebra - Límites',
      ),
      _q(
        '¿Cuál es la derivada de sen(x)?',
        ['cos(x)', '-cos(x)', 'sen(x)', 'tan(x)'],
        0,
        'La derivada de sen(x) es cos(x).',
        'Álgebra - Derivadas trigonométricas',
      ),
      _q(
        '¿Qué representa la segunda derivada?',
        [
          'La pendiente de la función',
          'La tasa de cambio de la primera derivada',
          'El área bajo la curva',
          'El punto máximo',
        ],
        1,
        'La segunda derivada indica si la pendiente está aumentando o disminuyendo (concavidad).',
        'Álgebra - Análisis de funciones',
      ),
      _q(
        '¿Qué es una matriz identidad?',
        [
          'Matriz de ceros',
          'Matriz con 1 en la diagonal y 0 en demás',
          'Matriz cuadrada',
          'Matriz transpuesta',
        ],
        1,
        'La identidad tiene 1s en la diagonal principal y 0s en el resto. Iₙ.',
        'Álgebra - Matrices',
      ),
    ],
  };

  // CIENCIAS - Biología, Física, Química (16 bloques del MEP)
  static final Map<int, List<Question>> _scienceQuestions = {
    0: [
      // 10° Año
      _q(
        '¿Qué es la fotosíntesis?',
        [
          'Respiración celular',
          'Proceso donde las plantas producen glucosa usando luz solar',
          'Digestión de alimentos',
          'Circulación de la sangre',
        ],
        1,
        'La fotosíntesis convierte CO₂ + H₂O + luz solar → glucosa + O₂',
        'Biología - Fotosíntesis',
      ),
      _q(
        '¿Cuál es la unidad básica de la vida?',
        ['El átomo', 'La célula', 'El órgano', 'El tejido'],
        1,
        'La célula es la unidad fundamental de todo ser vivo.',
        'Biología - Célula',
      ),
      _q(
        '¿Qué son los átomos?',
        [
          'Partículas muy pequeñas que forman todo',
          'Células especializadas',
          'Moléculas simples',
          'Tejidos del cuerpo',
        ],
        0,
        'Los átomos son las partículas más pequeñas de la materia que conservan las propiedades de un elemento.',
        'Química - Átomo',
      ),
      _q(
        '¿Qué es la densidad?',
        [
          'Masa por volumen',
          'Masa / Volumen',
          'Peso / Volumen',
          'Volumen / Masa',
        ],
        1,
        'Densidad = Masa / Volumen. Indica cuánta masa hay en un volumen dado.',
        'Física - Densidad',
      ),
      _q(
        '¿Qué son los生态系统?',
        [
          'Grupos de células similares',
          'Comunidades de seres vivos + ambiente físico',
          'Órganos del cuerpo',
          'Tipos de clima',
        ],
        1,
        'Un ecosistema incluye los seres vivos (comunidad biológica) y el ambiente físico (biotopo).',
        'Biología - Ecosistemas',
      ),
      _q(
        '¿Qué es la mitosis?',
        [
          'Tipo de respiración',
          'División celular que produce células idénticas',
          'Fusión de células',
          'Producción de energía',
        ],
        1,
        'La mitosis es la división celular que produce dos células hijas genéticamente idénticas a la madre.',
        'Biología - División celular',
      ),
      _q(
        '¿Qué establece la Ley de Newton de la inercia?',
        [
          'Todo cuerpo permanece en reposo o movimiento uniforme',
          'F = ma',
          'A toda acción corresponde una reacción igual',
          'La gravedad afecta a todos los cuerpos',
        ],
        0,
        'Primera Ley de Newton: Un objeto en reposo permanece en reposo, y uno en movimiento permanece en movimiento uniforme, a menos que actúe una fuerza externa.',
        'Física - Leyes de Newton',
      ),
      _q(
        '¿Qué es la materia?',
        [
          'Todo lo que ocupa espacio y tiene masa',
          'Solo lo que podemos ver',
          'La energía del universo',
          'El espacio vacío',
        ],
        0,
        'La materia es todo lo que tiene masa y ocupa un lugar en el espacio.',
        'Química - Materia',
      ),
      _q(
        '¿Cuáles son los estados de la materia?',
        [
          'Sólido, líquido y gaseoso',
          'Caliente, frío y tibio',
          'Grande, pequeño y mediano',
          'Viejo, nuevo y antiguo',
        ],
        0,
        'Los tres estados fundamentales son: sólido, líquido y gaseoso. El plasma es un cuarto estado.',
        'Química - Estados de la materia',
      ),
      _q(
        '¿Qué es el ADN?',
        [
          'Ácido que contiene la información genética',
          'Una proteína muscular',
          'Un tipo de célula',
          'Un órgano del cuerpo',
        ],
        0,
        'El ADN (ácido desoxirribonucleico) almacena y transmite la información genética.',
        'Biología - Genética',
      ),
    ],
    1: [
      // 11° Año
      _q(
        '¿Qué es la Ley de gravitación universal de Newton?',
        ['F = ma', 'F = G(m₁m₂)/d²', 'E = mc²', 'PV = nRT'],
        1,
        'Newton demostró que F = G(m₁m₂)/d², donde todos los cuerpos se atraen proporcionalmente a sus masas.',
        'Física - Gravitación',
      ),
      _q(
        '¿Qué es la energía cinética?',
        [
          'Energía almacenada',
          'Energía del movimiento',
          'Energía del sol',
          'Energía nuclear',
        ],
        1,
        'La energía cinética es la energía que posee un cuerpo debido a su movimiento. EC = ½mv²',
        'Física - Energía',
      ),
      _q(
        '¿Qué establece la Ley de conservación de la energía?',
        [
          'La energía aumenta',
          'La energía disminuye',
          'La energía no se crea ni se destruye, solo se transforma',
          'La energía se puede destruir',
        ],
        2,
        'El principio fundamental establece que en un sistema aislado, la energía total permanece constante.',
        'Física - Energía',
      ),
      _q(
        '¿Qué es el sistema circulatorio?',
        [
          'Conjunto de vasos y órganos que transportan sangre',
          'Sistema de digestión',
          'Conjunto de huesos',
          'Sistema de respiración',
        ],
        0,
        'El sistema circulatorio incluye corazón, arterias, venas y capilares que transportan sangre por todo el cuerpo.',
        'Biología - Sistema circulatorio',
      ),
      _q(
        '¿Qué son los elementos químicos?',
        [
          'Sustancias formadas por un solo tipo de átomo',
          'Mezclas de sustancias',
          'Compuestos químicos',
          'Moléculas simples',
        ],
        0,
        'Un elemento es una sustancia pura formada por átomos del mismo tipo (mismo número atómico).',
        'Química - Elementos',
      ),
      _q(
        '¿Qué es una reacción química?',
        [
          'Cambio físico',
          'Proceso donde sustancias se transforman en otras nuevas',
          'Mezcla de sustancias',
          'Cambio de estado',
        ],
        1,
        'En una reacción química, los reactivos se transforman en productos con diferentes propiedades.',
        'Química - Reacciones',
      ),
      _q(
        '¿Qué es la selección natural?',
        [
          'Selección artificial de rasgos',
          'Supervivencia de organismos mejor adaptados',
          'Mutación genética',
          'Reproducción asexual',
        ],
        1,
        'Propuesta por Darwin: los organismos mejor adaptados a su ambiente tienen mayor probabilidad de sobrevivir y reproducirse.',
        'Biología - Evolución',
      ),
      _q(
        '¿Qué es la hidrostática?',
        [
          'Estudio de los líquidos en reposo',
          'Estudio del movimiento',
          'Estudio de gases',
          'Estudio del calor',
        ],
        0,
        'La hidrostática estudia los fluidos (líquidos y gases) en equilibrio o reposo.',
        'Física - Hidrostática',
      ),
    ],
    2: [
      // 12° Año
      _q(
        '¿Qué es la teoría de la relatividad de Einstein?',
        [
          'E = mc², masa y energía son equivalentes',
          'La luz es una onda',
          'El tiempo es absoluto',
          'La gravedad no existe',
        ],
        0,
        'E = mc² indica que la masa y la energía son formas equivalentes de la misma entidad.',
        'Física - Relatividad',
      ),
      _q(
        '¿Qué es la electrostática?',
        [
          'Estudio de cargas eléctricas en reposo',
          'Estudio de corrientes',
          'Estudio de imanes',
          'Estudio de ondas',
        ],
        0,
        'La electrostática estudia los fenómenos producidos por cargas eléctricas en reposo.',
        'Física - Electricidad',
      ),
      _q(
        '¿Qué es la estructura de la materia?',
        [
          'Cómo se organizan los átomos y moléculas',
          'El tamaño de los objetos',
          'El peso de los cuerpos',
          'La forma de los objetos',
        ],
        0,
        'Estudia la organización de partículas subatómicas, átomos, moléculas y su comportamiento.',
        'Química - Estructura',
      ),
      _q(
        '¿Qué son las transformaciones químicas?',
        [
          'Cambios de estado',
          'Cambios que producen nuevas sustancias',
          'Mezclas',
          'Cambios de forma',
        ],
        1,
        'En las transformaciones químicas (reacciones) se forman sustancias con propiedades diferentes.',
        'Química - Reacciones',
      ),
      _q(
        '¿Qué es la genética?',
        [
          'Estudio de los genes y la herencia',
          'Estudio de los ecosistemas',
          'Estudio del cuerpo humano',
          'Estudio del clima',
        ],
        0,
        'La genética estudia los genes, la herencia biológica y la variación de los organismos.',
        'Biología - Genética',
      ),
      _q(
        '¿Qué es la evolución biológica?',
        [
          'Cambio de especies con el tiempo por selección natural',
          'Creación divina',
          'Extinción de especies',
          'Mutaciones aleatorias',
        ],
        0,
        'La evolución es el cambio en las características de las poblaciones a lo largo de generaciones.',
        'Biología - Evolución',
      ),
    ],
  };

  // ESTUDIOS SOCIALES - Sociedad contemporánea, Historia de CR, Geografía, Economía
  static final Map<int, List<Question>> _socialQuestions = {
    0: [
      // 10° Año
      _q(
        '¿En qué fecha se independizó Costa Rica de España?',
        [
          '15 de septiembre de 1821',
          '25 de diciembre de 1821',
          '1 de enero de 1822',
          '5 de noviembre de 1820',
        ],
        0,
        'Costa Rica se independizó el 15 de septiembre de 1821, junto con otras provincias centroamericanas.',
        'Historia de Costa Rica',
      ),
      _q(
        '¿Quién fue Juan Rafael Mora Porras?',
        [
          'Primer presidente de Costa Rica',
          'Segundo presidente de Costa Rica (1849-1859)',
          'Un escritor costarrisense',
          'Un explorador del siglo XVI',
        ],
        1,
        'Juan Rafael Mora fue el segundo presidente y es clave en la historia de Costa Rica, enfrentó a William Walker.',
        'Historia de Costa Rica',
      ),
      _q(
        '¿Qué es Mesoamérica?',
        [
          'Una región de México',
          'Zona cultural que incluía partes de México y Centroamérica donde florecieron culturas prehispánicas',
          'Un país centroamericano',
          'Una montaña',
        ],
        1,
        'Mesoamérica fue una región cultural donde se desarrollaron civilizaciones como los mayas, aztecas y nicoyas.',
        'Historia - Civilizaciones',
      ),
      _q(
        '¿Quién fue José María Figueres Ferrer?',
        [
          'Un poeta',
          'Presidente tres veces y abolió el ejército en 1948',
          'Un explorador',
          'Un escritor costarrisense',
        ],
        1,
        'Figueres Ferrer fue presidente en tres períodos y abolió el ejército costarricense en 1948.',
        'Historia de Costa Rica',
      ),
      _q(
        '¿Qué es la geografía?',
        [
          'Estudio de la historia',
          'Estudio de la Tierra, sus territorios y poblaciones',
          'Estudio de la economía',
          'Estudio de la política',
        ],
        1,
        'La geografía estudia la superficie terrestre, sus fenómenos, lugares y las relaciones humanas con el entorno.',
        'Geografía',
      ),
      _q(
        '¿Cuáles son los países de Centroamérica?',
        [
          'México, Guatemala, Belice',
          'Guatemala, Belice, Honduras, El Salvador, Nicaragua, Costa Rica, Panamá',
          'Solo países sudamericanos',
          'México y Centroamérica',
        ],
        1,
        'Centroamérica está formada por: Guatemala, Belice, Honduras, El Salvador, Nicaragua, Costa Rica y Panamá.',
        'Geografía - Centroamérica',
      ),
      _q(
        '¿Qué es el capitalismo?',
        [
          'Sistema económico donde los medios de producción son del Estado',
          'Sistema donde la propiedad privada y el mercado libre son fundamentales',
          'Un sistema de trueque',
          'Un sistema sin dinero',
        ],
        1,
        'El capitalismo se basa en la propiedad privada, libre empresa y mercado libre.',
        'Economía - Sistemas',
      ),
      _q(
        '¿Quién fue Alejandro Mora?',
        [
          'Primer presidente de Costa Rica',
          'No existe información disponible',
          'Un poeta nacional',
          'Un explorador',
        ],
        1,
        'No hay registro de un personaje histórico significativo con ese nombre en Costa Rica.',
        'Historia de Costa Rica',
      ),
      _q(
        '¿Qué es un mapa?',
        [
          'Representación bidimensional de la superficie terrestre',
          'Una fotografía satelital',
          'Un libro de historia',
          'Una herramienta de navegación',
        ],
        0,
        'Un mapa es una representación gráfica de la Tierra o parte de ella sobre una superficie plana.',
        'Geografía - Cartografía',
      ),
      _q(
        '¿Qué es el comercio internacional?',
        [
          'Venta de productos dentro de un país',
          'Intercambio de bienes y servicios entre países',
          'Compra de productos locales',
          'Exportación de servicios',
        ],
        1,
        'El comercio internacional abarca las transacciones de bienes y servicios entre distintas naciones.',
        'Economía - Comercio',
      ),
    ],
    1: [
      // 11° Año
      _q(
        '¿Qué fue la Primera Guerra Mundial?',
        [
          'Conflicto europeo de 1914 a 1918',
          'Guerra civil española',
          'Revolución francesa',
          'Segunda Guerra Mundial',
        ],
        0,
        'La Primera Guerra Mundial (1914-1918) fue un conflicto global que involucró a las potencias mundiales.',
        'Historia - WWI',
      ),
      _q(
        '¿Qué fue la Segunda Guerra Mundial?',
        [
          'Conflicto de 1939 a 1945',
          'Conflicto de 1914 a 1918',
          'Guerra fría',
          'Guerra de Corea',
        ],
        0,
        'La Segunda Guerra Mundial (1939-1945) fue el conflicto más grande de la historia.',
        'Historia - WWII',
      ),
      _q(
        '¿Qué es la globalización?',
        [
          'Proceso de interconexión económica, cultural y política mundial',
          'Aislamiento de países',
          'Un tipo de gobierno',
          'Una religión mundial',
        ],
        0,
        'La globalización es la creciente interdependencia y conexión entre países en lo económico, cultural y político.',
        'Economía - Globalización',
      ),
      _q(
        '¿Qué es el TLC (Tratado de Libre Comercio)?',
        [
          'Acuerdo comercial entre países para reducir barreras',
          'Un tipo de guerra',
          'Una ley ambiental',
          'Un tratado de paz',
        ],
        0,
        'Los TLC son acuerdos que eliminan o reducen barreras arancelarias entre países.',
        'Economía - Comercio',
      ),
      _q(
        '¿Qué es la democracia?',
        [
          'Gobierno de una sola persona',
          'Sistema de gobierno donde el pueblo ejerce el poder',
          'Gobierno militar',
          'Sistema económico',
        ],
        1,
        'La democracia es el régimen político donde el poder se ejerce por el pueblo, mediante elecciones.',
        'Cívica - Democracia',
      ),
      _q(
        '¿Qué son los derechos humanos?',
        [
          'Privilegios de algunos ciudadanos',
          'Derechos inherentes a todas las personas sin distinción',
          'Leyes de un país',
          'Reglas de una empresa',
        ],
        1,
        'Los derechos humanos son derechos inherentes a toda persona: dignidad, libertad, igualdad.',
        'Cívica - Derechos',
      ),
      _q(
        '¿Qué fue la Guerra Fría?',
        [
          'Conflicto armado directo entre EUA y URSS',
          'Período de tensión geopolítica sin guerra directa (1947-1991)',
          'Guerra mundial',
          'Conflicto en Europa',
        ],
        1,
        'La Guerra Fría fue el período de tensión entre bloque occidental (EUA) y oriental (URSS) sin enfrentamiento directo.',
        'Historia - Guerra Fría',
      ),
    ],
    2: [
      // 12° Año
      _q(
        '¿Qué es la Constitución Política de Costa Rica?',
        [
          'Una ley secundaria',
          'La norma suprema que rige el Estado costarricense',
          'Un decreto ejecutivo',
          'Un tratado internacional',
        ],
        1,
        'La Constitución Política es la norma fundamental que establece la organización del Estado y los derechos ciudadanos.',
        'Cívica - Constitución',
      ),
      _q(
        '¿Qué es la ciudadanía crítica?',
        [
          'Ser ciudadano de un país',
          'Capacidad de analizar y cuestionar activamente la realidad social',
          'Simple pertenencia a una nación',
          'Votar en elecciones',
        ],
        1,
        'La ciudadanía crítica implica participar de manera informada y reflexiva en los asuntos públicos.',
        'Cívica - Ciudadanía',
      ),
      _q(
        '¿Qué es el desarrollo sostenible?',
        [
          'Crecimiento económico sin límites',
          'Satisfacción de necesidades presentes sin comprometer las futuras',
          'Uso máximo de recursos naturales',
          'Industrialización acelerada',
        ],
        1,
        'El desarrollo sostenible busca equilibrar crecimiento económico, cuidado ambiental y equidad social.',
        'Estudios Sociales - Sostenibilidad',
      ),
      _q(
        '¿Qué son los derechos humanos universales?',
        [
          'Derechos solo para ciudadanos',
          'Derechos inherentes a toda persona por su dignidad',
          'Derechos de un grupo específico',
          'Derechos限定 a un país',
        ],
        1,
        'Los derechos humanos universales son inherentes a todas las personas sin distinción.',
        'Cívica - DDHH',
      ),
    ],
  };

  // ESPAÑOL - Comprensión lectora, Gramática, Literatura, Producción textual
  static final Map<int, List<Question>> _spanishQuestions = {
    0: [
      // 10° Año
      _q(
        '¿Qué es un sustantivo?',
        [
          'Palabra que indica acción',
          'Palabra que nombra seres, lugares o cosas',
          'Palabra que califica',
          'Palabra que conecta',
        ],
        1,
        'El sustantivo (o nombre) es la palabra que nombra personas, animales, lugares, objetos o ideas.',
        'Gramática - Partes de la oración',
      ),
      _q(
        '¿Qué es una metáfora?',
        [
          'Comparación usando "como"',
          'Recurso que da cualidades humanas a objetos',
          'Exageración (hipérbole)',
          'Repetición de sonidos',
        ],
        1,
        'La metáfora atribuye cualidades de una cosa a otra sin usar conectores como "como".',
        'Literatura - Figuras retóricas',
      ),
      _q(
        '¿Qué es el sujeto de una oración?',
        [
          'Lo que se dice del sujeto',
          'Quien realiza la acción o del cual se predica',
          'El verbo de la oración',
          'El complemento',
        ],
        1,
        'El sujeto es quien realiza la acción del verbo o es descrito en la oración.',
        'Gramática - Sujeto',
      ),
      _q(
        '¿Qué es una comparación (símil)?',
        [
          'Relación entre dos elementos usando "como"',
          'Metáfora sin comparación',
          'Personificación',
          'Hipérbole',
        ],
        0,
        'El símil o comparación usa conectores como "como", "cual", "parecido a" para relacionar elementos.',
        'Literatura - Figuras retóricas',
      ),
      _q(
        '¿Qué es el predicado?',
        [
          'Lo que se dice del sujeto',
          'El nombre de la oración',
          'El complemento directo',
          'El artículo',
        ],
        0,
        'El predicado es todo lo que se afirma o niega del sujeto, contiene el verbo.',
        'Gramática - Predicado',
      ),
      _q(
        '¿Qué es un verbo?',
        [
          'Palabra que nombra',
          'Palabra que indica acción, estado o cambio',
          'Palabra que califica',
          'Palabra que une',
        ],
        1,
        'El verbo expresa acciones, estados o cambios y es el núcleo del predicado.',
        'Gramática - Verbo',
      ),
      _q(
        '¿Qué es la comprensión lectora?',
        [
          'Leer sin entender',
          'Proceso de entender e interpretar un texto',
          'Memorizar un texto',
          'Copiar un texto',
        ],
        1,
        'La comprensión lectora es la capacidad de entender, analizar y extraer significado de un texto.',
        'Español - Comprensión',
      ),
      _q(
        '¿Qué es un adverbio?',
        [
          'Palabra que modifica al verbo',
          'Palabra que modifica al adjetivo, verbo o adverbio',
          'Palabra que nombra',
          'Palabra que conecta',
        ],
        1,
        'El adverbio modifica a un verbo, adjetivo u otro adverbio, indicando circunstancias.',
        'Gramática - Adverbio',
      ),
      _q(
        '¿Qué es una hiato?',
        [
          'Dos vocales juntas que se pronuncian separadas',
          'Dos vocales juntas que forman una sola sílaba',
          'Un tipo de consonante',
          'Una figura retórica',
        ],
        0,
        'El hiato es la secuencia de dos vocales que pertenecen a sílabas distintas.',
        'Gramática - Fonética',
      ),
      _q(
        '¿Qué es el conecto (diptongo)?',
        [
          'Dos vocales separadas',
          'Dos vocales juntas en la misma sílaba',
          'Una consonante doble',
          'Un sonido nasal',
        ],
        1,
        'El diptongo es la combinación de dos vocales en una misma sílaba.',
        'Gramática - Fonética',
      ),
    ],
    1: [
      // 11° Año
      _q(
        '¿Qué es el modernismo literario?',
        [
          'Movimiento literario de finales del siglo XIX e inicio del XX',
          'Literatura medieval',
          'Poesía romántica',
          'Narrativa realista del siglo XX',
        ],
        0,
        'El modernismo fue un movimiento artístico y literario caracterizado por la renovación formal y temática.',
        'Literatura - Modernismo',
      ),
      _q(
        '¿Qué es una oración compuesta?',
        [
          'Oración con un solo verbo',
          'Oración con dos o más verbos principales',
          'Oración muy corta',
          'Oración sin sujeto',
        ],
        1,
        'Una oración compuesta contiene dos o más oraciones simples unidas por conjunciones o signos.',
        'Gramática - Oración compuesta',
      ),
      _q(
        '¿Qué es el realismo en literatura?',
        [
          'Narración de hechos fantásticos',
          'Representación de la vida cotidiana con objetividad',
          'Poesía subjetiva',
          'Literatura medieval',
        ],
        1,
        'El realismo busca representar la realidad cotidiana de manera objetiva y fiel.',
        'Literatura - Realismo',
      ),
      _q(
        '¿Qué es el subjuntivo?',
        [
          'Modo de la realidad',
          'Modo verbal que expresa deseo, duda o posibilidad',
          'Tiempo pasado',
          'Voz activa',
        ],
        1,
        'El subjuntivo expresa acciones hipotéticas, deseadas, dudadas o posibles.',
        'Gramática - Modo subjuntivo',
      ),
      _q(
        '¿Qué es la producción textual?',
        [
          'Lectura de textos',
          'Creación y redacción de textos escritos',
          'Memorización de textos',
          'Análisis de textos',
        ],
        1,
        'La producción textual es el proceso de redactar y crear textos de forma coherente.',
        'Español - Producción',
      ),
    ],
    2: [
      // 12° Año
      _q(
        '¿Qué es la lingüística?',
        [
          'Ciencia que estudia el lenguaje humano',
          'Estudio de las matemáticas',
          'Historia de la literatura',
          'Geografía cultural',
        ],
        0,
        'La lingüística es la ciencia que estudia el lenguaje humano, su estructura y funcionamiento.',
        'Español - Lingüística',
      ),
      _q(
        '¿Qué es el análisis del discurso?',
        [
          'Estudio de palabras individuales',
          'Estudio de cómo se usa el lenguaje en contextos sociales',
          'Estudio de la gramática',
          'Estudio de la literatura',
        ],
        1,
        'El análisis del discurso examina cómo el lenguaje funciona en la comunicación social.',
        'Español - Discurso',
      ),
      _q(
        '¿Qué es el vanguardismo?',
        [
          'Movimiento conservador',
          'Movimiento artístico de ruptura con tradiciones (siglo XX)',
          'Escuela clásica',
          'Literatura medieval',
        ],
        1,
        'El vanguardismo rejectó las formas tradicionales y buscó innovar en arte y literatura.',
        'Literatura - Vanguardismo',
      ),
    ],
  };

  // EDUCACIÓN CÍVICA
  static final Map<int, List<Question>> _civicaQuestions = {
    0: [
      // 10° Año
      _q(
        '¿Qué es la ciudadanía?',
        [
          'Ser native de un país',
          'Condición de pertenencia a una comunidad política con derechos y deberes',
          'Tener un documento de identidad',
          'Votar en elecciones',
        ],
        1,
        'La ciudadanía implica pertenecer a un Estado y disfrutar de derechos políticos y civiles.',
        'Cívica - Ciudadanía',
      ),
      _q(
        '¿Qué son los valores cívicos?',
        [
          'Principios que guían el comportamiento ciudadano responsable',
          'Creencias religiosas',
          'Normas de una empresa',
          'Leyes económicas',
        ],
        0,
        'Los valores cívicos como justicia, respeto y solidaridad orientan la convivencia democrática.',
        'Cívica - Valores',
      ),
      _q(
        '¿Qué es el respeto?',
        [
          'Obediencia total',
          'Consideración y valoración hacia otros',
          'Temor',
          'Indiferencia',
        ],
        1,
        'El respeto es reconocer la dignidad y derechos de las demás personas.',
        'Cívica - Respeto',
      ),
    ],
    1: [
      // 11° Año
      _q(
        '¿Qué son los derechos fundamentales?',
        [
          'Derechos ilimitados',
          'Derechos inherentes a la persona reconocidos constitucionalmente',
          'Privilegios del gobierno',
          'Derechos económicos',
        ],
        1,
        'Los derechos fundamentales son inherentes a la dignidad humana y están protegidos por la Constitución.',
        'Cívica - Derechos',
      ),
      _q(
        '¿Qué es la tolerancia?',
        [
          'Aceptar todo sin cuestionar',
          'Respeto ante las diferencias de otros',
          'Indiferencia',
          'Conformismo',
        ],
        1,
        'La tolerancia es respetar las ideas, creencias y prácticas diferentes a las propias.',
        'Cívica - Tolerancia',
      ),
      _q(
        '¿Qué es el Estado de Derecho?',
        [
          'Gobierno sin leyes',
          'Principio donde todos están sometidos a la ley',
          'Gobierno del más fuerte',
          'Estado sin Constitución',
        ],
        1,
        'El Estado de Derecho garantiza que ninguna persona o institución está sobre la ley.',
        'Cívica - Estado',
      ),
    ],
    2: [
      // 12° Año
      _q(
        '¿Qué es la participación ciudadana?',
        [
          'Solo votar',
          'Involucramiento activo en decisiones públicas',
          'Ser empleado público',
          'Pagar impuestos',
        ],
        1,
        'La participación ciudadana incluye votar, opinar, organizarse y vigilar las acciones del gobierno.',
        'Cívica - Participación',
      ),
      _q(
        '¿Qué es la sostenibilidad ambiental?',
        [
          'Explotación máxima de recursos',
          'Uso responsable de recursos para no comprometer generaciones futuras',
          'No usar recursos naturales',
          'Contaminación controlada',
        ],
        1,
        'La sostenibilidad busca equilibrio entre desarrollo económico, social y cuidado del ambiente.',
        'Cívica - Ambiente',
      ),
      _q(
        '¿Qué son los derechos de la mujer?',
        [
          'Privilegios',
          'Derechos iguales para mujeres establecidos internacionalmente',
          'Derechos especiales',
          'Ninguno',
        ],
        1,
        'Los derechos de la mujer incluyen igualdad de género, no discriminación y violencia cero.',
        'Cívica - Género',
      ),
    ],
  };

  static Question _q(
    String question,
    List<String> options,
    int correct,
    String explanation,
    String topic,
  ) {
    return Question.create(
      odId: DateTime.now().microsecondsSinceEpoch.toString(),
      question: question,
      options: options,
      correctAnswerIndex: correct,
      explanation: explanation,
      categoryIndex: 0,
      levelIndex: 0,
      topic: topic,
    );
  }
}
