# 🚀 GUÍA DE INICIO RÁPIDO - TauroStock V1

## 📲 Configuración Inicial

### Paso 1: Preparar el Entorno
```bash
# Verifica que Flutter está instalado
flutter doctor

# Si hay problemas, actualiza Flutter
flutter upgrade

# Limpia el proyecto (importante!)
flutter clean
```

### Paso 2: Instalar Dependencias
```bash
# Navega al directorio del proyecto
cd app_taurostockv1

# Obtiene todas las dependencias
flutter pub get

# (Opcional) Obtén dependencias del pub.dev
flutter pub upgrade
```

### Paso 3: Ejecutar la Aplicación
```bash
# En emulador/dispositivo conectado
flutter run

# O especifica el dispositivo
flutter run -d emulator-5554

# Para modo release (más rápido)
flutter run --release
```

---

## 💻 Primer Uso

### Pantalla de Login
1. La aplicación abre en la **pantalla de inicio de sesión**
2. Los campos ya vienen con credenciales de demo:
   - **Email**: `admin@tauroglosck.com`
   - **Contraseña**: `admin123`
3. Haz clic en "**Iniciar Sesión**"
4. Se guarda automáticamente tu sesión

### Crear Nueva Cuenta
1. En la pantalla de login, haz clic en "**Regístrate**"
2. Completa los datos:
   - Nombre completo
   - Email (único)
   - Contraseña
   - Confirmar contraseña
   - Selecciona rol (Operador o Administrador)
3. Haz clic en "**Crear Cuenta**"
4. Se abre automáticamente el dashboard

---

## 📊 Dashboard - Pantalla Principal

Una vez iniciada sesión, verás el **Dashboard** con:

### Estadísticas Principales (4 tarjetas)
- **Productos**: Total de productos registrados
- **Clientes**: Total de clientes registrados
- **Stock Bajo**: Productos con inventario bajo
- **Cuentas por Cobrar**: Deuda total de clientes

### Productos con Stock Bajo
- Lista de productos que están por agotarse
- Muestra cantidad actual vs mínima requerida

### Navegación
- Usa la **barra inferior** para cambiar entre secciones
- Ícono de **logout** en la esquina superior derecha

---

## 🏪 Sección 1: GESTIÓN DE PRODUCTOS

### Ver Todos los Productos
1. Toca el botón "**Productos**" en la navegación inferior
2. Se muestra la lista de todos los productos
3. Cada tarjeta muestra:
   - Nombre del producto
   - Código de barras
   - Cantidad en stock
   - Precio de venta

### Buscar Producto
1. En la pantalla de productos, usa el **campo de busca**
2. Escribe por:
   - Nombre del producto
   - Código de barras
3. La lista se filtra automáticamente

### Crear Nuevo Producto
1. Haz clic en el botón **"+"** (esquina inferior derecha)
2. Completa los campos:
   - **Nombre**: Nombre del producto (Ej: "Arroz")
   - **Descripción**: Detalles opcionales
   - **Código de Barras**: Código único (puedes escanear usando el icono de escáner)
   - **Categoría**: Ej: "Alimentos"
   - **Precio de Costo**: Costo para la empresa
   - **Precio de Venta**: Precio al cliente
   - **Cantidad**: Stock actual
   - **Stock Mínimo**: Nivel de alerta
3. Toca el área de imagen para elegir una foto del producto
4. Haz clic en "**Crear Producto**"

### Editar Producto
1. En la lista de productos, toca el menú (⋮) de un producto
2. Selecciona "**Editar**"
3. Modifica los campos necesarios
4. Haz clic en "**Actualizar**"

### Eliminar Producto
1. En la lista, toca el menú (⋮) del producto
2. Selecciona "**Eliminar**"
3. Confirma la eliminación
4. El producto se marca como inactivo

---

## 👥 Sección 2: GESTIÓN DE CLIENTES

## 🏢 Sección 3: GESTIÓN DE PROVEEDORES Y COMPRAS

### Ver Proveedores
1. Toca "Proveedores" en la barra inferior
2. Se muestra lista de proveedores
3. Cada tarjeta muestra nombre, contacto, compras totales y deuda

### Buscar Proveedor
1. Usa el campo de búsqueda
2. Escribe nombre, email o teléfono

