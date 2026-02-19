# 🚁 SEVIGDRONE App

> **"Elevando Sueños, Conquistando Cielos"**

Aplicación oficial para la gestión académica y operativa de pilotos de drones de la academia **Sevigdrone**. Esta herramienta integral permite a los cadetes gestionar su formación, controlar su flota de aeronaves y mantenerse actualizados con el mundo de los UAVs.
## 🚀 Funcionalidades Principales

### 1. 🎓 Academia Virtual
* **Catálogo de Cursos:** Visualización dinámica de cursos disponibles.
* **Gestión de Acceso:** Diferenciación entre cursos adquiridos (Acceso directo) y bloqueados.
* **Integración Comercial:** Enlace directo a WhatsApp para la adquisición de nuevos módulos.

### 2. 🚁 Hangar & Operaciones (SORA)
* **Gestión de Flota:** Registro y control de drones del usuario (Modelo, Peso, Estado).
* **Checklist Pre-Vuelo (SORA):** Sistema de verificación de seguridad basado en normativa MIP. Valida:
    * Estado físico (Hélices, Motores).
    * Batería y Sensores.
    * Condiciones Meteorológicas y Zona VLOS.
* **Feedback Visual:** Indicadores de "Tierra" (Rojo) o "Despegue Autorizado" (Verde).

### 3. 📰 Centro de Noticias Híbrido
* **Noticias Oficiales:** Comunicados internos gestionados por la administración (Firebase).
* **Actualidad Mundial (RSS):** Integración con **Google News** para mostrar noticias de tecnología y drones en tiempo real, con extracción automática de imágenes.

### 4. 🛠️ Panel Administrativo (CMS)
* **Gestión de Contenidos:** CRUD completo para Noticias y Cursos.
* **Subida de Imágenes:** Gestión de multimedia mediante enlaces directos o almacenamiento en la nube.
* **Seguridad:** Acceso restringido únicamente a usuarios con rol de 'admin'.

### 5. 🔐 Seguridad y Autenticación
* Login y Registro con **Firebase Auth**.
* Recuperación de contraseña vía correo electrónico.
* Roles de usuario (Admin vs. Cadete).

---

## 🛠️ Tecnologías Utilizadas

Este proyecto está construido con **Flutter** y sigue una arquitectura limpia y escalable.

* **Frontend:** Flutter (Dart).
* **Backend (BaaS):** Firebase (Google).
    * *Authentication:* Gestión de usuarios.
    * *Cloud Firestore:* Base de datos NoSQL en tiempo real.
    * *Storage:* Almacenamiento de multimedia.
* **Librerías Clave:**
    * `provider` / `setState`: Gestión de estado.
    * `http` & `xml`: Consumo y parseo de RSS Feeds.
    * `url_launcher`: Apertura de enlaces externos.
    * `intl`: Formateo de fechas.
    * `cached_network_image`: Caché avanzado de imágenes.
## 📄 Licencia

Este proyecto es propiedad de **Sevigdrone S.A.S**. Todos los derechos reservados.
Desarrollado por **Adrian**.

---

<div align="center">
  <sub>Construido con 💙 y rotores en Ecuador 🇪🇨</sub>
</div>
