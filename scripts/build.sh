#!/bin/bash
set -e
echo "--- Environment Check ---"
pwd
ls -la
echo "PATH: $PATH"
echo "--- Starting Flutter Web build process ---"

# 1. Create .env file from environment variables (for Vercel)
echo "Creating .env file..."
echo "SUPABASE_URL=${SUPABASE_URL}" > .env
echo "SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" >> .env

# 2. Install Flutter SDK
if [ ! -d "flutter" ]; then
    echo "Downloading Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Verify Flutter installation
flutter doctor -v

# 4. Enable Web support
flutter config --enable-web

# 5. Get dependencies
flutter pub get

# 6. Build Web Release
echo "Building Flutter Web..."
flutter build web --release --base-href / --pwa-strategy=offline-first

echo "Build completed successfully!"
