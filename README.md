# TauroStock V1

Aplicación Flutter (offline-first) para gestión de inventario, ventas y caja orientada a pequeños negocios. Usa SQLite local con Providers para estado y soporta múltiples empresas mediante `businessRuc`.

## Qué hace
- Inventario y precios con códigos de barras, imágenes y categorías personalizables.
- Ventas con carrito, pagos mixtos (efectivo, tarjeta, transferencia, crédito), gestión de deudas y anulaciones con reversa de stock.
- Compras y abastecimiento: registra proveedores, compra items y actualiza inventario.
- Caja: apertura/cierre de sesión con saldos esperados/actuales.
- Finanzas: transacciones rápidas de ingresos/egresos, historial de pagos, cuentas por cobrar/pagar.
- Reportes: dashboard con top productos, ventas últimos 7 días, totales contado/crédito, kardex por producto.
- Multi‑empresa básico: cada registro se asocia a `businessRuc`; el admin crea la empresa al registrarse.

## Arquitectura
- **main.dart**: registra 12 `ChangeNotifierProvider`, tema y rutas (25+ pantallas). Home wrapper decide login vs dashboard.
- **Servicios**:  
  - `services/database_service.dart`: ORM manual + migraciones (14 tablas: users, businesses, products, clients, providers, sales/sale_items/sale_payments, purchases/purchase_items, transactions, kardex, payment_history, cash_sessions, categories, settings). Maneja stock, deudas, kardex, caja, ajustes.  
  - `services/auth_service.dart`: sesión en `SharedPreferences` (email/role/name/flag).
- **Providers**: auth, productos, clientes, proveedores, compras, ventas, carrito, transacciones, caja, categorías, settings; exponen agregados (top productos, ventas 7d, totales crédito, etc.).
- **Modelos**: DTO por tabla (incluye ítems de venta/compra y configuración).  
- **UI**: pantallas de login/registro/seguridad, dashboard, inventario, carrito/checkout, compras, transacciones, caja, categorías, clientes/proveedores, reportes, perfil.

## Flujos clave
- **Autenticación/Registro**: admin crea negocio; empleados quedan `isActive=false` hasta aprobación. Sesión persistida localmente (sin hashing).
- **Venta**: carrito → pagos mixtos → inserta `sales`, `sale_items`, `sale_payments`; descuenta stock y aumenta saldo del cliente si es crédito; anulaciones revierten stock y saldo, registran kardex.
- **Compra**: registra `purchases` e items, aumenta stock y saldo a proveedor si es crédito.
- **Caja**: `cash_sessions` abre/cierra con saldos inicial/esperado/real.
- **Kardex**: cada movimiento de stock queda en `kardex` con previo/nuevo stock.
- **Transacciones/Gastos**: tabla `transactions` para ingresos/egresos rápidos.
- **Categorías**: tabla `categories` con icono/color (picker ampliado).
- **Settings**: `settings` por empresa (logo, moneda, datos fiscales).

## Dependencias y APIs
- Flutter 3.10.7, Provider, sqflite, path_provider, shared_preferences, intl, image_picker, barcode_scan2 (aún sin uso en UI), fl_chart (sin uso), google_fonts (sin uso).  
- Sin APIs HTTP externas; todo es local en el dispositivo.

## Seguridad y privacidad (estado actual)
- Contraseñas en texto plano en SQLite; sesión en `SharedPreferences` sin cifrado.
- Sin políticas de reintentos ni bloqueo; `clearDatabase()` borra todo sin protección.
- Validación de `isActive` sólo parcial; no hay roles granulares ni control por pantalla.
- Imágenes se guardan como rutas locales; sin sandbox adicional.

## Riesgos y brechas
- Pérdida de datos: no hay backup/export ni sincronización multi‑dispositivo.
- Dependencias no usadas (`fl_chart`, `google_fonts`, `barcode_scan2`) pueden limpiarse o integrarse.
- Codificación de strings: varios textos con acentos mal codificados; afecta UX/accesibilidad.
- Sin tests (unit/widget) ni logging estructurado.

## Recomendaciones rápidas para defensa
1) **Seguridad**: hash de contraseñas (bcrypt), cifrar sesión básica, validar `isActive` en login y operaciones sensibles.  
2) **Respaldo**: exportar DB/CSV y botón de respaldo; plan futuro de API REST para sync.  
3) **Roles/Permisos**: aplicar controles de UI/acción por rol y empresa.  
4) **Calidad**: agregar tests a providers y migraciones; lint + CI mínimo.  
5) **UX/Textos**: corregir encoding, mejorar labels accesibles.  
6) **Dependencias**: remover o activar gráficos/barcode/google_fonts para justificar peso.  
7) **Auditoría**: logging de acciones críticas (ventas, anulaciones, caja) y reporte exportable.

## Estructura de datos (resumen)
- `users` (id, email, password, role, isActive, businessRuc), `businesses` (ruc, name…).  
- `products` (stock, cost, price, category, barcode, imagePath, businessRuc) + `kardex`.  
- `sales` + `sale_items` + `sale_payments`; `purchases` + `purchase_items`.  
- `clients` (accountBalance, loyaltyPoints) y `providers` (balance).  
- `payment_history` (abonos clientes/proveedores), `transactions` (ingresos/egresos), `cash_sessions`, `categories`, `settings`.

## Puesta en marcha
```
flutter pub get
flutter run
```
Base de datos se crea/migra en `getApplicationDocumentsDirectory() / taurostockv1.db`; la sesión se limpia en `main()` para desarrollo (`AuthService().logout()`).

## Estado de pruebas
No hay tests configurados. Se recomienda iniciar con tests unitarios de providers y migraciones de `DatabaseService`.

