# Phoenix + Symfony Users Demo

This project is a demo application composed of **two cooperating systems**:

- **Backend API**: Elixir + Phoenix  
- **Frontend / Admin Panel**: PHP + Symfony  

The systems communicate exclusively via a **REST JSON API**.  
The backend is responsible for data storage and business logic, while Symfony provides a web-based CRUD interface.

---

## Architecture Overview

```text
project-root/
│
├── phoenix-api/        # Elixir + Phoenix REST API
│   ├── lib/
│   ├── priv/
│   └── Dockerfile
│
├── symfony-app/        # Symfony frontend (Twig-based admin panel)
│   ├── src/
│   ├── templates/
│   └── Dockerfile
│
├── docker-compose.yml  # Shared Docker Compose setup
└── README.md
```


---

## Technology Stack

### Backend (API)
- Elixir
- Phoenix Framework
- Ecto + PostgreSQL
- Bandit HTTP server
- Req (HTTP client)

### Frontend (Admin Panel)
- PHP 8+
- Symfony 6+
- Twig
- Symfony Forms
- Symfony HttpClient

### Infrastructure
- Docker
- Docker Compose
- PostgreSQL 15

---

## Domain Model

### User
| Field        | Type   | Notes                         |
|-------------|--------|-------------------------------|
| first_name  | string | Required                      |
| last_name   | string | Required                      |
| birthdate   | date   | 1970-01-01 → 2024-12-31        |
| gender      | string | `male` / `female`             |

---

## Data Sources

User data is **generated automatically** using public Polish PESEL registry datasets published on dane.gov.pl.

### Official sources:

- **First names (PESEL registry)**  
  https://dane.gov.pl/pl/dataset/1667,lista-imion-wystepujacych-w-rejestrze-pesel-osoby-zyjace

- **Last names (PESEL registry)**  
  https://dane.gov.pl/pl/dataset/1681,nazwiska-osob-zyjacych-wystepujace-w-rejestrze-pesel

### The importer:
- selects the most recent datasets,
- extracts the **top 100 names** per gender,
- generates **100 random users**,
- ensures gender consistency between name and gender,
- stores them in PostgreSQL.

---

## REST API (Phoenix)

Base URL (inside Docker):
http://phoenix:4000/api


Base URL (from host):
http://localhost:4000/api


### Endpoints

| Method | Endpoint           | Description |
|------|--------------------|-------------|
| GET  | `/users`           | List users (filtering & sorting supported) |
| GET  | `/users/:id`       | User details |
| POST | `/users`           | Create user |
| PUT  | `/users/:id`       | Update user |
| DELETE | `/users/:id`     | Delete user |
| POST | `/import`          | Run PESEL-based import |

### Filtering & Sorting (`GET /users`)
Query parameters:
- `first_name`
- `last_name`
- `gender`
- `birthdate_from`
- `birthdate_to`
- `sort` (column name)
- `dir` (`asc` / `desc`)

---

## Import Endpoint

The import endpoint is protected by a simple header token.

```http
POST /api/import
x-import-token: dev-import-token
```

Example:
```bash
curl -X POST http://localhost:4000/api/import \
  -H "x-import-token: dev-import-token"
```

## Symfony Admin Panel

### The Symfony application provides:
- User list with filtering and sorting
- Create / Edit / Delete users
- Server-side communication with the Phoenix API
- No local database — all data is fetched via REST

### Access in browser:
http://localhost:8000/users


---

## Running the Project

### Requirements
- Docker
- Docker Compose

### Start the stack

```bash
docker compose up -d --build
```

### Import sample data
```bash
curl -X POST http://localhost:4000/api/import \
  -H "x-import-token: dev-import-token"
```

### Open applications

- **Phoenix API**  
  http://localhost:4000/api/users

- **Symfony Admin Panel**  
  http://localhost:8000/users

---

## Development Notes

- The project intentionally uses **two separate frameworks** to demonstrate:
  - API-driven architecture
  - Clear separation of responsibilities
  - Cross-language integration (Elixir ↔ PHP)
- Symfony does **not** use Doctrine entities — it acts as a pure API client.
- Phoenix handles filtering and sorting at the database level (Ecto).

---

## Possible Extensions

- Pagination (`limit` / `offset`)
- API authentication (JWT / OAuth)
- OpenAPI / Swagger documentation
- Frontend UX with Symfony UX / Turbo / Vue
- Background import jobs (Oban)

---

## License

This project is provided for educational and demonstration purposes.  
Public data sources are used in accordance with dane.gov.pl open data policies.