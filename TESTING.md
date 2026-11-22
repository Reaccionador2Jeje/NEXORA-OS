# Probar NEXORA OS

NEXORA OS está en fase experimental. Las imágenes de prueba se construyen automáticamente en GitHub Actions, pero todavía no son versiones estables.

## Descargar una compilación

Abre la ejecución de la edición que quieras probar:

- [NEXORA XFCE4 Live — compilaciones](https://github.com/Reaccionador2Jeje/NEXORA-OS/actions/workflows/build-live.yml)
- [NEXORA Minimal GTK Netinst — compilaciones](https://github.com/Reaccionador2Jeje/NEXORA-OS/actions/workflows/build-iso.yml)

Elige una ejecución que aparezca como **Success** (verde), abre su resumen y descarga el artefacto correspondiente en la sección **Artifacts**:

| Edición | Nombre del artefacto |
| --- | --- |
| XFCE4 Live | `nexora-os-xfce4-live-amd64` |
| Minimal GTK Netinst | `nexora-os-minimal-gtk-netinst-amd64` |

Se necesita iniciar sesión en GitHub y tener acceso de lectura al repositorio. Los artefactos de CI son temporales y se conservan durante 30 días. Las descargas públicas permanentes se habilitarán mediante SourceForge cuando el proyecto esté registrado y configurado.

## Verificar la ISO

Descarga el archivo ISO y su archivo `.sha256` en la misma carpeta. En Linux, abre una terminal en esa carpeta y ejecuta:

```sh
sha256sum --check NOMBRE-DE-LA-ISO.iso.sha256
```

El resultado esperado es `OK`. Si la verificación falla, no utilices esa imagen; vuelve a descargarla y reporta el problema.

## Probar de forma segura

- Empieza en una máquina virtual y usa un disco virtual vacío.
- Para XFCE4 Live, comprueba que el escritorio inicia y que puedes abrir sus aplicaciones principales.
- Para Minimal GTK Netinst, comprueba que aparece el instalador. La instalación requiere conexión a Internet.
- No instales una compilación experimental en un equipo que contenga archivos importantes.
- La prueba automática de CI es headless: comprueba el arranque básico, pero no reemplaza una prueba visual de escritorio ni confirma compatibilidad con todo el hardware.

## Reportar un problema

[Crear un informe de error](https://github.com/Reaccionador2Jeje/NEXORA-OS/issues/new/choose).

Incluye la edición, el enlace de la ejecución, el programa de máquina virtual y el paso donde ocurrió el problema. No incluyas contraseñas, claves privadas ni información personal.

## Estado

NEXORA OS todavía no es una versión estable. Las compilaciones pueden contener errores, y los nombres o características pueden cambiar mientras el proyecto evoluciona.
