@echo off
setlocal

set "FLUTTER=C:\Users\Tom\flutter\bin"
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
set "PATH=%FLUTTER%;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

cd /d "C:\Users\Tom\AndroidStudioProjects\cardflip"

echo.
echo  CardFlip launcher
echo  -----------------
echo  [1] Run in Chrome
echo  [2] Run on connected Android device / emulator
echo  [3] Build debug APK
echo.
set /p choice=Pick 1, 2, or 3: 

if "%choice%"=="2" goto android
if "%choice%"=="3" goto apk

echo.
echo Starting Chrome...
flutter run -d chrome
goto end

:android
echo.
echo Starting Android...
flutter run
goto end

:apk
echo.
echo Building debug APK...
flutter build apk --debug
echo.
echo APK: build\app\outputs\flutter-apk\app-debug.apk
explorer "build\app\outputs\flutter-apk"
goto end

:end
echo.
pause
