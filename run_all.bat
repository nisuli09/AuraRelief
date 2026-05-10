@echo off

cd /d C:\Users\hp\AndroidStudioProjects\Migraine_App

start cmd /k "python app.py"
start cmd /k "python api.py"

timeout /t 3

flutter run -d edge
