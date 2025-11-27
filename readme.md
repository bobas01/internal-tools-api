# Internal Tools API

## Technologies

- Langage : PHP 8.2
- Framework : Symfony 7.1 + API Platform 4
- Base de données : MySQL 8 (Docker, base `internal_tools`)
- Port API : 8000 (configurable)

## Quick Start

1. Démarrer la base de données (à la racine du projet) :

   ```bash
   docker compose --profile mysql up -d
   ```

2. Installer les dépendances backend (dans `internal-tools-api`) :

   ```bash
   cd internal-tools-api
   composer install
   ```

3. Démarrer le serveur Symfony :

   ```bash
   symfony serve
   # ou
   php -S 127.0.0.1:8000 -t public
   ```

4. API disponible sur :  
   `http://127.0.0.1:8000`

5. Documentation Swagger / OpenAPI :  
   `http://127.0.0.1:8000/api`

## Configuration

- Variables d'environnement : à définir dans `internal-tools-api/.env.local` (non versionné) :

  ```env
  APP_ENV=dev
  APP_DEBUG=1
  DATABASE_URL="mysql://dev:dev123@127.0.0.1:3306/internal_tools?serverVersion=8.0"
  ```

- Configuration DB (Docker) :
  - Host : `127.0.0.1`
  - Port : `3306`
  - Base : `internal_tools`
  - User / Password : `dev` / `dev123`

## Tests

Pas de suite de tests spécifique ajoutée pour ce test, mais PHPUnit est prêt à l’emploi :

```bash
cd internal-tools-api
php bin/phpunit
```

## Architecture

- **Choix techniques**

  - Symfony + API Platform pour bénéficier d’un socle REST robuste, de la validation et de la génération automatique d’OpenAPI/Swagger.
  - MySQL Dockerisé fourni (scripts `mysql/init.sql`) pour repartir d’un jeu de données réaliste (20 outils, 25 employés, métriques).
  - Doctrine ORM pour le mapping et les jointures vers les tables d’analytics (`usage_logs`, `cost_tracking`).

- **Structure du projet**
  - `docker-compose.yml` + `mysql/` : stack base de données + seed.
  - `internal-tools-api/` : application Symfony / API Platform.
    - `src/Entity/Tool.php` : entité principale exposée en API (`/api/tools`), filtres (département, statut, coût, catégorie), validation.
    - `src/Entity/Category.php` : entité `categories`, exposée pour référencer les catégories via `/api/categories`.
    - `src/State/ToolDetailStateProvider.php` : provider custom pour le `GET /api/tools/{id}` détaillé, qui enrichit la réponse avec :
      - `totalMonthlyCost` (depuis la table `cost_tracking`)
      - `usageMetrics.last_30_days` (agrégats issus de `usage_logs`).
    - `config/packages/api_platform.yaml` : configuration API Platform (doc, formats, désactivation GraphQL).
