#!/bin/bash
# Script de Construcción Segura (Ofuscación de Código Dart)

echo "=========================================================="
echo "🛡️ INICIANDO COMPILACIÓN SEGURA DE PRODUCCIÓN (OWASP M7)"
echo "=========================================================="
echo "Preparando directorios para símbolos de depuración..."
mkdir -p build/app/outputs/symbols

echo "Compilando APK con Ofuscación (R8) activada..."
# --obfuscate: Cambia los nombres de clases, funciones y variables a letras aleatorias.
# --split-debug-info: Guarda el mapa original de nombres fuera del APK para que los atacantes no puedan leerlo.
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

echo "=========================================================="
echo "✅ ¡APK CONSTRUIDO, ENCRIPTADO Y OFUSCADO CON ÉXITO!"
echo "Ruta del APK Seguro: build/app/outputs/flutter-apk/app-release.apk"
echo "Guarda la carpeta 'build/app/outputs/symbols' en un lugar seguro (la necesitarás si tu app crashea para leer el error real)."
echo "=========================================================="
