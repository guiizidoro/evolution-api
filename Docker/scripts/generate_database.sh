#!/bin/bash

# Source environment variables unconditionally.
source ./.env

source ./Docker/scripts/env_functions.sh

if [ "$DOCKER_ENV" != "true" ]; then
    export_env_vars
fi

if [[ "$DATABASE_PROVIDER" == "postgresql" || "$DATABASE_PROVIDER" == "mysql" || "$DATABASE_PROVIDER" == "psql_bouncer" ]]; then
    export DATABASE_URL
    echo "Generating database for $DATABASE_PROVIDER"
    echo "Database URL: $DATABASE_URL"

    # We add a retry loop to give the database time to start.
    RETRY_COUNT=0
    MAX_RETRIES=10
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        npm run db:generate
        if [ $? -eq 0 ]; then
            echo "Prisma generate succeeded"
            exit 0 # Success, exit the script.
        else
            RETRY_COUNT=$((RETRY_COUNT+1))
            echo "Prisma generate failed, retrying in 5 seconds... ($RETRY_COUNT/$MAX_RETRIES)"
            sleep 30 # Wait for 5 seconds before retrying.
        fi
    done

    echo "Error: Prisma generate failed after $MAX_RETRIES retries."
    exit 1 # Failure, exit the script with an error.

else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi
