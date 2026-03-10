# BELLA COLOR - Manual de Uso Completo

## Que es Bella Color?

Es un sistema de turnos online para salones de belleza. Tus clientas reservan desde el celular, vos gestionas todo desde el panel de admin. Funciona en el navegador, no hay que instalar nada.

---

## ANTES DE EMPEZAR (una sola vez)

### 1. Preparar la base de datos (Supabase)

Supabase es donde se guardan todos los datos (turnos, clientes, servicios, etc).

**Entrar a Supabase:**
- Abri https://supabase.com/dashboard
- Logueate con tu cuenta

**Ejecutar los scripts SQL:**
- En el menu de la izquierda toca **SQL Editor**
- Vas a ejecutar 3 archivos, UNO POR UNO, en este orden:

**Archivo 1 - Crear tablas:**
- Abri el archivo `sql/001_schema.sql` del proyecto
- Copia TODO el contenido
- Pegalo en el SQL Editor
- Toca el boton verde **Run**
- Tiene que decir "Success"

**Archivo 2 - Seguridad:**
- Abri `sql/002_rls_policies.sql`
- Copia todo, pega, Run
- "Success"

**Archivo 3 - Imagenes:**
- Abri `sql/003_storage_policies.sql`
- Copia todo, pega, Run
- "Success"

**Crear el bucket de imagenes:**
- En el menu izquierdo toca **Storage**
- Toca **New bucket**
- Nombre: `salon-images`
- Public bucket: **APAGADO** (dejalo como esta)
- Toca **Create**

Listo! La base de datos esta lista.

### 2. Subir la app a internet (Deploy)

Esto hace que la app este disponible en https://bella-color.web.app

**Abri una terminal** y escribi estos comandos:

```
cd /home/jido/AndroidStudioProjects/bella_color
flutter build web
firebase login
```

Si te pide loguearte, usa la cuenta **programacionjjj@gmail.com**.

Despues:

```
firebase deploy
```

Espera que termine. Cuando diga "Deploy complete!" ya esta online.

---

## CREAR UN SALON NUEVO (Super Admin)

Vos (Programacion JJ) sos el Super Admin. Vos creas los salones para tus clientas.

### Paso a paso:

1. Abri https://bella-color.web.app
2. La primera vez va a mostrar un error (porque no hay salon "demo"). Esta bien.
3. Toca el boton **Admin**
4. **MANTEN PRESIONADO** el boton Admin (2 segundos). Aparece un dialogo que dice "Super Admin"
5. Escribi el PIN: **987654**
6. Toca **Entrar**
7. Estas en el panel de Super Admin

### Crear el salon:

1. Toca el boton **"Nuevo Salon"** (abajo a la derecha)
2. Llena los datos:
   - **Nombre del salon**: El nombre real del salon. Ej: "Nails by Maria"
   - **Email del admin**: El email de la duena del salon. Ej: "maria@gmail.com"
   - **Contrasena temporal**: Se genera sola. Dejala como esta o cambiala
3. Toca **"Crear Salon"**
4. Aparece una pantalla con toda la info:
   - El **link** del salon (ej: `https://bella-color.web.app?tenant=nails_by_maria`)
   - El **email** y **contrasena**
5. Toca **"Copiar mensaje para WhatsApp"**
6. Abri WhatsApp y pegale el mensaje a tu clienta

El mensaje que se copia dice algo asi:
```
Hola! Tu sistema de turnos esta listo.

Link: https://bella-color.web.app?tenant=nails_by_maria
Email: maria@gmail.com
Contrasena: Abc45kMn

Ingresa al link, logueate y configura tu salon.
```

---

## LA DUENA DEL SALON CONFIGURA TODO (Admin)

Tu clienta (la duena del salon) recibe el mensaje de WhatsApp y hace esto:

### Entrar al admin:

1. Abre el link que le mandaste
2. Toca el boton **"Admin"** (arriba a la derecha, dorado)
3. Pone su **email** y **contrasena**
4. Toca **"Ingresar"**
5. Entra al panel de administracion

### Configurar el salon (7 pestanas):

#### Pestana SALON (la ultima)
Aca ve la info de su salon. Por ahora esta vacio, pero puede ver:
- Nombre, direccion, colores
- Configuracion de tiempos (anticipacion, auto-liberacion, recordatorios)
- Boton de soporte tecnico (te llama a vos por WhatsApp)

#### Pestana PROFESIONALES
Las personas que atienden en el salon.

1. Toca **"Agregar Profesional"**
2. Pone el **nombre** (ej: "Maria")
3. Pone la **especialidad** (ej: "Manicure y pedicure")
4. Toca **"Crear"**
5. Repite para cada profesional

El switch al lado de cada nombre lo activa/desactiva (sin borrarlo).

#### Pestana SERVICIOS
Lo que ofrece el salon.

1. Toca **"Agregar Servicio"**
2. Llena:
   - **Nombre**: ej "Manicure semipermanente"
   - **Categoria**: elige de la lista (unas, maquillaje, masajes, depilacion, pestanas, cejas, facial, cabello, corporal, otro)
   - **Duracion**: en minutos (ej: 60)
   - **Precio**: opcional (ej: 5000)
3. Toca **"Crear"**
4. Repite para cada servicio

#### Pestana HORARIOS
Dias y horas que atiende el salon.

1. Toca **"Editar Horarios"**
2. Pone:
   - **Hora inicio**: ej "09:00"
   - **Hora fin**: ej "18:00"
   - **Intervalo**: cada cuantos minutos hay un turno (ej: 30)
