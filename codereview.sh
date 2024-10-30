#!/bin/bash

# Configuración: obtener el token y el usuario de las variables de entorno
GITHUB_CODEREVIEW_TOKEN=${GITHUB_CODEREVIEW_TOKEN}  # Variable de entorno para el token
GITHUB_CODEREVIEW_USER=${GITHUB_CODEREVIEW_USER}    # Variable de entorno para el nombre de usuario

# Verificar si las variables de entorno están configuradas
if [[ -z "$GITHUB_CODEREVIEW_TOKEN" ]] || [[ -z "$GITHUB_CODEREVIEW_USER" ]]; then
  echo "Error: GITHUB_CODEREVIEW_TOKEN y GITHUB_CODEREVIEW_USER deben estar configuradas."
  exit 1
fi

# Define la consulta GraphQL usando printf para evitar problemas de comillas
query=$(printf '{
  "query": "query { search(query: \\"type:pr review-requested:%s state:open\\", type: ISSUE, first: 10) { edges { node { ... on PullRequest { title url repository { nameWithOwner } } } } } }"
}' "$GITHUB_CODEREVIEW_USER")

# Realiza la solicitud a la API de GitHub GraphQL
response=$(curl -s -X POST -H "Authorization: bearer $GITHUB_CODEREVIEW_TOKEN" -H "Content-Type: application/json" \
  -d "$query" https://api.github.com/graphql)

# Verifica si hubo errores en la respuesta de la API
if echo "$response" | jq -e '.errors' > /dev/null; then
  echo "Error en la solicitud: $(echo "$response" | jq '.errors')"
  exit 1
fi

# Procesa y muestra los resultados, enviando notificaciones en macOS
echo "Repositorios que requieren tu revisión de código:"
echo "$response" | jq -c '.data.search.edges[] | {repo: .node.repository.nameWithOwner, title: .node.title, url: .node.url}' |
while IFS= read -r pr_info; do
    # Extrae los valores directamente desde jq
    repo_name=$(echo "$pr_info" | jq -r '.repo')
    pr_title=$(echo "$pr_info" | jq -r '.title')
    pr_url=$(echo "$pr_info" | jq -r '.url')

    # Muestra una notificación en macOS con el título del PR y un botón que abre el enlace
    osascript -e "display notification \"$pr_title\" with title \"Revisión requerida en $repo_name\" subtitle \"Pull Request\" sound name \"Ping\""
    osascript -e "display dialog \"$pr_title\" buttons {\"Abrir PR\", \"Cerrar Notificación\"} default button \"Cerrar Notificación\" with title \"Revisión de código\" with icon note" \
              -e "if button returned of result is \"Abrir PR\" then open location \"$pr_url\""
done
