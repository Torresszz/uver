#!/bin/bash
# Descargar Flutter
git clone https://github.com/flutter/flutter.git -b stable
# Agregar al PATH
export PATH="$PATH:`pwd`/flutter/bin"
# Configurar y descargar dependencias
flutter config --enable-web
flutter pub get