### Agregar Proveedor
1. Toca el botón **"+"**
2. Completa nombre, teléfono, email, dirección, ciudad y RFC/NIT
3. Haz clic en "Crear Proveedor"

### Registrar Compra
1. Desde la pantalla de proveedores, toca el icono de carrito
2. Selecciona un proveedor en el desplegable
3. Busca y agrega productos (similar al POS)
4. Define cantidad y confirma
5. Selecciona estado de pago (pendiente o pagado)
6. Toca "Registrar Compra"

### Cuentas por Pagar
1. En la pantalla de compras, toca el icono de dinero (💰)
2. Se listan las compras pendientes
3. Toca "Pagar" para saldar y actualizar la deuda


### Ver Todos los Clientes
1. Toca "**Clientes**" en la navegación inferior
2. Se muestra la lista completa de clientes
3. Cada tarjeta muestra:
   - Nombre del cliente
   - Email
   - Total de compras
   - Deuda (si la hay)

### Buscar Cliente
1. Usa el **campo de búsqueda**
2. Puedes buscar por:
   - Nombre
   - Email
   - Teléfono
3. La lista se filtra en tiempo real

### Crear Nuevo Cliente
1. Haz clic en el botón **"+"**
2. Completa la información:
   - **Nombre**: Nombre completo (requerido)
   - **Teléfono**: Número de contacto
   - **Email**: Correo electrónico
   - **Dirección**: Dirección física
3. Haz clic en "**Crear Cliente**"

### Editar Cliente
1. Toca el menú (⋮) del cliente
2. Selecciona "**Editar**"
3. Modifica los datos
4. Haz clic en "**Actualizar**"

### Ver Clientes con Deuda
- En el dashboard, se muestra el total de deuda
- Cada cliente muestra su saldo en rojo si tiene deuda

---

## 💳 Sección 3: PUNTO DE VENTA (VENTAS)

### Acceder al POS
1. Toca "**Ventas**" en la navegación inferior
2. Se abre la interfaz de punto de venta

(En la sección POS también puedes escanear códigos más adelante si se implementa)

### Composición de la Pantalla
La pantalla se divide en 2 partes:
- **Izquierda**: Catálogo de productos
- **Derecha**: Carrito de compras

### Realizar una Venta

#### Paso 1: Buscar y Seleccionar Productos
1. Busca el producto en el **campo de búsqueda**
2. Se muestra un grid con productos disponibles
3. Haz clic en el producto deseado
4. Se abre un diálogo pidiendo cantidad
5. Ingresa la cantidad deseada
6. Haz clic en "**Agregar**"

#### Paso 2: Revisar el Carrito
En el lado derecho ves:
- Lista de productos agregados
- Cantidad de cada uno
- Subtotal
- Total Final
- Selector de método de pago

#### Paso 3: Configurar Pago
1. Selecciona el método de pago:
   - **Efectivo**: Pago inmediato
   - **Tarjeta**: Pago con tarjeta
   - **Crédito**: Venta a crédito

#### Paso 4: Completar Venta
1. Haz clic en "**Completar Venta**"
2. Se procesa automáticamente:
   - Se guarda la venta en la BD
   - Se actualiza el inventario
   - Se limpia el carrito
3. Se muestra mensaje de éxito

### Modificar Carrito
- **Cambiar cantidad**: Edita el número de items
- **Remover producto**: Haz clic en la "X"

---

## 📈 Dashboard - Análisis de Datos

### Métricas Principales
1. **Total de Productos**: Cantidad de SKU activos
2. **Total de Clientes**: Clientes registrados
3. **Stock Bajo**: Productos bajo mínimo
4. **Deuda Total**: Sumas de cuentas por cobrar

### Alertas
- Los productos con stock bajo se muestran en naranja
- Se actualiza automáticamente después de cada venta

---

## ⚙️ Configuración de Usuario

### Cambiar Contraseña
(Próxima versión)

### Cerrar Sesión
1. Haz clic en el **ícono de logout** (esquina superior derecha)
2. Selecciona "**Cerrar Sesión**"
3. Vuelves a la pantalla de inicio de sesión
4. Tu sesión se guarda para próximos accesos

