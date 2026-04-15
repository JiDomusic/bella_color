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

## CONFIGURAR TU SALON (10 pestanas)

### Pestana TURNOS
Aca se ven los turnos del dia.

- **Solapas de categoria**: filtra los turnos por tipo de servicio (Todos, Uñas, Cabello, etc.)
- Selecciona una **fecha** tocando el calendario arriba
- Cada turno muestra: hora, nombre del cliente, servicio, profesional, telefono, codigo, estado
- **Botones de accion** en cada turno:
  - **Confirmar**: cuando la clienta confirma que va a venir
  - **Atender**: cuando llega y empieza el servicio
  - **Completar**: cuando termino
  - **No Show**: si no vino
  - **Cancelar**: si cancela
  - **WhatsApp**: aparece si hay telefono; abre chat directo con la clienta
  - **Comprobante**: aparece si la clienta subio comprobante de seña; tocalo para ver la imagen

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
- Toca **"Ver historial"** para ver las estadisticas de cada profesional:
  - Total de turnos atendidos
  - Turnos completados, cancelados y no-show
  - Lista detallada de turnos completados con fecha, hora y servicio

### Pestana SERVICIOS
Lo que ofrece tu salon.

- **Solapas de categoria**: filtra los servicios por tipo (Todos, Uñas, Cabello, etc.). Solo aparecen las categorias que tienen servicios.

1. Toca **"Agregar Servicio"**
2. Llena:
   - **Nombre**: ej "Manicure semipermanente"
   - **Categoria**: elige de la lista (unas, maquillaje, masajes, depilacion, pestanas, cejas, facial, cabello, corporal, otro)
   - **Duracion**: en minutos (ej: 60)
   - **Precio efectivo**: precio para pago en efectivo (ej: 5000)
   - **Precio tarjeta**: precio para pago con tarjeta (ej: 5500). Opcional.
   - **Descuento efectivo %**: descuento para pago en efectivo (ej: 10)
   - **Descuento tarjeta %**: descuento para pago con tarjeta (ej: 5)
   - **Imagen**: opcionalmente subi una foto del servicio
3. Toca **"Crear"**
4. Repeti para cada servicio

- Toca un servicio para **editarlo** (cambiar nombre, duracion, precios, imagen)
- Las clientas ven ambos precios (efectivo y tarjeta) al reservar

#### Solapamiento de servicios (NUEVO)

Algunos servicios tienen **tiempo de espera** donde la clienta queda sola procesando (ej: color, alisado, permanente). En esos casos, la profesional puede atender a otra clienta mientras tanto.

Para activarlo:

1. Al crear o editar un servicio, busca el switch **"Permite solapamiento"**
2. Activalo en servicios donde **la clienta queda procesando sola** (ej: color, alisado)
3. Dejalo desactivado en servicios de **atencion continua** (ej: corte, cejas, unas)

Ademas, en la pestana **Profesionales**, cada profesional tiene un campo **"Turnos simultaneos"**:
- Pone **cuantas clientas puede atender a la vez** (ej: 3 para una colorista)
- Si la profesional solo atiende una clienta a la vez, deja el **1** (que viene por defecto)

**Ejemplo**: Laura (colorista, turnos simultaneos = 3) esta haciendo un color a las 10:00. Otra clienta puede reservar cejas a las 10:00 con Laura, porque el color permite solapamiento. Pero no puede reservar un corte a las 10:00, porque el corte no permite solapamiento.

**Importante**: La duracion del servicio ahora se tiene en cuenta. Si un color dura 90 minutos y empieza a las 10:00, los horarios de las 10:30 y 11:00 se marcan como ocupados para esa profesional (salvo que haya solapamiento).

### Pestana HORARIOS
Dias y horas que atiende tu salon.

1. Toca **"Editar Horarios"**
2. Pone:
   - **Hora inicio**: ej "09:00"
   - **Hora fin**: ej "18:00"
   - **Intervalo**: cada cuantos minutos hay un turno (ej: 30)
3. Selecciona los **dias** que abris (los chips azules). Ej: Lun a Sab
4. Toca **"Guardar"**

### Pestana CERRAR DIAS (Bloqueos por categoria)
Bloquea dias u horarios especificos. Podes bloquear **por categoria** de servicio o **en general** para todo el salon.

