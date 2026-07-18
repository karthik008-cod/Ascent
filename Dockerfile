# Stage 1: Build the Flutter Web application
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy dependency files first to cache layer
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy full source code and build for web
COPY . .
ARG BREVO_API_KEY
RUN flutter build web --release --dart-define=BREVO_API_KEY=${BREVO_API_KEY}

# Stage 2: Serve with Nginx Alpine
FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built web artifacts from Stage 1
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom Nginx SPA config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 8080 (Render detects EXPOSE to bind traffic)
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
