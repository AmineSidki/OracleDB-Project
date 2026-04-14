#!/bin/bash
# ================================================================
# Global DB — Load original E_Shop data
# Runs as: oracle OS user inside the container
# Files are mounted at /e-shop-data/ from the host's ./eshop-data/
#
# Load order respects FK dependencies:
#   Categories → Employes → Fournisseurs → Clients
#     → Commandes → Produits → LigneCommandes
# ================================================================

set -e

CONN="$APP_USER/$APP_USER_PASSWORD@//localhost/XEPDB1"

run_sql_file() {
    local file="$1"
    echo ">>> Loading: $(basename "$file")"
    # Strip Windows carriage returns, append EXIT so sqlplus doesn't hang
    { sed 's/\r//g' "$file"; echo -e "\nEXIT;"; } | sqlplus -S "$CONN"
    echo "    Done."
}

echo "=============================="
echo " EShop Global DB — Data Load"
echo "=============================="

# NLS session fix: French data uses comma as decimal separator in produits.sql
# We set it globally before each run via a wrapper
run_sql_file_with_nls() {
    local file="$1"
    echo ">>> Loading: $(basename "$file") [NLS comma-decimal]"
    {
        echo "ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ', .';"
        sed 's/\r//g' "$file"
        echo -e "\nCOMMIT;\nEXIT;"
    } | sqlplus -S "$CONN"
    echo "    Done."
}

# 1 — Categories + compteur sequence
run_sql_file "/e-shop-data/cat#U00e9gorie.sql"

# 2 — Employes
run_sql_file "/e-shop-data/Employe.sql"

# 3 — Fournisseurs
run_sql_file "/e-shop-data/Fournisseur.sql"

# 4 — Clients
run_sql_file "/e-shop-data/Clients.sql"

# 5 — Commandes
run_sql_file "/e-shop-data/commandes.sql"

# 6 — Produits (comma-decimal issue)
run_sql_file_with_nls "/e-shop-data/produits.sql"

# 7 — LigneCommandes
run_sql_file "/e-shop-data/lignecommandes.sql"

echo ""
echo "=============================="
echo " Data load complete."
echo " DB links and triggers must"
echo " be set up via scripts/ after"
echo " all three containers are up."
echo "=============================="