**Solapas de categoria**: arriba del calendario ves las solapas (General, Uñas, Cabello, etc.). Solo aparecen las categorias que tienen servicios cargados.

#### Bloquear todo el salon (feriado, vacaciones):
1. Toca la solapa **"General"**
2. Selecciona el dia en el calendario
3. Toca **"Bloquear General"**
4. Activa **"Dia completo"**
5. Pone el motivo y toca **"Bloquear"**

#### Bloquear solo una categoria (ej: Nati hace uñas de 14 a 16 y no puede hacer pestañas):
1. Toca la solapa **"Pestañas"**
2. Selecciona el dia en el calendario
3. Toca **"Bloquear Pestañas"**
4. Desactiva "Dia completo"
5. Elegí **Desde: 14:00** y **Hasta: 16:00**
6. Toca **"Bloquear"**

**Resultado**: las clientas que quieran pestañas no ven esos horarios. Las que quieran masajes, cabello, etc. **si pueden reservar** en ese mismo horario.

**Importante**: la clienta nunca ve que hay un bloqueo. Solo ve que el horario no esta disponible.

### Pestana ESPERA
Lista de personas que quisieron turno pero no habia disponibilidad.

- Se ve el nombre, telefono y fecha
- Toca el icono de **WhatsApp** (verde) para avisarle que se libero un turno
- Toca la **papelera** roja para borrar la entrada

### Pestana CLIENTES
Historial completo de tus clientas.

- Se crean **automaticamente** al completar un turno.
- Busca por nombre en la barra de busqueda.
- Ficha de cliente:
  - Datos de contacto (nombre, telefono, email) y **boton WhatsApp** para escribirle directo.
  - **Historia Clinica / Observaciones** por visita.
  - **Historial de Turnos** con fechas, estados y servicios.

#### Agregar una observacion:
1. Abri la ficha de la clienta > **Historia Clinica > Agregar**.
2. Completa servicio, profesional y observacion; la fecha se autocompleta.
3. Guarda. Puedes editar (lapiz) o borrar (papelera) cada nota.

**Tip**: Registra productos/tecnicas usados y notas para la proxima visita.

### Pestana STOCK (con codigo de barras)
Control de inventario con scanner y historial de movimientos.

- Alerta roja cuando hay productos bajo minimo.
- Filtro por categoria (unas, cejas, color, peluqueria, etc.).
- Cada producto muestra nombre, marca, categoria, **codigo de barras** y cantidad.

#### Agregar un producto:

1. Toca el boton **"+"** (dorado, arriba a la derecha)
2. Llena:
   - **Nombre del producto**: ej "Esmalte OPI rojo"
   - **Marca**: ej "OPI" (opcional)
   - **Codigo de barras**: podes escanearlo con la camara o ingresarlo manual
   - **Categoria**: elige de la lista
   - **Cantidad**: cuantas unidades tenes
   - **Alerta minimo**: cuando te avisa que hay poco (ej: 5)
3. Toca **"Crear"**

#### Ajustar stock rapido:
- Toca **"+"** o **"-"** al lado de la cantidad para sumar/restar de a 1
- Para ajustes mayores: toca los **3 puntos** > **"Ajustar stock"** > elegi ingreso o egreso, cantidad y motivo

#### Escanear codigo de barras (camara):

1. Toca el icono del **scanner** (al crear o editar un producto)
2. Elegi **"Camara"** para escanear con el celular o **"Manual"** para tipear el codigo
3. Si el producto ya existe, te ofrece sumarle +1 al stock directamente

#### Menu de opciones (3 puntos):

- **Editar**: cambiar datos del producto
- **Ajustar stock**: ingresos o egresos con motivo
- **Historial**: ver todos los movimientos del producto (fecha, cantidad, motivo, usuario)
- **Eliminar**: borrar el producto

**Tip**: El sistema te avisa cuando un producto baja del minimo configurado. Revisa las alertas antes de cerrar el salon.

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

**Banner promocional:**
- **Tipo de banner**: elegi entre **Texto**, **Video** o **Ambos**
  - **Texto**: el banner clasico con mensaje de texto
  - **Video**: un video MP4 que se reproduce automaticamente en la pagina (muted, en loop)
  - **Ambos**: muestra el texto y el video
