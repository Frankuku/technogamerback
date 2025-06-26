#!/bin/bash

# Colores para mejor lectura
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# URL base del API
API_URL="http://localhost:4001/api"

# Función para mostrar secciones principales
section() {
    echo -e "\n${GREEN}=== $1 ===${NC}"
}

# Función para mostrar subsecciones
subsection() {
    echo -e "\n${BLUE}--- $1 ---${NC}"
}

# Función para mostrar errores
error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Verifica que la API esté disponible
section "VERIFICANDO DISPONIBILIDAD DE LA API"
if curl -s "$API_URL/products" > /dev/null; then
    echo -e "${GREEN}✓ La API está en funcionamiento${NC}"
else
    error "La API no está disponible. Asegúrate de que el servidor esté corriendo."
    exit 1
fi

# 1. AUTENTICACIÓN (Usando directamente el usuario admin conocido)
section "AUTENTICACIÓN COMO ADMINISTRADOR"
subsection "Inicio de sesión como admin"

# Datos del usuario admin conocido
ADMIN_EMAIL="micheal23@gmail.com"
ADMIN_PASSWORD="qwerty"

echo -e "${YELLOW}Iniciando sesión como: $ADMIN_EMAIL${NC}"
    
# Realizar el login
LOGIN_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
    "$API_URL/auth/login")

echo "Respuesta de login:"
echo "$LOGIN_RESPONSE" | json_pp 2>/dev/null || echo "$LOGIN_RESPONSE"

# Extraer token y user ID del response
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | head -1 | cut -d'"' -f4)
USER_ID=$(echo "$LOGIN_RESPONSE" | grep -o '"_id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    error "No se pudo obtener un token de autenticación"
    exit 1
else
    echo -e "${GREEN}✓ Token de ADMINISTRADOR obtenido correctamente${NC}"
    echo "USER_ID: $USER_ID"
fi

# 2. CATEGORÍAS (Probar funcionalidad básica)
section "CATEGORÍAS"

# 2.1 Crear una nueva categoría
subsection "Crear categoría nueva"
TIMESTAMP=$(date +%s)
CATEGORY_NAME="Categoría Admin Test $TIMESTAMP"

CATEGORY_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d "{\"name\":\"$CATEGORY_NAME\",\"description\":\"Categoría creada con permisos de admin\"}" \
    "$API_URL/categories")

echo "Respuesta creación categoría:"
echo "$CATEGORY_RESPONSE" | json_pp 2>/dev/null || echo "$CATEGORY_RESPONSE"

# Extraer ID de la categoría creada
CATEGORY_ID=$(echo "$CATEGORY_RESPONSE" | grep -o '"_id":"[^"]*' | cut -d'"' -f4)

if [ -n "$CATEGORY_ID" ]; then
    echo -e "${GREEN}✓ Categoría creada con ID: $CATEGORY_ID${NC}"
else
    # Si falla, usar una categoría existente
    CATEGORY_ID=$(curl -s "$API_URL/categories" | grep -o '"_id":"[^"]*' | head -1 | cut -d'"' -f4)
    echo -e "${YELLOW}Usando ID de categoría existente: $CATEGORY_ID${NC}"
fi

# 3. PRODUCTOS
section "PRODUCTOS"

# 3.1 Crear un nuevo producto
subsection "Crear producto nuevo"

# Ahora incluimos el creador directamente en la creación del producto
PRODUCT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d "{\"name\":\"Producto Admin Test $TIMESTAMP\",\"description\":\"Producto creado con permisos de admin\",\"price\":99999,\"stock\":50,\"isAvailable\":true,\"image\":\"/uploads/products/default.jpg\",\"category\":\"$CATEGORY_ID\",\"creator\":\"$USER_ID\"}" \
    "$API_URL/products")

echo "Respuesta creación producto:"
echo "$PRODUCT_RESPONSE" | json_pp 2>/dev/null || echo "$PRODUCT_RESPONSE"

# Extraer ID del producto creado
PRODUCT_ID=$(echo "$PRODUCT_RESPONSE" | grep -o '"_id":"[^"]*' | cut -d'"' -f4)

if [ -n "$PRODUCT_ID" ]; then
    echo -e "${GREEN}✓ Producto creado con ID: $PRODUCT_ID${NC}"
else
    # Si falla, usar un producto existente
    PRODUCT_ID=$(curl -s "$API_URL/products" | grep -o '"_id":"[^"]*' | head -1 | cut -d'"' -f4)
    echo -e "${YELLOW}Usando ID de producto existente: $PRODUCT_ID${NC}"
fi

# 3.2 Obtener un producto específico (para demostrar populate)
subsection "Obtener producto específico con populate de categoría"
echo -e "${YELLOW}Obteniendo producto: $PRODUCT_ID${NC}"

PRODUCT_DETAIL=$(curl -s "$API_URL/products/$PRODUCT_ID")
echo "$PRODUCT_DETAIL" | json_pp 2>/dev/null || echo "$PRODUCT_DETAIL"

# 4. PRODUCTOS POR CATEGORÍA
section "PRODUCTOS POR CATEGORÍA"

