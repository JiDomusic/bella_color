# BELLA COLOR - Manual de Uso

## Que es Bella Color?

Es un sistema de turnos online para tu salon de belleza. Tus clientas reservan desde el celular, vos gestionas todo desde el panel de admin. Funciona en el navegador, no hay que instalar nada.

---

## PRIMER INGRESO (para salones nuevos)

1. Te mandamos por WhatsApp tu **email** y una **contrasena temporal**
2. Abri el link de tu salon
3. Toca el boton **"Admin"** (arriba a la derecha, dorado)
4. Pone el email y la contrasena temporal
5. Toca **"Ingresar"**

### Onboarding (configuracion inicial)

La primera vez que entras, el sistema te muestra una pantalla de **"Configuracion inicial"**. Ahi tenes que completar los datos de tu salon:

1. **Logo**: toca el icono de la camara para subir el logo de tu salon
2. **Nombre del salon** (obligatorio): el nombre de tu negocio
3. **Subtitulo**: ej "Peluqueria & Estetica"
4. **Slogan**: una frase corta
5. **Direccion, Ciudad, Provincia**: donde queda tu salon
6. **Email de contacto**: para que te escriban tus clientas
7. **Telefono**: numero fijo o celular
8. **WhatsApp**: tu numero de WhatsApp (con codigo de area, ej: 3411234567)
9. Toca **"Completar configuracion"**

Una vez que completas el onboarding, pasas al panel de admin y no vuelve a aparecer.

### Cambiar la contrasena temporal

Es **MUY IMPORTANTE** que cambies la contrasena temporal por una propia:

1. En el panel de admin, toca el **candadito** (arriba a la derecha)
2. Escribi tu **nueva contrasena** (minimo 8 caracteres)
3. Repetila en el segundo campo
4. Toca **"Guardar"**

A partir de ahora entras con tu nueva contrasena.

---

## COMO ENTRAR AL PANEL DE ADMIN

1. Abri el link de tu salon
2. Toca el boton **"Admin"** (arriba a la derecha, dorado)
3. Pone tu **email** y **contrasena**
4. Toca **"Ingresar"**

### Botones de la barra superior:

- **Casa** (dorado): vuelve a la pagina principal que ven tus clientas
- **Candado**: cambiar contrasena
- **Salir**: cierra sesion (te pide confirmacion)

---

## CONFIGURAR TU SALON (8 pestanas)

### Pestana TURNOS
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

#### Enviar recordatorios por WhatsApp

Arriba de la lista de turnos hay un boton **"Enviar recordatorios de mañana"**:

1. Toca el boton
2. Se abre una lista con todos los turnos **confirmados de mañana**
3. Cada turno tiene un **icono de WhatsApp** (verde) al costado
4. Toca el icono de WhatsApp de la clienta que quieras recordar
5. Se abre WhatsApp con el **mensaje de recordatorio ya escrito** (nombre, servicio, hora, codigo)
6. Solo tenes que tocar **enviar** en WhatsApp
7. El turno se marca como "recordatorio enviado" (check verde) para que no lo envies dos veces
8. Repeti con cada clienta

**Tip**: Hacelo el dia anterior por la tarde, asi tus clientas tienen tiempo de confirmar o cancelar.

### Pestana PROFESIONALES
Las personas que atienden en tu salon.

1. Toca **"Agregar Profesional"**
2. Pone el **nombre** (ej: "Maria")
3. Pone la **especialidad** (ej: "Manicure y pedicure")
4. Opcionalmente subi una **foto** tocando el circulo de la camara
5. Toca **"Crear"**
6. Repeti para cada profesional

- Toca el nombre de un profesional para **editarlo** (cambiar nombre, especialidad o foto)
- El switch al lado de cada nombre lo activa/desactiva (sin borrarlo)

### Pestana SERVICIOS
Lo que ofrece tu salon.

1. Toca **"Agregar Servicio"**
2. Llena:
   - **Nombre**: ej "Manicure semipermanente"
   - **Categoria**: elige de la lista (unas, maquillaje, masajes, depilacion, pestanas, cejas, facial, cabello, corporal, otro)
   - **Duracion**: en minutos (ej: 60)
   - **Precio**: opcional (ej: 5000)
   - **Imagen**: opcionalmente subi una foto del servicio
3. Toca **"Crear"**
4. Repeti para cada servicio

- Toca un servicio para **editarlo** (cambiar nombre, duracion, precio, imagen)

### Pestana HORARIOS
Dias y horas que atiende tu salon.

1. Toca **"Editar Horarios"**
2. Pone:
   - **Hora inicio**: ej "09:00"
   - **Hora fin**: ej "18:00"
   - **Intervalo**: cada cuantos minutos hay un turno (ej: 30)
3. Selecciona los **dias** que abris (los chips azules). Ej: Lun a Sab
4. Toca **"Guardar"**

### Pestana BLOQUEOS
Para bloquear dias o horarios especificos (feriados, vacaciones, etc).