- Para subir un video: toca **"Subir video"**, elegi un MP4 de tu galeria (maximo 30MB)
- El video se ve en la pagina publica de tu salon como banner promocional

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

**Paso 1** - Elige uno o varios servicios. Si el salon tiene varias categorias (uñas, cabello, etc.) aparecen **chips de filtro** arriba para buscar mas rapido. Puede seleccionar multiples servicios y ver el resumen con la duracion y precio total antes de continuar.

**Paso 2** - Elige una profesional (o "Sin preferencia")

**Paso 3** - Elige fecha y hora disponible (la duracion se calcula sumando todos los servicios elegidos)

**Paso 4** - Pone su nombre y telefono (WhatsApp para coordinar)

**Si el servicio requiere seña/pago anticipado:**
- Ve el **CBU**, **Alias** y **Titular** del salon (puede copiar tocando el icono)
- Ve el **monto** a transferir
- Hace la transferencia desde su banco/app
- Toca **"Subir comprobante de transferencia"** y elige la captura de pantalla
- El sistema **valida automaticamente** que la imagen sea un comprobante real
- Si es valido: aparece **"Comprobante recibido"** y se habilita el boton **"Confirmar Turno"**
- Si no es valido: muestra un mensaje pidiendo que suba una captura de pantalla de la transferencia
- **Sin comprobante valido no puede reservar**

Toca **"Confirmar Turno"**

Despues de reservar recibe un **codigo de confirmacion** (6 letras/numeros) y puede:
- **Confirmar por WhatsApp**: toca el boton verde para mandarte el mensaje por WhatsApp. Si subio comprobante, el mensaje **incluye el link a la imagen** del comprobante para que lo veas.
- **Copiar el codigo**: toca el codigo para copiarlo

### Ver comprobantes desde el panel admin

Si una clienta subio comprobante de transferencia, en la pestana **Turnos** vas a ver un boton naranja **"Comprobante"** en ese turno. Tocalo para ver la imagen del comprobante y verificar que la transferencia es real.

Tambien recibis el link del comprobante por WhatsApp cuando la clienta confirma su turno.

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
- Despues de los 15 dias, el pago es mensual (se vence el mismo dia del mes en que termino tu prueba)
- Vas a ver un aviso en tu panel cuando se acerque el vencimiento, con el alias para transferir
- **El dia de vencimiento el sistema te avisa que vence HOY**
- Si no pagas, **al dia siguiente el sistema se suspende automaticamente**
- Para reactivar: transferi a **programacion.jj** y envia el comprobante por WhatsApp

---

## NOTIFICACIONES AUTOMATICAS

El sistema te avisa automaticamente de cosas importantes:

- **10 minutos antes del cierre**: te recuerda revisar el stock y agregar observaciones de las clientas del dia
- **Stock bajo**: cuando un producto tiene menos unidades del minimo configurado, ves una alerta en la pestana Stock y un aviso en el panel

Estas notificaciones aparecen dentro del panel de admin (no necesitan permisos del navegador).

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

**Puedo poner precios distintos para efectivo y tarjeta?**
Si! Al crear o editar un servicio, tenes campos separados para **precio efectivo** y **precio tarjeta**. Tambien podes poner descuentos por metodo de pago.

**Como agrego observaciones de mis clientas?**
Anda a la pestana **Clientes**, busca la clienta por nombre, tocala y usa el boton **"Agregar"** en la seccion Historia Clinica.

**Como funciona el scanner de codigos de barras?**
En la pestana **Stock**, al agregar o editar un producto, toca el icono del scanner. Podes usar la camara del celular o ingresar el codigo manualmente.

**Puedo subir un video promocional?**
Si! En la pestana **Salon**, busca la seccion de Banner. Cambia el tipo a **Video** o **Ambos** y subi un MP4 (maximo 30MB). Se muestra en tu pagina publica.

---

## AYUDA

Si algo no funciona, contactanos por WhatsApp desde el panel de admin (pestana Salon > "Contactar Soporte") o directo al numero de abajo.

---

*Desarrollado por Programacion JJ - WhatsApp 3413363551*
