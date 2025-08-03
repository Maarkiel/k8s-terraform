#!/bin/bash

# Quick Diagnosis Script for Gunicorn PATH Issue
# Run this to identify the exact problem

echo "🔍 QUICK GUNICORN DIAGNOSIS"
echo "=========================="
echo ""

# Check if we're using minikube docker
eval $(minikube docker-env)

echo "1. Checking Docker images in minikube:"
docker images | grep portfolio-demo
echo ""

echo "2. Checking PATH in container:"
docker run --rm portfolio-demo:latest echo '$PATH'
echo ""

echo "3. Checking where gunicorn is located:"
docker run --rm portfolio-demo:latest which gunicorn || echo "❌ gunicorn not found in PATH"
echo ""

echo "4. Checking if gunicorn exists in expected location:"
docker run --rm portfolio-demo:latest ls -la /home/appuser/.local/bin/gunicorn || echo "❌ gunicorn not found in /home/appuser/.local/bin/"
echo ""

echo "5. Checking current user in container:"
docker run --rm portfolio-demo:latest whoami
echo ""

echo "6. Checking user ID:"
docker run --rm portfolio-demo:latest id
echo ""

echo "7. Testing gunicorn with full path:"
docker run --rm portfolio-demo:latest /home/appuser/.local/bin/gunicorn --version || echo "❌ Full path doesn't work"
echo ""

echo "8. Testing python -m gunicorn:"
docker run --rm portfolio-demo:latest python -m gunicorn --version || echo "❌ python -m gunicorn doesn't work"
echo ""

echo "9. Checking all files in .local/bin:"
docker run --rm portfolio-demo:latest ls -la /home/appuser/.local/bin/
echo ""

echo "10. Checking if PATH includes .local/bin:"
docker run --rm portfolio-demo:latest bash -c 'echo $PATH | grep -o "/home/appuser/.local/bin"' || echo "❌ PATH doesn't include /home/appuser/.local/bin"
echo ""

# Reset docker env
eval $(minikube docker-env -u)

echo "🎯 DIAGNOSIS COMPLETE!"
echo ""
echo "Based on the results above, the issue is likely:"
echo "- If gunicorn not found in PATH: PATH issue"
echo "- If gunicorn exists but can't execute: Permission issue"
echo "- If user is not 'appuser': User context issue"
echo "- If PATH doesn't include .local/bin: Environment variable issue"

