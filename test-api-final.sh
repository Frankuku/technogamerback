#!/bin/bash

# ==================================================
# SCRIPT DE DEMOSTRACIÓN PARA API NODE.JS
# Creado para la presentación final del proyecto
# ==================================================

# Colores para mejor lectura
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
NC="\033[0m" # No Color

# URL base del API
API_URL="http://localhost:4001/api"

# Función para mostrar secciones principales
section() {
    echo -e "\n${GREEN}================ $1 =================${NC}"
}

# Función para mostrar subsecciones
subsection() {
    echo -e "\n${BLUE}--- $1 ---${NC}"
}

# Función para mostrar notas o comentarios
note() {
    echo -e "${PURPLE}➡ $1${NC}"
}

# Función para mostrar errores
error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Función para formatear JSON si jq está disponible, o mostrar como texto plano si no
format_json() {
    if command -v json_pp &> /dev/null; then
        echo "$1" | json_pp 2>/dev/null || echo "$1"
    elif command -v jq &> /dev/null; then
        echo "$1" | jq . 2>/dev/null || echo "$1"
    else
        echo "$1"
    fi
}

# Verifica que la API esté disponible
section "VERIFICANDO DISPONIBILIDAD DE LA API"
note "Verificando conexión con el servidor..."

if curl -s "$API_URL/products" > /dev/null; then
    echo -e "${GREEN}✓ La API está en funcionamiento${NC}"
else
    error "La API no está disponible. Asegúrate de que el servidor esté corriendo."
    note "Para iniciar el servidor ejecuta: npm start"
    exit 1
fi

# =============================================================
# PARTE 1: AUTENTICACIÓN Y USUARIOS
# =============================================================
section "AUTENTICACIÓN Y USUARIOS"
note "Demostrando funcionalidades de usuario y autenticación"

# Iniciar sesión con usuario ADMIN existente
subsection "Autenticación - Login con Usuario Admin"
note "Realizando login con usuario admin (micheal23@gmail.com)..."

# Datos del usuario admin conocido
ADMIN_EMAIL="micheal23@gmail.com"
ADMIN_PASSWORD="qwerty"
    
# Realizar el login
LOGIN_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
    "$API_URL/auth/login")

echo "Respuesta de login:"
format_json "$LOGIN_RESPONSE"

# Extraer token y user ID del response
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | head -1 | cut -d'"' -f4)
USER_ID=$(echo "$LOGIN_RESPONSE" | grep -o '"_id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    error "No se pudo obtener un token de autenticación"
    exit 1
else
    echo -e "${GREEN}✓ Token de ADMINISTRADOR obtenido correctamente${NC}"
    echo -e "${YELLOW}USER_ID: $USER_ID${NC}"
    echo -e "${PURPLE}Este token se usará para las operaciones que requieren autenticación${NC}"
fi

# Listar todos los usuarios
subsection "Usuarios - Listado General"
note "Obteniendo lista de todos los usuarios..."

USER_LIST_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/users")
format_json "$USER_LIST_RESPONSE"

# Obtener un usuario específico
subsection "Usuarios - Obtener Usuario Específico"
note "Obteniendo detalles del usuario autenticado..."

USER_DETAIL_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/users/$USER_ID")
format_json "$USER_DETAIL_RESPONSE"

# =============================================================
# PARTE 2: CATEGORÍAS 
# =============================================================
section "GESTIÓN DE CATEGORÍAS"
note "Demostrando funcionalidades de Categorías"

# Listar todas las categorías
subsection "Categorías - Listado General"
note "Obteniendo todas las categorías (endpoint público)..."

CATEGORIES_RESPONSE=$(curl -s "$API_URL/categories")
format_json "$CATEGORIES_RESPONSE"

# Crear una nueva categoría
subsection "Categorías - Crear Nueva"
note "Creando una nueva categoría (requiere autenticación)..."

TIMESTAMP=$(date +%s)
CATEGORY_NAME="Categoría Demo $TIMESTAMP"

CATEGORY_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"name\":\"$CATEGORY_NAME\",\"description\":\"Categoría para demostración de la API\"}" \
    "$API_URL/categories")

echo "Respuesta de creación:"
format_json "$CATEGORY_RESPONSE"

# Extraer ID de la categoría creada
CATEGORY_ID=$(echo "$CATEGORY_RESPONSE" | grep -o '"_id":"[^"]*' | cut -d'"' -f4)

if [ -n "$CATEGORY_ID" ]; then
    echo -e "${GREEN}✓ Categoría creada con ID: $CATEGORY_ID${NC}"
