# TauroStock - Aplicación de Gestión de Inventario y Ventas

## Descripción

TauroStock es una aplicación móvil Flutter para la gestión completa de operaciones comerciales de pequeñas y medianas empresas. Integra inventario, punto de venta móvil, gestión de clientes y proveedores, y reportes financieros.

## Características Principales

- ✅ **Autenticación de Usuario**: Registro e inicio de sesión seguro
- ✅ **Gestión de Inventario**: Crear, editar, eliminar y buscar productos (código de barras y foto de producto)
- ✅ **Control de Stock**: Alertas de stock bajo
- ✅ **Punto de Venta (POS)**: Interfaz touchscreen para ventas rápidas
- ✅ **Gestión de Clientes**: Registro de clientes y seguimiento de deudas
- ✅ **Gestión de Proveedores**: Control de proveedores con compras asociadas
- ✅ **Registro de Compras**: Registrar entradas de mercancía y actualizar inventario
- ✅ **Cuentas por Pagar**: Seguimiento de compras pendientes y pago desde la app
- ✅ **Dashboard**: Resumen de métricas claves del negocio
- ✅ **Base de Datos Local**: SQLite para almacenamiento offline
- ✅ **Múltiples Roles**: Soporte para administrador y operador

## Credenciales de Prueba

```
Email: admin@tauroglosck.com
Contraseña: admin123
Rol: admin
```

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── models/                      # Modelos de datos
│   ├── user.dart
│   ├── product.dart
│   ├── client.dart
│   ├── sale.dart
│   ├── purchase.dart
│   └── provider.dart
├── services/                    # Servicios
│   ├── database_service.dart   # Gestión de base de datos SQLite
│   └── auth_service.dart       # Gestión de autenticación
├── providers/                   # State Management (Provider)
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   ├── client_provider.dart
│   ├── cart_provider.dart
│   └── provider_model_provider.dart
├── screens/                     # Pantallas de la aplicación
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── dashboard_screen.dart
│   ├── main_screen.dart
│   ├── products_screen.dart
│   ├── product_form_screen.dart
│   ├── clients_screen.dart
│   ├── client_form_screen.dart
│   └── sales_screen.dart
├── widgets/                     # Widgets reutilizables
│   └── custom_widgets.dart
└── utils/                       # Utilidades
    └── validators_and_formatters.dart
```

## Dependencias Principales

- **provider**: State Management
- **sqflite**: Base de datos SQLite
- **shared_preferences**: Almacenamiento local
- **intl**: Formateo de fechas y moneda
- **fl_chart**: Gráficos y análisis
- **path_provider**: Acceso a directorios del sistema

## Instalación

> ⚠️ **Permisos adicionales**
> - Para escanear códigos y subir fotos, la aplicación solicitará acceso a la cámara y almacenamiento. Asegúrate de aceptar los permisos en Android/iOS.


1. **Clonar/Descargar el proyecto**
   ```bash
   cd app_taurostockv1
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## Flujos Principales

### 1. Autenticación
- Acceder a la pantalla de login
- Ingresar credenciales (admin@tauroglosck.com / admin123)
- Se guarda la sesión localmente
- Acceso a dashboard

### 2. Gestión de Productos
- Crear nuevos productos con código de barras (puedes escanear desde la pantalla de registro)
- Adjuntar una foto desde la galería para cada producto
- Editar información de productos
- Monitorear stock bajo
- Eliminar productos

### 3. Punto de Venta
- Buscar y seleccionar productos
- Agregar productos al carrito
- Modificar cantidades
- Seleccionar método de pago
- Completar venta (se actualiza el inventario automáticamente)

### 4. Gestión de Clientes
- Registrar nuevos clientes
- Buscar clientes
- Editar información de clientes
- Seguimiento automático de compras y deudas

### 5. Gestión de Proveedores & Compras
- Registrar proveedores con datos de contacto y fiscal
- Buscar y editar proveedores
- Desde la lista de proveedores abrir compras o registrar nuevas
- Registrar compras (entrada) seleccionando proveedor y productos
- Visualizar y pagar cuentas por pagar

