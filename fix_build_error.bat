@echo off
echo ========================================
echo Flutter Build Error Fix Script
echo ========================================
echo.

echo Step 1: Stopping Gradle daemon...
cd android
call gradlew --stop
cd ..

echo Step 2: Cleaning Flutter project...
call flutter clean

echo Step 3: Removing build directories...
if exist "build" rmdir /s /q "build"
if exist "android\build" rmdir /s /q "android\build"
if exist "android\app\build" rmdir /s /q "android\app\build"

echo Step 4: Clearing Gradle cache...
cd android
call gradlew clean
cd ..

echo Step 5: Getting Flutter dependencies...
call flutter pub get

echo Step 6: Building APK...
call flutter build apk --release

echo.
echo ========================================
echo Build process completed!
echo ========================================
pause
