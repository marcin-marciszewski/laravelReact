#! /bin/bash
rm ./project.tar
git archive --format tar --output ./project.tar main

echo 'Uploading project...'
ssh -o StrictHostKeyChecking=no root@srv12.mikr.us -p 10319 'rm -f /tmp/project.tar'
if ! rsync -e "ssh -p 10319" --progress ./project.tar root@srv12.mikr.us:/tmp/project.tar; then
    echo "Failed to upload project.tar"
    exit 1
fi
echo 'Upload complete.'

echo 'Building image...'
ssh -o StrictHostKeyChecking=no root@srv12.mikr.us -p 10319 <<'ENDSSH'
    # Create app directory and ensure proper permissions
    mkdir -p /app && chmod 755 /app

    # Check if tar file exists
    if [ ! -f /tmp/project.tar ]; then
        echo "Error: /tmp/project.tar not found"
        exit 1
    fi

    # Clear directory and extract with error checking
    rm -rf /app/*
    tar -xf /tmp/project.tar -C /app || { echo "Failed to extract tar file"; exit 1; }

    # Ensure we stop and remove all existing containers to clear any volumes
    docker compose -f /app/compose.prod.yaml down -v

    # Build and start the containers
    docker compose -f /app/compose.prod.yaml up --build -d --remove-orphans

    # Clear view cache in the PHP container
    docker compose -f /app/compose.prod.yaml exec -T php-fpm php artisan view:clear
ENDSSH
echo 'Build complete.'