### 5. Dashboard
- Visualizar métricas claves
- Alertas de stock bajo
- Estadísticas de clientes y productos

## Uso de la Aplicación

### Inicio de Sesión
1. Abre la aplicación
2. Si no has iniciado sesión, verás la pantalla de login
3. Usa las credenciales de prueba proporcionadas
4. Selecciona "Regístrate" para crear una nueva cuenta

### Navegación Principal
Utiliza la barra de navegación inferior para acceder a:
- **Inicio**: Dashboard con resumen del negocio
- **Ventas**: Punto de venta para realizar transacciones
- **Productos**: Gestión de inventario
- **Clientes**: Gestión de clientes y seguimiento de deudas
- **Proveedores**: Lista de proveedores y acceso a compras/pendientes

### Crear un Producto
1. Ve a la sección "Productos"
2. Haz clic en el botón "+" y completa los campos requeridos
3. Usa el escáner para capturar el código de barras o escríbelo manualmente
4. Toca el recuadro de foto para seleccionar una imagen del producto
5. Haz clic en "Crear Producto"

### Realizar una Venta
1. Ve a la sección "Ventas"
2. Busca los productos deseados
3. Haz clic en un producto para agregar cantidad
4. El producto se agregará al carrito
5. Revisa el total y selecciona el método de pago
6. Haz clic en "Completar Venta"

### Gestionar Clientes
1. Ve a la sección "Clientes"
2. Haz clic en "+" para agregar un nuevo cliente
3. Completa la información del cliente
4. Los clientes estarán disponibles para vincular a ventas

## Funcionalidades Avanzadas

### Compras y Cuentas
- Registro de compras con proveedor y actualización de inventario
- Pantalla de cuentas por pagar para saldar deudas con proveedores


### Búsqueda y Filtrado
- Búsqueda por nombre de producto o código de barras
- Búsqueda de clientes por nombre, email o teléfono

### Alertas de Stock Bajo
- En el dashboard se muestran productos con stock bajo
- Se puede configurar el stock mínimo por producto

### Seguimiento de Deudas
- Automático seguimiento de compras de clientes
- Resumen de clientes con deuda

### Métodos de Pago
- Efectivo
- Tarjeta
- Crédito

## Solución de Problemas

### La aplicación no inicia
- Verifica que Flutter está instalado: `flutter doctor`
- Limpia el proyecto: `flutter clean`
- Reinstala las dependencias: `flutter pub get`

### Errores de base de datos
- Elimina la base de datos anterior
- En el emulador: Settings > Apps > TauroStock > Storage > Clear Data
- En dispositivo físico: Desinstala y reinstala la aplicación

### Sesión se cierra inesperadamente
- Verifica que tienes suficiente almacenamiento
- Comprueba que los permisos están habilitados

## Persistencia de Datos

- **Usuarios**: SQLite (encriptado en contraseña)
- **Productos, Clientes, Ventas**: SQLite local
- **Sesión de Usuario**: SharedPreferences
- **Datos de Aplicación**: Almacenamiento local del dispositivo

## Seguridad

- Las contraseñas se almacenan localmente
- Solo para demostración - en producción usar encriptación adicional
- Cada usuario tiene su propia sesión

## Roadmap Futuro

- [ ] Sincronización en la nube
- [ ] Reportes PDF avanzados
- [ ] Escaneo de códigos de barras
- [ ] Integración de cámara
- [ ] Soporte multi-tienda
- [ ] Análisis predictivo
- [ ] Aplicación web
- [ ] API REST

## Contribuciones

Las contribuciones son bienvenidas. Para cambios importantes:
1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver archivo LICENSE para más detalles.

## Soporte

Para reportar problemas o sugerencias, abre un issue en el repositorio.

---

**Versión**: 1.0.0  
**Última Actualización**: Febrero 2026  
**Estado**: En Desarrollo