3. Selecciona los **dias** que abre (los chips azules). Ej: Lun a Sab
4. Toca **"Guardar"**

#### Pestana BLOQUEOS
Para bloquear dias o horarios especificos (feriados, vacaciones, etc).

1. Toca **"Agregar Bloqueo"**
2. Selecciona la **fecha**
3. Si es todo el dia: activa **"Dia completo"**
4. Si es un horario especifico: pone la hora (ej: "14:00")
5. Pone el **motivo** (ej: "Feriado")
6. Toca **"Crear"**

#### Pestana TURNOS
Aca se ven los turnos del dia.

- Selecciona una **fecha** tocando el calendario arriba
- Cada turno muestra: hora, nombre del cliente, servicio, profesional, telefono, codigo, estado
- **Botones de accion** en cada turno:
  - **Confirmar**: cuando la clienta confirma que va a venir
  - **Atender**: cuando llega y empieza el servicio
  - **Completar**: cuando termino
  - **No Show**: si no vino
  - **Cancelar**: si cancela

**Flujo normal de un turno:**
```
Pendiente -> Confirmar -> Atender -> Completar
```

#### Pestana ESPERA
Lista de personas que quisieron turno pero no habia disponibilidad.

- Se ve el nombre, telefono y fecha
- Toca el icono de **WhatsApp** (verde) para avisarle que se libero un turno
- Toca la **papelera** roja para borrar la entrada

---

## COMO RESERVAN LAS CLIENTAS

La clienta abre el link del salon (ej: `https://bella-color.web.app?tenant=nails_by_maria`) y ve:

### Pagina del salon:
- Logo y nombre del salon
- Lista de **servicios** con foto, nombre, duracion y precio
- Lista de **profesionales** con foto y especialidad
- Boton grande **"Reservar Turno"**

### Reservar (4 pasos):

**Paso 1 - Elegir servicio:**
- Toca el servicio que quiere (ej: "Manicure semipermanente")

**Paso 2 - Elegir profesional:**
- Elige una profesional de la lista
- O toca **"Sin preferencia"** si no le importa quien la atienda

**Paso 3 - Elegir fecha y hora:**
- Toca el calendario y elige una fecha
- Aparecen los horarios disponibles como circulos
- Los horarios **tachados con rojo** ya no estan disponibles
- Si quedan pocos turnos aparece un banner amarillo: **"Alta demanda"**
- Si queda 1 solo: banner rojo: **"Ultimo turno disponible!"**
- Si no queda ninguno: boton **"Anotarme en lista de espera"**
- Toca un horario disponible y despues **"Continuar"**

**Paso 4 - Datos personales:**
- Llena: nombre, telefono (obligatorios), email y comentarios (opcionales)
- Ve un resumen de lo que eligio
- Toca **"Confirmar Turno"**

### Despues de reservar:
- Ve una pantalla con el **codigo de confirmacion** (ej: "A3K7NP")
- Puede **copiar** el codigo tocandolo
- Puede **confirmar por WhatsApp** tocando el boton verde
- Toca **"Volver al inicio"** para terminar

### Que pasa con el turno?
- La clienta tiene **2 horas** para confirmar (sino se libera automatico)
- El salon recibe el turno en su panel de admin
- Si la clienta no confirma en 2 horas, el turno se libera y queda disponible para otra persona

---

## PARA LANZAR (CHECKLIST)

Antes de decirle a tu clienta que ya esta listo, verifica:

- [ ] Los 3 SQL ejecutados en Supabase (tablas, seguridad, storage)
- [ ] Bucket `salon-images` creado en Supabase Storage (privado)
- [ ] `flutter build web` ejecutado sin errores
- [ ] `firebase deploy` exitoso
- [ ] Abrir https://bella-color.web.app y verificar que carga
- [ ] Crear el salon desde Super Admin (PIN 987654)
- [ ] Verificar que el link del salon funciona (ej: `?tenant=nombre_salon`)
- [ ] La duena del salon se puede loguear con email/contrasena
- [ ] Agregar al menos 1 profesional
- [ ] Agregar al menos 1 servicio
- [ ] Configurar horarios de atencion
- [ ] Probar una reserva completa como clienta
- [ ] Verificar que el turno aparece en el panel de admin
- [ ] Repo en GitHub privado

---

## DATOS IMPORTANTES

| Que | Valor |
|-----|-------|
| URL de la app | https://bella-color.web.app |
| Link de salon | https://bella-color.web.app?tenant=NOMBRE |
| PIN Super Admin | 987654 |
| WhatsApp Soporte | 3413363551 |
| Cuenta Firebase | programacionjjj@gmail.com |
| Supabase Dashboard | https://supabase.com/dashboard |
| Repo GitHub | https://github.com/JiDomusic/bella_color (privado) |

---

## SI ALGO FALLA

- **"No existe el tenant"**: El salon no fue creado todavia. Entra como Super Admin y crealo.
- **La app no carga**: Verifica que hiciste `flutter build web && firebase deploy`.
- **No puedo loguearme**: Verifica email y contrasena. Si la olvidaste, crea el salon de nuevo.
- **No aparecen horarios**: La duena del salon no configuro los horarios. Que entre al admin > Horarios.
- **No aparecen servicios**: La duena no cargo servicios. Que entre al admin > Servicios.
- **Turno se libero solo**: La clienta no confirmo en 2 horas. Es automatico.

---

*Desarrollado por Programacion JJ - WhatsApp 3413363551*