1. Toca **"Agregar Bloqueo"**
2. Selecciona la **fecha**
3. Si es todo el dia: activa **"Dia completo"**
4. Si es un horario especifico: pone la hora (ej: "14:00")
5. Pone el **motivo** (ej: "Feriado")
6. Toca **"Crear"**

### Pestana ESPERA
Lista de personas que quisieron turno pero no habia disponibilidad.

- Se ve el nombre, telefono y fecha
- Toca el icono de **WhatsApp** (verde) para avisarle que se libero un turno
- Toca la **papelera** roja para borrar la entrada

### Pestana REPORTES
Estadisticas de tu salon.

1. Selecciona un **rango de fechas** (desde - hasta)
2. Toca **"Generar reporte"**
3. Ves:
   - **Total de turnos** en ese periodo
   - **% de No Show** (clientas que no vinieron)
   - **% de Cancelacion**
   - **Dia mas ocupado** de la semana
   - **Horario mas ocupado**
   - **Servicio mas pedido**
   - **Profesional mas ocupada**
4. Graficos de barras por dia, hora, servicio y profesional

### Pestana SALON
Configuracion completa de tu salon. Aca podes cambiar todo:

**Datos basicos:**
- Nombre, subtitulo, slogan
- Direccion, ciudad, provincia
- Email, telefono, WhatsApp

**Imagenes:**
- **Logo color**: el logo que se ve en la pagina
- **Logo blanco**: version en blanco (opcional)
- **Imagen de fondo**: una foto de tu salon

Para subir una imagen, toca el recuadro con el icono de camara. Para quitar una imagen ya subida, toca la X roja.

**Colores:**
- **Color primario**: el color principal de tu salon (textos, titulos)
- **Color secundario**: complementario
- **Color terciario**: detalles
- **Color acento**: botones y destacados

Toca el circulito de color para abrir el **selector de colores** y elegir el que te guste.

**Reglas de reserva:**
- **Anticipacion maxima**: hasta cuantos dias adelante pueden reservar (ej: 30)
- **Auto-liberacion**: si la clienta no confirma en X minutos, el turno se libera solo
- **Ventana de confirmacion**: cuantas horas tiene la clienta para confirmar
- **Recordatorio**: cuantas horas antes se envia el recordatorio
- **Dia cerrado**: que dia de la semana no atendes

Toca **"Guardar cambios"** cuando termines.

Abajo de todo hay un boton de **"Contactar Soporte"** para hablarnos por WhatsApp y el boton de **"Cambiar contrasena"**.

---

## COMO RESERVAN TUS CLIENTAS

Tus clientas abren el link de tu salon y ven tu pagina con los servicios, profesionales y el boton **"Reservar Turno"**.

### Reservar (4 pasos):

**Paso 1** - Elige el servicio que quiere

**Paso 2** - Elige una profesional (o "Sin preferencia")

**Paso 3** - Elige fecha y hora disponible

**Paso 4** - Pone su nombre y telefono, y toca **"Confirmar Turno"**

Despues de reservar recibe un **codigo de confirmacion** (6 letras/numeros) y puede:
- **Confirmar por WhatsApp**: toca el boton verde para mandarte el mensaje por WhatsApp
- **Copiar el codigo**: toca el codigo para copiarlo

### Confirmar con codigo

Si la clienta ya tiene su codigo, puede tocarlo desde la pagina principal:

1. En la pagina de tu salon, toca **"Tengo un codigo de turno"**
2. Escribe el codigo (6 caracteres)
3. Toca **"Confirmar"**
4. Se muestran los datos del turno y se confirma automaticamente

### Importante:
- La clienta tiene **2 horas** para confirmar su turno (configurable)
- Si no confirma, el turno se libera automaticamente para otra persona

---

## SUSCRIPCION

- Tenes **15 dias gratis** para probar el sistema
- Despues de los 15 dias, el pago es mensual
- Vas a ver un aviso en tu panel cuando se acerque el vencimiento
- Si el pago se atrasa, el sistema se suspende automaticamente despues de 5 dias de gracia
- Para reactivar, contactanos por WhatsApp

---

## PREGUNTAS FRECUENTES

**La contrasena que me dieron no funciona?**
Probablemente usaste la temporal que te mandamos. Toca el candadito en el admin para cambiarla por una tuya.

**Como veo mi pagina como la ven mis clientas?**
Toca el boton de la **casita** (dorado, arriba a la derecha en el admin).

**Puedo cambiar los colores de mi pagina?**
Si! Anda a la pestana **Salon** y toca los circulitos de colores para cambiar cada uno.

**Como subo fotos?**
En la pestana **Profesionales**, **Servicios** o **Salon**, toca el icono de la camara para elegir una foto de tu galeria.

**Como envio recordatorios a mis clientas?**
En la pestana **Turnos**, toca **"Enviar recordatorios de mañana"**. Se abre WhatsApp con el mensaje listo para cada clienta. Solo tenes que darle enviar.

---

## AYUDA

Si algo no funciona, contactanos por WhatsApp desde el panel de admin (pestana Salon > "Contactar Soporte") o directo al numero de abajo.

---

*Desarrollado por Programacion JJ - WhatsApp 3413363551*
