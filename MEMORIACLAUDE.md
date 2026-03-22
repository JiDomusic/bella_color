# Memoria Claude - Bella Color

## IMPORTANTE: Proyecto independiente
- Bella Color es un proyecto SEPARADO de Reserva Template
- Tiene su PROPIA base de datos Supabase (no la misma que reserva_template)
- Tiene su PROPIO Firebase hosting (no reserva-jj)
- NO mezclar con reserva_template, son proyectos distintos

## Referencia: Reserva Template (restaurantes)
- URL de referencia: https://reserva-jj.web.app/
- Proyecto hermano: `/home/jido/AndroidStudioProjects/reserva_template/`
- Misma arquitectura: Flutter + Supabase + Firebase Hosting
- Usar como modelo/ejemplo, pero NO compartir datos ni servicios

## Patrón de visibilidad por onboarding (implementar en Bella Color)

### Splash Screen (sin onboarding)
- Cuando un tenant NO completó onboarding, el splash debe mostrar contenido GENÉRICO:
  - Logo: logo genérico de Bella Color (no el del salón vacío/incompleto)
  - Subtitle: "BELLA COLOR" (no el subtitle vacío del tenant)
  - Slogan: "Sistema de turnos para salones de belleza" (no el slogan vacío)
- Cuando el tenant SÍ completó onboarding: mostrar su logo, nombre, slogan reales
- Implementar con un getter: `bool get _usarGenerico => !AppConfig.instance.onboardingCompleted;`

### Home Screen (sin onboarding)
- Mostrar welcome overlay (publicidad de Programación JJ) cuando:
  - Es tenant demo (landing pública)
  - Es tenant real pero sin onboarding
- Lógica: `_showWelcomeOverlay = (tenantId == 'demo' || tenantId.isEmpty || !AppConfig.instance.onboardingCompleted);`
- Cuando es tenant sin onboarding, mostrar banner extra: "Este salón se está configurando. Próximamente estará disponible."
- Parámetro en WelcomeOverlay: `mostrarAvisoPendiente: true`

### 3 niveles de visibilidad
1. `/` (demo) → Publicidad pura de Bella Color / Programación JJ
2. `/mi_salon` (sin onboarding) → Publicidad + aviso "se está configurando"
3. `/mi_salon` (con onboarding) → Vista real del salón con logo, datos, colores

### Caso de uso
Cuando el super admin crea un salón nuevo y le pasa el link al cliente, el cliente NO debe ver una página vacía/rota con datos incompletos. Debe ver la publicidad de Bella Color hasta que complete el onboarding.

## Programación JJ - Branding
- WhatsApp: 3413363551
- "Industria Nacional"
- Productos: Reservas-JJ (restaurantes), Bella Color (belleza/cosmética)

## Notas
- Bella Color es cosmética/belleza, NO restaurantes
- Vertical diferente: servicios, profesionales, turnos (no mesas/áreas)
- Reutilizar patrón: SQL functions, RLS, app_secrets, build scripts, welcome overlay
- Cambiar textos: "restaurante" → "salón", cubiertos → iconos de belleza (content_cut, spa, face, brush)