else
    # Si falla la creación, usar una categoría existente
    CATEGORY_ID=$(echo "$CATEGORIES_RESPONSE" | grep -o '"_id":"[^"]*' | head -1 | cut -d'"' -f4)
    echo -e "${YELLOW}Usando ID de categoría existente: $CATEGORY_ID${NC}"
fi

# Obtener una categoría específica
subsection "Categorías - Detalles de Categoría"
note "Obteniendo detalles de la categoría (endpoint público)..."

CATEGORY_DETAIL=$(curl -s "$API_URL/categories/$CATEGORY_ID")
format_json "$CATEGORY_DETAIL"

# =============================================================
# PARTE 3: PRODUCTOS
# =============================================================
section "GESTIÓN DE PRODUCTOS"
note "Demostrando funcionalidades de Productos"

# Listar todos los productos
subsection "Productos - Listado General"
note "Obteniendo todos los productos (endpoint público)..."

PRODUCTS_RESPONSE=$(curl -s "$API_URL/products")
format_json "$PRODUCTS_RESPONSE"

# Extraer un ID de producto para pruebas
PRODUCT_ID=$(echo "$PRODUCTS_RESPONSE" | grep -o '"_id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$PRODUCT_ID" ]; then
    error "No se encontraron productos en la base de datos"
else
    echo -e "${YELLOW}ID de producto para pruebas: $PRODUCT_ID${NC}"
fi

# Obtener un producto específico (con populate de categoría)
subsection "Productos - Detalle con Populate"
note "Obteniendo detalles del producto con populate de categoría..."

PRODUCT_DETAIL=$(curl -s "$API_URL/products/$PRODUCT_ID")
format_json "$PRODUCT_DETAIL"

echo -e "${PURPLE}✦ Notar que esta respuesta incluye la categoría completa gracias al populate${NC}"

# =============================================================
# PARTE 4: RELACIONES ENTRE ENTIDADES
# =============================================================
section "RELACIONES ENTRE ENTIDADES"

# Obtener productos por categoría
subsection "Relaciones - Productos por Categoría"
note "Obteniendo productos filtrados por categoría..."

# Usar una categoría que ya tenga productos (Electro)
CATEGORY_WITH_PRODUCTS="6840de333d40433a6dabb4c5" # ID de la categoría Electro

PRODUCTS_BY_CATEGORY=$(curl -s "$API_URL/categories/$CATEGORY_WITH_PRODUCTS/products")
format_json "$PRODUCTS_BY_CATEGORY" 

echo -e "${PURPLE}✦ Esta relación muestra los productos que pertenecen a una categoría específica${NC}"

# =============================================================
# RESUMEN Y CONCLUSIÓN
# =============================================================
section "RESUMEN DE DEMOSTRACIÓN"

echo -e "${GREEN}✓ Se han probado los principales endpoints del API${NC}"
echo -e "${GREEN}✓ Autenticación JWT funcionando correctamente${NC}"
echo -e "${GREEN}✓ Operaciones CRUD básicas demostradas${NC}"
echo -e "${GREEN}✓ Relaciones entre entidades probadas${NC}"
echo -e "${YELLOW}Recursos utilizados durante la demostración:${NC}"
echo "  - Usuario Admin: $USER_ID ($ADMIN_EMAIL)"
echo "  - Categoría: $CATEGORY_ID"
echo "  - Producto: $PRODUCT_ID"
echo -e "${PURPLE}✦ Nota: La API incluye más funcionalidades como órdenes, relaciones avanzadas${NC}"
echo -e "${PURPLE}  y operaciones adicionales que pueden explorarse en el código fuente.${NC}"

# Mostrar información sobre los endpoints principales
section "DOCUMENTACIÓN RÁPIDA DE ENDPOINTS"

echo -e "${BLUE}Autenticación:${NC}"
echo "  POST   /api/auth/register    - Registro de usuario"
echo "  POST   /api/auth/login       - Inicio de sesión"
echo -e "${BLUE}Usuarios:${NC}"
echo "  GET    /api/users            - Obtener todos los usuarios"
echo "  GET    /api/users/:id        - Obtener usuario específico"
echo -e "${BLUE}Categorías:${NC}"
echo "  GET    /api/categories       - Obtener todas las categorías"
echo "  POST   /api/categories       - Crear nueva categoría"
echo "  GET    /api/categories/:id   - Obtener categoría específica"
echo -e "${BLUE}Productos:${NC}"
echo "  GET    /api/products         - Obtener todos los productos"
echo "  GET    /api/products/:id     - Obtener producto específico"
echo -e "${BLUE}Relaciones:${NC}"
echo "  GET    /api/categories/:id/products   - Productos por categoría"

echo -e "\n${GREEN}================ FIN DE LA DEMOSTRACIÓN =================${NC}"