---

## 🔍 Búsqueda y Filtrado

### Características de Búsqueda
- **Tiempo real**: Se filtra mientras escribes
- **Busca flexible**: No es sensible a mayúsculas
- **Múltiples campos**: Busca en nombre, email, teléfono, etc.

### Ejemplos de Búsqueda
```
Productos:
- "Arroz" → muestra todos los productos con "Arroz"
- "1234" → busca por código de barras

Clientes:
- "Juan" → muestra clientes con "Juan"
- "juan@email.com" → busca por email
- "+509" → busca por teléfono
```

---

## 💾 Datos y Almacenamiento

### ¿Dónde se guardan los datos?
- **Bases de Datos**: SQLite (local en el dispositivo)
- **Sesión**: SharedPreferences
- **No hay sincronización en nube** (próxima versión)

### Hacer Copia de Seguridad
```bash
# En Android Developer Bridge (adb)
adb pull /data/data/app_taurostockv1/databases/taurostockv1.db

# En emulador
adb -e pull /data/data/app_taurostockv1/databases/
```

### Restaurar desde Copia
```bash
adb push taurostockv1.db /data/data/app_taurostockv1/databases/
```

---

## ⚠️ Solución de Problemas

### La app no inicia
```bash
# 1. Limpia el proyecto
flutter clean

# 2. Obtén las dependencias nuevamente
flutter pub get

# 3. Ejecuta de nuevo
flutter run
```

### Errores de base de datos
```bash
# 1. En emulador: Limpia el almacenamiento
adb shell pm clear app_taurostockv1

# 2. O desinstala y reinstala
flutter uninstall
flutter run
```

### La sesión no persiste
```bash
# Verifica permisos de almacenamiento en el dispositivo
# Settings > Apps > TauroStock > Permissions > Storage
```

### Rendimiento lento
```bash
# Ejecuta en modo release (más rápido)
flutter run --release
```

---

## 🎯 Casos de Uso Comunes

### Caso 1: Registrar Nueva Tienda
1. Login con admin
2. Crea los productos (sección Productos)
3. Crea los clientes (sección Clientes)
4. Empieza a vender (sección Ventas)

### Caso 2: Venta Rápida
1. Ve a Ventas
2. Busca cada producto
3. Agrega al carrito
4. Completa la venta

### Caso 3: Reporte de Deudas
1. Ve al Dashboard
2. Ve la tarjeta "Cuentas por Cobrar"
3. En clientes, filtra los que tienen deuda

### Caso 4: Gestión de Inventario
1. Ve a Productos
2. Revisa los con stock bajo (naranja)
3. Edita y aumenta la cantidad
4. O agrega nuevo producto

---

## 💡 Tips y Trucos

### Búsqueda Rápida
- La búsqueda es **instantánea**, no necesitas presionar enter
- Funciona con caracteres parciales
- Es case-insensitive (sin importar mayúsculas)

### Agregar Múltiples de un Producto
1. Haz clic en el producto
2. Ingresa cantidad (ej: 5)
3. Vuelve a hacer clic habra otro
4. Cada uno se suma al carrito

### Métodos de Pago
- **Efectivo**: Se registra inmediatamente
- **Tarjeta**: Simulado (próxima: integraciones reales)
- **Crédito**: Se registra el cliente y su deuda

---

## 📞 Soporte

### Preguntas Frecuentes
**P: ¿Cómo borro todos los datos?**  
R: `Settings > Apps > TauroStock > Storage > Clear Data`

**P: ¿Puedo acceder desde múltiples dispositivos?**  
R: No por ahora, datos locales. Próxima versión tendrá sincronización.

**P: ¿Hay límite de productos?**  
R: No, ilimitado (depende de almacenamiento del dispositivo)

---

## 🎓 Roadmap Educativo

- [x] Nivel 1: Login y Navegación básica
- [x] Nivel 2: CRUD de Productos
- [x] Nivel 3: Gestión de Clientes
- [x] Nivel 4: Punto de Venta Funcional
- [ ] Nivel 5: Reportes avanzados
- [ ] Nivel 6: Sincronización en nube

---

**¡Listo! Ya estás preparado para usar TauroStock. ¡Que disfrutes! 🎉**
