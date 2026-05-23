# Plan de Trabajo Grupal - Reminder App

> Documento de planificación compartida entre los 3 integrantes del proyecto.
> Última actualización: 2026-05-23

---

## 1. Contexto

El docente nos indicó que la aplicación tenía un enfoque muy genérico y que debíamos especializarla. Decidimos **centrar la app en el mundo académico universitario**.

La presentación anterior fue calificada como "muy simple" y con bugs visibles, por lo que esta iteración apunta a:

- Especializar el dominio (entidades académicas).
- Cerrar bugs existentes antes de seguir agregando features.
- Mejorar la profundidad funcional sin romper la UI (que es lo mejor evaluado del proyecto).

---

## 2. Modelo de Dominio

### Entidades principales

```
User (con avatarIcon)
  │
Period (Periodo académico)
  │
  └── Course (Curso)
        ├── CourseSession[] (día + horarios + aula opcional)
        ├── Teacher? (Profesor - Sprint 2)
        ├── Grade[] (Calificaciones con peso %)
        └── Note[] (Apuntes del curso)

Reminder (Recordatorio - ex Activity)
Note libre (Apuntes generales fuera de curso)
Teacher (Profesor - Sprint 2)
Classroom (Aula - Sprint 2)
```

### Distinción semántica importante

| En código | En UI (español) | Qué es |
|---|---|---|
| `Reminder` | "Recordatorio" | Lo que antes era "Activity": tareas, pagos, eventos. Independiente de curso. |
| `Note` | "Apunte" | Bloc de notas (libre o por curso). |
| `Grade` | "Calificación" / "Nota" | Calificación con peso porcentual para promedio ponderado. |

Esta separación evita confusión entre "Notas" (apuntes) y "Notas" (calificaciones), que en español ambiguo significan lo mismo.

---

## 3. Pseudocódigo de Modelos

### User (actualizado)

