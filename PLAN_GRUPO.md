# Plan de Trabajo Grupal - Reminder App

> Documento de planificación compartida entre los 3 integrantes del proyecto.
> Última actualización: 2026-06-10

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
  final String? roomName;     // Aula libre por sesión (Classroom como entidad: DESCARTADA)
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

### Sprint 2 (en curso)

**Completado:**
- [x] **AuthGate** (2026-06-01): widget con `StreamBuilder` sobre `authStateChanges()` que decide Login/Home al abrir la app. Configurado como `home: const AuthGate()` en `app.dart` (`lib/features/auth/auth_gate.dart`).
- [x] **Icono de la app + nombre "Reminder App"** (2026-06-01): icono adaptativo (campana blanca sobre gradiente morado #B483FF→#7A4BFF) generado con `flutter_launcher_icons` para Android e iOS. Nombre en `AndroidManifest.xml` (`android:label`) e `Info.plist` (`CFBundleDisplayName` + `CFBundleName`). Assets en `assets/icon/` (ic_full / ic_background / ic_foreground).

- [x] **Login con Google** (2026-06-05): `AuthService.signInWithGoogle()` en `lib/services/auth_service.dart` + botón "Continuar con Google". Crea el doc `users/{uid}` si no existe (avatar 'anonimo'). Cancelar el prompt no muestra error.
- [x] **Entidad `Note` (Apuntes)** (2026-06-05): modelo + `NoteRepository` + `NotesScreen` (grid, búsqueda por título, filtro por curso) + `CreateNoteScreen`. Color por apunte.
- [x] **ProfileScreen** (2026-06-05): ver/editar nombre y avatar (ya no es placeholder).
- [x] **Archivar periodo** (2026-06-05): campo `isArchived` en Period + `ArchivedPeriodScreen` con restaurar.
- [x] **Color por curso** (2026-06-05): `colorCode` en Course + widget `ColorSelector`.
- [x] **Estabilización general** (2026-06-10): ver sección 10 (reglas Firestore, sistema de mensajes, errores de auth en español, localización de fechas).

- [x] **Recuperar contraseña** (2026-06-11): sheet en login con `sendPasswordResetEmail`. Errores inline dentro del modal (regla nueva de §6).
- [x] **Verificación de correo obligatoria** (2026-06-11): al registrarse se envía link de verificación y se cierra sesión; login y AuthGate bloquean usuarios con `emailVerified == false` (diálogo con "Reenviar Correo"). Cuentas Google ya vienen verificadas. OJO: cuentas de prueba viejas quedan bloqueadas hasta verificarse.
- [x] **Selector de avatar tras primer login con Google** (2026-06-11): detecta `additionalUserInfo.isNewUser`; sheet sobre Home vía `rootNavigatorKey` (AuthGate desmonta el login al instante, su context muere). `UserRepository.updateAvatarIcon()` con `update` (no `set`).

**Configuración Google Sign-In (IMPORTANTE para cada integrante):**
- `google_sign_in` 7.x exige `serverClientId` explícito en Android: está como constante en `auth_service.dart` (es el Web client ID de Authentication > Google > Web SDK configuration; es público, no es secreto).
- **Cada integrante debe registrar el SHA-1/SHA-256 de SU máquina** en Firebase Console (Configuración del proyecto > app Android > Agregar huella digital) o Google Sign-In le fallará solo a él. Obtenerlo: `cd android && .\gradlew signingReport` (variant debug). Tras agregar huellas, re-descargar `google-services.json`.

- [x] **Modo offline** (2026-06-11): persistencia explícita en `main.dart` (`persistenceEnabled` + cache ilimitado) y **NUEVA CONVENCIÓN: las escrituras a Firestore (create/update/delete/set) NO se esperan con `await`** — con persistencia offline el Future solo se completa cuando el servidor confirma, y un `await` cuelga la UI sin internet. Patrón: `repo.create(x).catchError((e) => debugPrint(...));` + snack + pop inmediatos. La escritura local es instantánea y se sincroniza sola. Los `await` de LECTURAS y de Firebase Auth sí se mantienen (necesitan respuesta real).
- [x] **Pickers unificados** (2026-06-11): helper `buildDarkPicker` en `lib/core/utils/picker_theme.dart` (tema oscuro + formato 12h AM/PM + color del AM/PM) usado por TODOS los date/time pickers — no duplicar más temas de picker. El formato 12h requirió `locale: Locale('es', 'US')` en `app.dart` (única variante de español con reloj de 12h en los datos de Flutter; los textos siguen en español).
- [x] **Fix:** editar un recordatorio ya no borra su hora/fecha (faltaba prellenar `startTimeController` y `_selectedDate` en `initState`).

- [x] **Pulido de Horario y Home** (2026-06-11): horas 12h en toda la UI; grid del horario adaptado al ancho de pantalla (7 días visibles) con pinch para acercar y doble tap para restaurar; validación del periodo POR DÍA (no por semana); navegación de semanas con `< >` y tap en título = semana actual; "Próximos" = 7 días rodantes agrupados por día colapsable; pantalla "Pendientes Futuros" (30 días) desde "Ver Todo"; hora de fin en cards de cursos; día en el detalle de sesión; FAB `Icons.apps`; ícono campana para recordatorios; AppBar y empty states unificados en las 4 pantallas gestionables (`DarkAppBar` ahora acepta `actions`).
- [x] **Recordatorios rediseñados** (2026-06-11): cada frecuencia muestra SOLO sus campos (Una vez: fecha; Diario: nada extra; Semanal: días; Mensual: primera fecha que se repite cada mes — ahora SÍ genera cards). Presupuesto como toggle. Validaciones por frecuencia. Al guardar se limpian los campos que no aplican.
- [x] **COMPARTIR entre usuarios** (2026-06-11): por correo + copia + bandeja de aceptación. Modelo `SharedItem` (`lib/models/shared_item.dart`) + `SharedItemRepository` (busca usuario por email con `limit(1)`, send/inbox/accept/reject). Sheet de envío reutilizable `lib/core/widgets/share_sheet.dart` con payloads por tipo (SIN `userId` ni ids de vínculos: curso viaja sin periodo, apunte sin curso). Botón compartir en tiles de recordatorios/cursos/periodos y en el editor de apuntes. Bandeja en la pestaña COMPARTIR: aceptar copia el recurso a tu cuenta, rechazar lo descarta.
  - **Firebase (ya configurado, no repetir):** reglas nuevas — `users` permite `list` con `limit == 1` (búsqueda por correo) y bloque propio para `shared_items` (create solo a nombre propio; read/delete solo remitente o destinatario). Índice compuesto: `shared_items` (`toUserId` ↑ + `createdAt` ↓).
  - Convención: los correos en `users` se guardan en minúsculas (`.toLowerCase()` en registro; Google ya los da así).

**Descartado (2026-06-11):**
- ~~Entidad `Classroom`~~ — `CourseSession.roomName` ya cubre el aula por sesión; una entidad con CRUD propio no aporta valor que justifique 3 pantallas más.
- ~~Entidad `Note`~~ — ya implementada (Apuntes).
- ~~Navegación temporal en Horario~~ — ya implementada (flechas `< >` + validación por día).

- [x] **Entidad `Teacher`** (2026-06-11): modelo (`name` + `email?` + `phone?`) + `TeacherRepository` (sin orderBy en query — ordena por nombre en cliente para NO necesitar índice compuesto) + pantallas de gestión (`teacher_screen.dart` / `create_teacher_screen.dart`, acceso desde el FAB del Home). Vínculo `teacherId` opcional en Course con toggle+selector en el formulario (mismo patrón que periodo). Nombre del profesor visible en el tile del curso y en el detalle de sesión del Horario. Eliminar un profesor deja los cursos "sin profesor" (el vínculo huérfano simplemente no se muestra). Bonus fix: editar un curso ya no resetea su color (faltaba prellenar `_selectedColor`).

- [x] **Paquete "validaciones al guardar"** (2026-06-11):
   - Detección de conflictos de horario al guardar curso: compara rangos por día contra los demás cursos del MISMO periodo (`inicioA < finB && inicioB < finA`); diálogo de advertencia con "Guardar Igual" (no bloquea). Usa `watchAll().first` (sirve del cache offline).
   - Al editar fechas de un periodo con cursos vinculados: diálogo "Este periodo tiene N cursos; cambiar las fechas puede ocultarlos... ¿Continuar?". Solo si las fechas realmente cambiaron.

**Pendiente (roadmap final):**
3. **Notificaciones locales** (`flutter_local_notifications`): el ícono de campana del Home abre un modal de configuración con avisos configurables ("15 min antes" + agregar más: 10, 5...) que aplican a cursos y recordatorios con hora. Es la feature más laboriosa: permisos Android 13+, programación recurrente y reprogramación al cambiar datos.
4. **Recordatorio por voz (versión simple):** plugin `speech_to_text` (reconocimiento del sistema, gratis, sin backend, es compatible con español y offline) — botón de micrófono que dicta el NOMBRE del recordatorio; fecha/hora se eligen con los pickers normales. Whisper/LLM descartados por costo y complejidad.

### Sprint 3 (posterior)
- ~~Modo offline + sync~~ — ya implementado (2026-06-11).
- ~~Modo Focus / Pomodoro~~ — DESCARTADO (2026-06-11).
- ~~Botón "¿Cómo vas?"~~ — DESCARTADO (2026-06-11).
- ~~Mensajes motivacionales con API de IA~~ — DESCARTADO (2026-06-11): requería Functions como proxy de la key.

### Sprint 4 (avanzado)
- ~~Compartir cursos / recordatorios / notas~~ — ya implementado in-app por correo (2026-06-11). Queda como idea opcional: QR para compartir cara a cara.
- ~~Recordatorios contextuales basados en clima~~ — DESCARTADO (2026-06-11).
- ~~Exportar reportes en PDF~~ — DESCARTADO (2026-06-11).

### Sprint 5 (ambicioso)
- ~~Whisper + LLM~~ — reemplazado por versión simple con `speech_to_text` (ver Pendiente del Sprint 2).

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

### Bloque E - Calificaciones (Grade) ✅ CERRADO
- [x] Crear modelo `Grade` en `lib/models/grade.dart`.
- [x] Crear `GradeRepository` en `lib/data/grade_repository.dart` (CRUD + watchByCourse).
- [x] Crear `lib/features/grade/grade_screen.dart` (lista de notas por curso + promedio actual).
- [x] Crear `lib/features/grade/create_grade_screen.dart` (form: título, valor, máximo, peso).
- [x] Implementar validación: suma de pesos ≤ 100, con feedback visual.
- [x] Calcular promedio ponderado en el header de `GradeScreen` (escala 0-20).
- [x] Acceso a `GradeScreen` desde el ícono de calificaciones en cada curso (`course_screen.dart`).

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
- [x] `home_screen.dart` bottom nav (`bottom_nav_bar.dart`): "HOME/SCHEDULE/SHARE/PROFILE" → "INICIO/HORARIO/COMPARTIR/PERFIL".
- [x] `home_screen.dart` stats: labels "Recordatorios/Cursos/Periodos" (se cambió "Apuntes" por "Periodos" porque Apuntes aún no existe como entidad).
- [x] `schedule_repository.dart`: subtitulos "Course", "Finance • $freq", "Activity • $freq" → equivalentes en español.
- [x] `login_screen.dart`: snackbars de error y éxito a español.
- [x] `register_screen.dart`: "User created successfully!" → "Cuenta creada con éxito" y todos los mensajes.
- [x] **Convertir labels UPPERCASE a Title Case** en `login_screen.dart`, `create_period_screen.dart`, `create_course_screen.dart`. (Verificado: `AppLabel` no aplica `.toUpperCase()`; los textos fuente ya están en Title Case.)

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
| Classroom DESCARTADA como entidad (2026-06-11) | `CourseSession.roomName` ya cubre el aula por sesión; el CRUD propio no justifica su costo. |
| Teacher SÍ como entidad con CRUD (2026-06-11) | Decisión del equipo: más limpio, permite reutilizar profesores entre cursos. Vínculo opcional `teacherId` en Course. |
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

- ~~API de IA para mensajes motivacionales~~ — DESCARTADA la feature (2026-06-11).
- ~~Permisos al compartir recursos~~ — RESUELTO (2026-06-11): se comparte una COPIA independiente con bandeja de aceptación; no hay edición compartida ni revocación que gestionar.
- ~~Algoritmo de detección de conflictos~~ — DECIDIDO (2026-06-11): advertencia, no bloqueo.
- ~~Whisper~~ — RESUELTO (2026-06-11): `speech_to_text` on-device; sin parser de lenguaje natural (la fecha se elige con pickers).

---

## 9. Estado actual de la app

### Lo que funciona (al cierre de Bloques A + B + C + D + E + F + G + Home reactivo + inicio de Sprint 2)
- **AuthGate (Sprint 2):** la app abre directo en Home si hay sesión guardada, o en Login si no, vía `StreamBuilder` sobre `authStateChanges()`. Firebase Auth persiste la sesión en el dispositivo.
- **Icono propio + nombre "Reminder App":** icono adaptativo (campana sobre gradiente morado) en Android e iOS; nombre instalado ya no es `reminder_app`.
- Registro con selector de avatar (10 íconos) + login con Firebase Auth.
- Cerrar sesión vía menú al tocar avatar en home.
- Avatar mostrado en HomeScreen header.
- CRUD de Periodos.
- CRUD de Cursos con **sesiones múltiples** (día + hora inicio/fin + aula por sesión + apunte por curso).
- CRUD de Recordatorios (UI ya 100% renombrada a "Recordatorios" — **Bloque F cerrado**).
- **Calificaciones (Bloque E cerrado):** CRUD de `Grade` por curso, promedio ponderado en escala 0-20, validación de suma de pesos ≤ 100% con feedback visual. Acceso desde el ícono de calificaciones en cada curso (`course_screen.dart`).
- **Traducción UI completa (Bloque G cerrado):** bottom nav, snackbars de login/register y todos los labels en español/Title Case.
- **Rebranding del login:** título "Recuérdalo" + slogan "TU GALERÍA DE INTENCIONES".
- Pantalla Schedule semanal en grid **con selector manual de periodos** (filtra cursos por periodo; "Todos los periodos" por defecto).
- **Home reactivo con StreamBuilder:** stats reales (Recordatorios/Cursos/Periodos) + "Pendientes Hoy" + "Próximos" se actualizan automáticamente al crear/editar/borrar cursos o recordatorios. `ScheduleRepository` refactorizado a funciones puras de filtrado.
- **Filtro automático por periodo activo en Home:** cursos de periodos cuyo rango de fechas no incluye "hoy" no aparecen; cursos sin periodo siempre visibles.
- **Reminders recurrentes en "Próximos":** Diario/Semanal generan una card por cada día restante de la semana; "Una vez" se acota al fin de semana.
- `SessionEditorSheet`: TimePicker en tema oscuro consistente con DatePicker, validación de errores inline dentro del modal (sin SnackBar oculto detrás).
- UI dark mode con identidad visual sólida (lo mejor evaluado).
- Helpers de formato de hora 24h↔12h en `lib/core/utils/time_helpers.dart`.
- Bottomsheet reutilizable `SessionEditorSheet` para crear/editar sesión.

### Lo que está roto / pendiente
- Pantalla Share es placeholder vacío — no entrar en la demo (Profile ya está implementada).

### Deuda técnica conocida
- `schedule_screen.dart`: colores hardcoded (Scaffold, header, grid, modal de detalle) y carga manual con `Future` en vez de `CourseRepository.watchAll()` con StreamBuilder. (Los `print` con emojis, los días en inglés y los `withOpacity` deprecados ya se corrigieron el 2026-06-10.)
- 6 lints info restantes en `flutter analyze`: 3 `use_super_parameters` (color_selector, notes_screen, create_note_screen), parámetro `sum` en `grade_repository.dart:95`, y 2 avisos menores en `auth_service.dart` (nullable innecesario y `await` sobre no-Future).
- Colores hardcoded en `lib/core/widgets/bottom_nav_bar.dart` — migrar a `AppColors`.
- Tema oscuro de pickers (`showDatePicker`, `showTimePicker`) está duplicado entre `app_date_picker_field.dart` y `session_editor_sheet.dart` — extraer a helper si aparece un tercer uso (regla de tres).
- Cosméticos en `home_screen.dart`: typo `upcoming . isEmpty` (línea ~226, Dart lo acepta), clase de estado `_HomeScreen` debería ser `_HomeScreenState` (convención).
- Comentarios con "actividad" en `reminder_repository.dart` — no UI, sin urgencia.
- Typo histórico `AppColors.organe` → corregido a `orange` el 2026-05-21.

---

## 10. Estabilización del 2026-06-10

Sesión de cierre de bugs tras los commits del 2026-06-05. Todo verificado con `flutter analyze` (41 → 24 issues, los restantes son deuda vieja).

### Firebase (configuración compartida — ya hecho, no repetir)
- **Reglas de Firestore de producción publicadas.** El test mode expiró el 2026-06-06 y TODA la app fallaba con `permission-denied`. Las reglas nuevas exigen sesión iniciada y que cada documento pertenezca al usuario (`userId` == uid; en `users/` el ID del doc es el uid). Regla derivada: toda colección nueva DEBE guardar campo `userId` y toda query DEBE filtrar por él.
- **7 índices compuestos creados** (reminders, courses, notes: `userId`+`createdAt`; periods: `userId`+`startDate`; grades: `userId`+`createdAt` y `userId`+`courseId`+`createdAt`; notes: `userId`+`courseId`+`createdAt`).

### Sistema de mensajes coherente (NUEVA CONVENCIÓN OBLIGATORIA)
- `lib/core/utils/app_feedback.dart`: `showSuccessSnack(context, msg)` / `showErrorSnack(context, msg)`. Único estilo de SnackBar en la app.
- `lib/core/widgets/status_views.dart`: `AppLoadingView` y `AppErrorView(message, error)` para StreamBuilder/FutureBuilder.
- **Regla: jamás mostrar `$e` ni `${snapshot.error}` al usuario.** Mensaje en español por el helper + `debugPrint` del detalle técnico. Nada de `ScaffoldMessenger` directo ni `print`.
- **Regla: en modales (bottomsheets/diálogos) los errores se muestran inline** (texto dentro del propio modal, con `StatefulBuilder` si hace falta estado local); un SnackBar disparado con el modal abierto queda oculto detrás. SnackBar solo después de cerrar el modal (ej. éxito → `pop` → snack). Precedentes: `session_editor_sheet.dart` y el sheet de recuperar contraseña en `login_screen.dart`.
- Colores semánticos `AppColors.success` / `AppColors.error`.

### Errores de autenticación en español
- `authErrorMessage(FirebaseAuthException)` en `lib/services/auth_service.dart`: mapea códigos a español. Clave: firebase_auth 6.x devuelve `invalid-credential` (ya no `wrong-password`/`user-not-found`). Usada en login (email y Google) y register. El default nunca expone `e.message` (inglés).
- Cancelar el prompt de Google se absorbe en el servicio (`GoogleSignInExceptionCode.canceled` → null, sin mensaje); otros errores se relanzan a la pantalla.

### Localización de fechas
- `flutter_localizations` + `locale: es` en `MaterialApp` (`app.dart`): DatePicker/TimePicker en español y habilita `DateFormat(..., 'es')`.
- Formato numérico unificado a **dd/mm/aaaa**: `formatShortDate()` en `lib/core/utils/date_helpers.dart` (reemplazó 4 copias privadas de `_formatDate` + el formato gringo m/d/y del picker). El parser de `create_period_screen` lee día-primero (cambiar formato y parser SIEMPRE juntos).
- Horario: días Lun-Dom y mes en español.

### Otros fixes
- Apuntes 100% en español (pantallas, diálogo de eliminar, hints, empty states).
- Bug de `if` sin llaves en `create_note_screen` (el `setState` se ejecutaba aunque el widget estuviera destruido). Regla: siempre llaves en los `if`.
- Guardas `if (!mounted) return;` tras `await` antes de usar `context` (lint `use_build_context_synchronously`).
- Eliminados: `print` de producción (repos + schedule), código muerto en `user_repository`, imports sin uso.
- Pantallas de apuntes alineadas a la paleta (`AppColors.surface`/`background`/`purplePrimary` en vez de literales).
- Decisión: `auth_service` NO hace merge del perfil en cada login Google (pisaría ediciones del usuario en Perfil); solo crea el doc si no existe.