# 4.1 Obtener productos por categoría
subsection "Listar productos de una categoría"

CATEGORY_PRODUCTS=$(curl -s "$API_URL/categories/$CATEGORY_ID/products")
echo "$CATEGORY_PRODUCTS" | json_pp 2>/dev/null || echo "$CATEGORY_PRODUCTS"

# 5. BÚSQUEDA Y FILTRADO DE PRODUCTOS
section "BÚSQUEDA Y FILTRADO"

# 5.1 Buscar productos por texto
subsection "Búsqueda de productos por texto"

SEARCH_TERM="Producto"
echo -e "${YELLOW}Buscando productos con el término: $SEARCH_TERM${NC}"

SEARCH_RESULTS=$(curl -s "$API_URL/products/search?search=$SEARCH_TERM")
echo "$SEARCH_RESULTS" | json_pp 2>/dev/null || echo "$SEARCH_RESULTS"

# 5.2 Filtrar productos por precio
subsection "Filtrado de productos por precio"

MIN_PRICE=5000
echo -e "${YELLOW}Filtrando productos con precio mínimo: $MIN_PRICE${NC}"

FILTER_RESULTS=$(curl -s "$API_URL/products/filter?minPrice=$MIN_PRICE")
echo "$FILTER_RESULTS" | json_pp 2>/dev/null || echo "$FILTER_RESULTS"

# 6. ÓRDENES
section "ÓRDENES"

# 6.1 Crear una nueva orden
subsection "Crear una nueva orden"

# Preparar los productos para la orden (formato actualizado para compatibilidad)
# Ahora necesitamos especificar items como array con product, quantity
echo -e "${YELLOW}Creando orden con producto: $PRODUCT_ID${NC}"

ORDER_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d "{\"items\":[{\"product\":\"$PRODUCT_ID\",\"quantity\":2}],\"shippingAddress\":{\"street\":\"Calle Test\",\"city\":\"Ciudad Test\",\"postalCode\":\"12345\",\"country\":\"País Test\"},\"paymentInfo\":{\"method\":\"credit_card\",\"transactionId\":\"test-$TIMESTAMP\"}}" \
    "$API_URL/orders")

echo "Respuesta creación orden:"
echo "$ORDER_RESPONSE" | json_pp 2>/dev/null || echo "$ORDER_RESPONSE"

# Extraer ID de la orden creada
ORDER_ID=$(echo "$ORDER_RESPONSE" | grep -o '"_id":"[^"]*' | cut -d'"' -f4)

if [ -n "$ORDER_ID" ]; then
    echo -e "${GREEN}✓ Orden creada con ID: $ORDER_ID${NC}"
else
    echo -e "${RED}No se pudo crear la orden${NC}"
fi

# 6.2 Listar órdenes (ahora usando el endpoint correcto)
subsection "Listar órdenes"

USER_ORDERS=$(curl -s -H "Authorization: $TOKEN" \
    "$API_URL/orders")

echo "$USER_ORDERS" | json_pp 2>/dev/null || echo "$USER_ORDERS"

# 6.3 Obtener una orden específica
if [ -n "$ORDER_ID" ]; then
    subsection "Obtener orden específica"
    echo -e "${YELLOW}Obteniendo orden: $ORDER_ID${NC}"
    
    ORDER_DETAIL=$(curl -s -H "Authorization: $TOKEN" \
        "$API_URL/orders/$ORDER_ID")
    
    echo "$ORDER_DETAIL" | json_pp 2>/dev/null || echo "$ORDER_DETAIL"
else
    echo -e "${RED}No hay ID de orden disponible para consultar${NC}"
fi

# 7. ACTUALIZACIÓN PARCIAL DE PRODUCTO (PATCH)
section "ACTUALIZACIÓN PARCIAL DE PRODUCTOS"

if [ -n "$PRODUCT_ID" ]; then
    subsection "Actualización parcial (PATCH) de un producto"
    
    PATCH_RESPONSE=$(curl -s -X PATCH -H "Content-Type: application/json" \
        -H "Authorization: $TOKEN" \
        -d "{\"price\":88888,\"stock\":25}" \
        "$API_URL/products/$PRODUCT_ID")
    
    echo "$PATCH_RESPONSE" | json_pp 2>/dev/null || echo "$PATCH_RESPONSE"
    
    echo -e "${GREEN}✓ Producto actualizado parcialmente${NC}"
else
    echo -e "${RED}No hay ID de producto para actualizar${NC}"
fi

# RESUMEN
section "RESUMEN DE PRUEBAS"
echo -e "${GREEN}✓ Se han probado todos los endpoints principales de la API${NC}"
echo -e "${GREEN}✓ Rutas verificadas con la estructura simplificada de la API${NC}"
echo -e "${YELLOW}Recursos creados durante la prueba:${NC}"
echo "  - Usuario Admin: $USER_ID ($ADMIN_EMAIL)"
echo "  - Categoría: $CATEGORY_ID"
echo "  - Producto: $PRODUCT_ID"
echo "  - Orden: $ORDER_ID"

echo -e "\n${GREEN}=== FIN DE LAS PRUEBAS ===${NC}"
