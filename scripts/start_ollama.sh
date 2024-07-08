#!/bin/sh
# cd /games/dify/docker/ && docker compose up -d && docker stop docker_web_1 docker_db_1 docker_redis_1 docker_weaviate_1 docker_sandbox_1 docker_api_1 docker_worker_1 docker_nginx_1
# cd /games/LibreChat && docker compose up -d && docker stop chat-mongodb chat-meilisearch vectordb rag_api LibreChat
cd /games/open-webui && docker compose -f docker-compose.yaml -f docker-compose.api.yaml -f docker-compose.gpu.yaml up -d && docker stop open-webui