```dart
class User {
  final String? id;
  final String name;
  final String email;
  final String? avatarIcon;   // NUEVO - ej. "dracula", "hada"
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Notas:**
- `avatarIcon` guarda solo el nombre del archivo sin extensión.
- Reconstrucción del path: `'assets/avatars/${user.avatarIcon}.png'`.
- Eliminar el campo `password` actual del modelo (Firebase Auth ya lo gestiona, no debe persistirse).
- Migrar nombres de campos a camelCase consistente: `createdAt` / `updatedAt` (hoy `fromFirestore` lee snake_case y `toFirestore` escribe camelCase, está roto).

### Course (actualizado)

```dart
class Course {
  final String? id;
  final String userId;
  final String? academicPeriodId;
  final String name;
  final List<CourseSession> sessions;   // REEMPLAZA scheduleDays
  final String? note;                   // Apunte general del curso
  final String? teacherId;              // Sprint 2 (FK a Teacher)
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### CourseSession (nuevo)

```dart
class CourseSession {
  final int dayOfWeek;        // 0=Lun ... 6=Dom
  final String startTime;     // "HH:mm" formato 24h ej. "08:00"
  final String endTime;       // "HH:mm" formato 24h ej. "10:00"
  final String? roomName;     // Aula libre (Sprint 2 migra a classroomId FK)
}
```

**Concepto:** un curso puede tener diferentes horarios por día. Lunes 8-10 y Miércoles 14-16 son 2 sesiones del mismo curso. Modelar como lista de objetos evita listas paralelas desincronizadas.

### Reminder (renombrado de Activity)

```dart
class Reminder {
  final String? id;
  final String userId;
  final String name;
  final String? notes;
  final double? budgetAmount;
  final String frequency;       // "Una vez" | "Diario" | "Semanal" | "Mensual"
  final List<int> scheduleDays;
  final String? startTime;
  final DateTime? date;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Cambios respecto a Activity:** ninguno en estructura, solo el rename del nombre de clase y de la colección Firestore (`activities` → `reminders`).

### Grade (nuevo)

```dart
class Grade {
  final String? id;
  final String userId;
  final String courseId;     // FK al curso
  final String title;        // "Parcial 1", "Tarea 3"
  final double value;        // calificación obtenida, ej. 17.5
  final double maxValue;     // calificación máxima posible, ej. 20
  final double weight;       // peso en %, ej. 30
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Fórmula de promedio ponderado:**

```
promedio = Σ (value/maxValue × weight) / Σ weight
```

**Validación clave:** al guardar, la suma de `weight` de un curso debe ser ≤ 100. Si es menor, avisar al usuario "te falta X% por asignar". Si es mayor, bloquear.

### Note (nuevo - Sprint 2)

```dart
class Note {
  final String? id;
  final String userId;
  final String? courseId;    // null = nota libre, lleno = nota de curso
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Teacher (nuevo - Sprint 2)

```dart
class Teacher {
  final String? id;
  final String userId;
  final String name;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Classroom (nuevo - Sprint 2)

```dart
class Classroom {
  final String? id;
  final String userId;
  final String code;         // "A-301"
  final String? building;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

## 4. Funcionalidades acordadas - Roadmap por Sprint

### Sprint 1 (actual)
- Selector de avatar al registrar (10 íconos locales en `assets/avatars/`).
- Fix de bugs de autenticación.
- Botón cerrar sesión (vía menú al tocar avatar en home).
- Horarios por día con hora inicio/fin (`CourseSession`).
- Pantalla Schedule semanal (grid tipo calendario).
- Calificaciones con peso porcentual + promedio ponderado.
- Traducción completa de UI a español.
- Rename de `Activity` → `Reminder` (modelo + colección + UI).

### Sprint 2 (siguiente)
- Login con Google (`google_sign_in` + Firebase).
- Entidad `Teacher` con CRUD propio + vínculo a Course.
- Entidad `Classroom` con CRUD propio + vínculo a CourseSession.
- Entidad `Note` (apuntes) libre y por curso.
- Detección de conflictos de horario al crear/editar curso.
- Notificaciones locales (`flutter_local_notifications`) para recordatorios, calificaciones y cursos del día.
- **Navegación temporal en Horario:** la fecha del header siempre muestra la semana actual del calendario. Permitir navegar semanas (`< >`) o saltar a la semana del periodo seleccionado, para repasar semestres pasados con su calendario correcto. Decidir comportamiento cuando el periodo está en curso vs. ya terminado.
- **Validación al editar fechas de un periodo:** si el periodo tiene cursos asociados, mostrar advertencia (NO bloqueo) al cambiar fechas, ya que el filtro automático de Home podría ocultar esos cursos. Texto sugerido: "Este periodo tiene N cursos; cambiar las fechas puede ocultarlos del inicio. ¿Continuar?".

### Sprint 3 (posterior)
- Modo offline + sync (Firestore lo trae built-in, hay que verificar config).
- Modo Focus / Pomodoro.
- Botón "¿Cómo vas?" con respuestas predefinidas.
- Mensajes motivacionales con API de IA.

### Sprint 4 (avanzado)
- Compartir cursos / recordatorios / notas por QR o email.
- Recordatorios contextuales basados en clima.
- Exportar reportes en PDF.

### Sprint 5 (ambicioso)
- Crear recordatorios por voz con Whisper + LLM para parsear lenguaje natural.

---

## 5. Lista de tareas del Sprint 1 (sin asignar)

Cada integrante elige según prioridad e interés. Marcar con [x] al completar y hacer commit con el nombre del integrante en el mensaje.

### Bloque A - Avatar y autenticación
- [x] Actualizar modelo `User` con campo `avatarIcon` + corregir inconsistencias snake/camelCase + quitar `password` del modelo.
- [x] Crear widget `AvatarSelector` (grid de avatares con borde resaltado al seleccionar).
- [x] Integrar `AvatarSelector` en `RegisterScreen` (vía bottomsheet al tocar el avatar, no inline).
- [x] Guardar `avatarIcon` en Firestore al crear cuenta.
- [x] Mostrar avatar elegido en `HomeScreen._buildHeader` (reemplazar `CircleAvatar` placeholder).

### Bloque B - Bugs y cerrar sesión
- [x] Cambiar `Navigator.push` por `Navigator.pushReplacement` en `login_screen.dart`.
- [x] En `register_screen.dart`: limpiar controllers + `Navigator.pop` tras registro exitoso.
- [x] Implementar menú al tocar avatar en home (opciones: "Cerrar Sesión").
- [x] `FirebaseAuth.instance.signOut()` + `pushReplacement` a `LoginScreen`.
- [x] Eliminar funciones muertas: `loginAccess` en login, `registerUser` (sin guion bajo) en register.
- [x] Quitar `print('DEBUG ...')` de `home_screen.dart` y `schedule_repository.dart`.

### Bloque C - Horarios por día en cursos
- [x] Crear modelo `CourseSession` en `lib/models/course_session.dart`.
- [x] Refactorizar `Course` para reemplazar `scheduleDays` por `List<CourseSession>`.
- [x] Actualizar `Course.fromFirestore` / `toFirestore` (sesiones como array de mapas en Firestore).
- [x] Refactorizar `CreateCourseScreen` con UI estilo "School Planner": lista de sesiones + bottomsheet `SessionEditorSheet` reutilizable + campos Aula (por sesión) y Apunte (por curso).
- [x] Actualizar `course_screen.dart` para mostrar sesiones formateadas (ej. "Lun 8-10 AM, Mié 2-4 PM").
- [x] Adaptar `schedule_repository.dart` al nuevo modelo de sesiones.

**Decisiones tomadas durante el Bloque C:**
- Formato de hora: `"HH:mm"` (24h) en Firestore, `"h:mm AM/PM"` (12h) en UI. Helpers en `lib/core/utils/time_helpers.dart`.
- `Course.note`: apunte general del curso (`String?`).
- `CourseSession.roomName`: aula por sesión (`String?`). Sprint 2 se migra a `classroomId` FK.
- Un curso puede tener múltiples sesiones en el mismo día (ej. teoría + práctica).
- Sin pantalla separada "Add multiple": la lista de sesiones vive en la pantalla principal del curso.

### Bloque D - Pantalla Schedule semanal
- [x] Crear `lib/features/schedule/schedule_screen.dart`.
- [x] Implementar grid de horario semanal (columnas = días Lun-Dom, filas = horas 12:00am-11:59pm).
- [x] Renderizar cursos como cards posicionadas (`Stack` + `Positioned`).
- [x] Conectar botón "HORARIO" del bottom nav de `home_screen.dart` a la nueva pantalla.
- [x] Selector manual de periodos en el header de Horario (bottomsheet con "Todos los periodos" + lista). Filtra `_courses` por `academicPeriodId`. Helper `_filteredCourses` recalculado por columna.
- [x] Método `PeriodRepository.getAll()` (Future) para carga puntual desde ScheduleScreen.

**Deuda Bloque D:** días en inglés (`Mon`, `Tue`...), colores hardcoded en Scaffold/header/grid/modal, `print` con emojis en `_loadCourses`, `withOpacity()` deprecado — pulido pendiente. Adicional: la fecha del header siempre muestra "semana actual del calendario" aunque selecciones un periodo pasado (necesita navegación temporal — ver Sprint 2).

### Bloque E - Calificaciones (Grade)
- [ ] Crear modelo `Grade` en `lib/models/grade.dart`.
- [ ] Crear `GradeRepository` en `lib/data/grade_repository.dart` (CRUD + watchByCourse).
- [ ] Crear `lib/features/grade/grade_screen.dart` (lista de notas por curso + promedio actual).
- [ ] Crear `lib/features/grade/create_grade_screen.dart` (form: título, valor, máximo, peso).
- [ ] Implementar validación: suma de pesos ≤ 100, con feedback visual.
- [ ] Calcular promedio ponderado en el header de `GradeScreen`.
- [ ] Acceso a `GradeScreen` desde sheet de detalle del curso (cuando se implemente).

### Bloque F - Rename Activity → Reminder
- [x] Renombrar `lib/models/activity.dart` → `reminder.dart` (clase `Activity` → `Reminder`).
- [x] Renombrar `lib/data/activity_repository.dart` → `reminder_repository.dart`.
- [x] Renombrar la clase interna `ActivityScreen` → `ReminderScreen` (+ `_ActivityScreenState` → `_ReminderScreenState`, `_ActivityTile` → `_ReminderTile`) y el título "Actividades" → "Recordatorios". Textos UI internos traducidos (eliminar, error, empty state).
- [x] Renombrar `create_activity_screen.dart` → `create_reminder_screen.dart` + textos UI ("Crear/Editar Recordatorio", "Nombre del Recordatorio", snackbars).
- [x] Cambiar referencia a colección Firestore: `'activities'` → `'reminders'` en repo y en `schedule_repository.dart`.
- [ ] **Borrar la colección `activities` vieja en Firestore Console** (datos de prueba).
- [x] Actualizar `create_options_sheet.dart` con el nuevo nombre (`ReminderScreen` + título "Recordatorio").
- [x] Asegurar que el botón en el sheet dice "Recordatorio" (subtitle reposicionado a contexto académico: "Exámenes, prácticas, reuniones, mensualidades").

### Bloque G - Traducción UI a español
- [x] `home_screen.dart`: secciones renombradas a "Pendientes Hoy" (generaliza cursos + recordatorios) y "Próximos", "Ver Todo", empty states traducidos.
- [ ] `home_screen.dart` bottom nav (`bottom_nav_bar.dart`): "HOME/SCHEDULE/SHARE/PROFILE" → "INICIO/HORARIO/COMPARTIR/PERFIL".
- [x] `home_screen.dart` stats: labels "Recordatorios/Cursos/Periodos" (se cambió "Apuntes" por "Periodos" porque Apuntes aún no existe como entidad).
- [x] `schedule_repository.dart`: subtitulos "Course", "Finance • $freq", "Activity • $freq" → equivalentes en español.
- [ ] `login_screen.dart`: snackbars de error y éxito a español.
- [ ] `register_screen.dart`: "User created successfully!" → "Cuenta creada con éxito" y todos los mensajes.
- [ ] **Convertir labels UPPERCASE a Title Case** en `login_screen.dart` (2), `create_activity_screen.dart` (7), `create_period_screen.dart` (3), `create_course_screen.dart` (4). Decisión tomada en Sprint 1 al refactorizar `register_screen.dart`.

---

## 6. Convenciones del proyecto

### Idiomas
- **Comunicación entre integrantes y comentarios en código: español.**
- **Identificadores en código (clases, variables, funciones): inglés.**
- **Excepción:** nombres de archivos de assets (`mago_joven.png`) pueden estar en español si son contenido visual; el valor guardado en Firestore (`avatarIcon: "mago_joven"`) sigue esa convención.
- **Textos visibles al usuario: 100% español.** El único término en inglés visible es el nombre técnico de la app (`reminder_app`).

### Capitalización en UI
- **Botones, AppBars, labels, FABs: Title Case** (ej. "Iniciar Sesión", "Crear Curso", "Cerrar Sesión").
- **Mensajes, snackbars, descripciones: oración normal** (ej. "No hay cursos registrados").
- **Headers ALL CAPS** (ej. "BIENVENIDO", "CORREO ELECTRÓNICO"): mantener cuando aplique.
- NO transformar textos a mayúsculas vía CSS o `.toUpperCase()` automáticamente. Si va en mayúsculas, escribirlo así en el código fuente.

### Estructura de carpetas
```
lib/
├── core/          # widgets compartidos, tema
├── data/          # repositorios (acceso a Firestore)
├── features/      # pantallas agrupadas por feature
│   ├── auth/
│   ├── home/
│   ├── schedule/
│   └── grade/
├── models/        # clases de dominio
├── app.dart
├── main.dart
└── firebase_options.dart
```

### Firestore
- **Naming de campos: camelCase consistente** (`createdAt`, `userId`, `scheduleDays`).
- **withConverter:** todos los repositorios usan `withConverter` para tipar las queries.
- **IDs:** Firestore genera el doc ID automáticamente (`add()`), no se setea manualmente.
- **Filtrar por usuario:** todo query incluye `where('userId', isEqualTo: currentUserId)`.

### Documentación
- **No crear archivos `.md` dentro del repo.** Toda la documentación grupal va en este archivo. Excepción única: este `PLAN_GRUPO.md`.
- Comentarios en código solo si la lógica es no obvia (preferir nombres descriptivos).

### Git
- **Commits pequeños y atómicos.** Un commit = un cambio lógico.
- **Mensaje de commit en español o inglés**, descriptivo del cambio.
- **Pull antes de empezar a trabajar** para evitar conflictos.

---

## 7. Decisiones técnicas tomadas

| Decisión | Por qué |
|---|---|
| Rename limpio de Activity → Reminder borrando datos viejos | Estamos en desarrollo temprano, la coherencia código/BD vale más que conservar datos de prueba. |
| Avatares como assets locales, no Firebase Storage | Son 10 íconos fijos, no datos del usuario. Ahorra costo de almacenamiento/lectura. |
| `avatarIcon` guarda string del nombre (opción A) | Más simple que mantener un mapa de IDs. Es contenido visual, no lógica de negocio. |
| Teacher/Classroom como entidades separadas (no embebidas) | Permite reutilizar un profesor en varios cursos sin duplicar datos. |
| `CourseSession` como lista de objetos (no listas paralelas) | Listas paralelas se desincronizan y producen bugs. |
| `Grade.maxValue` configurable | Algunos cursos van sobre 20, otros sobre 100. |
| Validación de suma de pesos ≤ 100 en cliente | Feedback inmediato al usuario. |
| Schedule = grid calendario (no lista) | Más visual e impresiona en presentación. |
| Profesor/Aula a Sprint 2 | Sprint 1 ya tiene 7 bloques, sobrecargarlo es contraproducente. |
| Login Google a Sprint 2 | Idem - prioridad menor que cerrar bugs y modelo de dominio. |
| Filtro de cursos en Home por periodo activo según fechas (no por borrar el periodo) | Los cursos de periodos pasados no contaminan Home automáticamente. Borrar el periodo sigue disponible para casos puntuales. Cursos sin `academicPeriodId` siempre visibles. |
| Reminders recurrentes en "Próximos": una card por ocurrencia | Diario/Semanal generan una card por cada día restante de la semana; "Una vez" se acota al domingo 23:59:59. Más fiel a la realidad que una sola card etiquetada. |
| Selector de Horario solo "Todos los periodos" + lista de periodos | No se incluyó "Periodo activo" ni "Sin periodo asignado" para mantener el selector simple. |
| Cast Firestore con `(x as num?)?.toDouble()` para montos | Firestore guarda `int` si el número no tiene decimales; `as double?` crashea. `num` cubre int y double. |

---

## 8. Pendientes de discusión grupal

Estos temas se decidirán cuando lleguemos a su sprint:

- **API de IA para mensajes motivacionales:** ¿Claude API, OpenAI o Gemini? Considerar costo y manejo de keys (no exponer en cliente, usar Firebase Functions como proxy).
- **Permisos al compartir recursos:** ¿solo lectura o también edición? ¿revocación?
- **Algoritmo de detección de conflictos:** comparación de rangos horarios por día. Definir si conflicto es "bloqueante" o solo "advertencia".
- **Whisper:** ¿OpenAI API o modelo self-hosted? El parser de fecha en lenguaje natural requiere un LLM aparte.

---

## 9. Estado actual de la app

### Lo que funciona (al cierre de Bloques A + B + C + D + F + Home reactivo)
- Registro con selector de avatar (10 íconos) + login con Firebase Auth.
- Cerrar sesión vía menú al tocar avatar en home.
- Avatar mostrado en HomeScreen header.
- CRUD de Periodos.
- CRUD de Cursos con **sesiones múltiples** (día + hora inicio/fin + aula por sesión + apunte por curso).
- CRUD de Recordatorios (UI ya 100% renombrada a "Recordatorios" — **Bloque F cerrado**).
- Pantalla Schedule semanal en grid **con selector manual de periodos** (filtra cursos por periodo; "Todos los periodos" por defecto).
- **Home reactivo con StreamBuilder:** stats reales (Recordatorios/Cursos/Periodos) + "Pendientes Hoy" + "Próximos" se actualizan automáticamente al crear/editar/borrar cursos o recordatorios. `ScheduleRepository` refactorizado a funciones puras de filtrado.
- **Filtro automático por periodo activo en Home:** cursos de periodos cuyo rango de fechas no incluye "hoy" no aparecen; cursos sin periodo siempre visibles.
- **Reminders recurrentes en "Próximos":** Diario/Semanal generan una card por cada día restante de la semana; "Una vez" se acota al fin de semana.
- `SessionEditorSheet`: TimePicker en tema oscuro consistente con DatePicker, validación de errores inline dentro del modal (sin SnackBar oculto detrás).
- UI dark mode con identidad visual sólida (lo mejor evaluado).
- Helpers de formato de hora 24h↔12h en `lib/core/utils/time_helpers.dart`.
- Bottomsheet reutilizable `SessionEditorSheet` para crear/editar sesión.

### Lo que está roto / pendiente
- Sin calificaciones (Grade) ni promedio ponderado — **Bloque E** (no iniciado).
- La pantalla de Recordatorios requería **índice compuesto en Firestore** (`userId` + `createdAt`); creado desde el link del error `failed-precondition` el 2026-05-23. El Bloque E (`grade_repository`) probablemente necesitará otro índice similar.
- Textos pendientes de traducir en login, register, bottom nav — **Bloque G**.
- Labels UPPERCASE pendientes de convertir a Title Case en `create_period_screen.dart`, `create_course_screen.dart`, `login_screen.dart` — **Bloque G**.
- Falta `AuthGate` que decida Login vs Home según estado de auth al iniciar app — Sprint 2.
- Pantallas Profile y Share son placeholders vacíos — no entrar en la demo.

### Deuda técnica conocida
- `schedule_screen.dart`: días en inglés (`Mon`-`Sun`), colores hardcoded (Scaffold, header, grid, modal de detalle), `print` con emojis en `_loadCourses` (líneas ~58-91), `withOpacity()` deprecado (usar `withValues(alpha:)`), carga manual con `Future` en vez de `CourseRepository.watchAll()` con StreamBuilder.
- Colores hardcoded en `lib/core/widgets/bottom_nav_bar.dart` — migrar a `AppColors`.
- Tema oscuro de pickers (`showDatePicker`, `showTimePicker`) está duplicado entre `app_date_picker_field.dart` y `session_editor_sheet.dart` — extraer a helper si aparece un tercer uso (regla de tres).
- Cosméticos en `home_screen.dart`: typo `upcoming . isEmpty` (línea ~226, Dart lo acepta), clase de estado `_HomeScreen` debería ser `_HomeScreenState` (convención).
- Comentarios con "actividad" en `reminder_repository.dart` — no UI, sin urgencia.
- Typo histórico `AppColors.organe` → corregido a `orange` el 2026-05-21.
