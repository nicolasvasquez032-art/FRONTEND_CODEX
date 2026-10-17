# ==============================================================================
# Dockerfile - Frontend Web (TalentMatch)
# Arquitectura: Multi-stage Build (Compilación con Flutter SDK + Servidor Nginx)
# ==============================================================================

# ------------------------------------------------------------------------------
# Etapa 1: Build de la aplicación Flutter Web
# ------------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS build-stage

WORKDIR /app

# Descargar paquetes primero para aprovechar caché
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar el código fuente y compilar a web release
COPY . .
RUN flutter build web --release

# ------------------------------------------------------------------------------
# Etapa 2: Servidor Web Nginx ligero para producción
# ------------------------------------------------------------------------------
FROM nginx:alpine AS production-stage

LABEL maintainer="Equipo TalentMatch"
LABEL description="Frontend Web Nginx - TalentMatch"

# Copiar los artefactos generados en la etapa de compilación
COPY --from=build-stage /app/build/web /usr/share/nginx/html

# Exponer el puerto estándar HTTP
EXPOSE 80

# Iniciar Nginx en primer plano
CMD ["nginx", "-g", "daemon off;"]
