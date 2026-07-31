# Phase 2: scanner-agent — Deepen Detection + Switch to Shared Doc

**Repo:** fullstack-dev
**Depends on:** Phase 1 (`skills/project/reference/context7-usage.md` must exist before Task 2 points to it)
**Delivers:** `scanner-agent` detects Django, Flask, Rails, Spring/Spring Boot, Laravel, and ASP.NET/.NET at the same depth already given to Next.js/Nuxt/Prisma, and its own Context7 MCP Usage section is replaced with a pointer to the shared doc.

## File Structure

```
agents/
└── scanner-agent.md   [MODIFY]  (both tasks touch this one file, as two separate commits)
```

### Task 1: Extend the four detection tables with six new ecosystems

**Files:**
- Modify: `agents/scanner-agent.md`

**Interfaces:**
- Consumes: none (table content is self-contained; no dependency on context7-usage.md).
- Produces: new rows in `agents/scanner-agent.md`'s `### Package & Dependency Files`, `### Configuration Files`, `### Entry Points`, and `### Models & Schemas` tables for Django, Flask, Rails, Spring/Spring Boot, Laravel, ASP.NET/.NET.

**Acceptance Criteria:** AC6, AC7, AC12

**Steps:**

1. **Write content.** In `agents/scanner-agent.md`, append these 6 rows to the end of the `### Package & Dependency Files` table (currently ending with the `composer.json` row at line 45), immediately before the blank line that precedes "Extract: language, framework, runtime...":

   ```markdown
   | `manage.py` present, and `requirements.txt`/`pyproject.toml` contains `django` or `settings.py` contains `INSTALLED_APPS` | Django project confirmed (Python web framework) |
   | `requirements.txt`/`pyproject.toml` contains `flask`, and a Python file greps for `from flask import Flask` | Flask project confirmed (never inferred from `app.py` alone -- that filename is shared with FastAPI, Streamlit, and plain scripts) |
   | `Gemfile` present and `config/routes.rb` present | Rails project confirmed |
   | `pom.xml` contains `spring-boot-starter` or `org.springframework.boot`, or `build.gradle*` contains `org.springframework.boot` | Spring / Spring Boot project confirmed |
   | `composer.json` contains `"laravel/framework"` | Laravel project confirmed |
   | `*.csproj` contains `Microsoft.AspNetCore` | ASP.NET / .NET project confirmed |
   ```

   Append these 6 rows to the end of the `### Configuration Files` table (currently ending with the `.env.example`/`.env.local.example` row at line 66):

   ```markdown
   | `settings.py`, `<project>/settings/*.py` | Django settings module, installed apps, database config, middleware stack |
   | `config.py`, `.flaskenv`, `instance/config.py` | Flask app config, environment-specific settings |
   | `config/application.rb`, `config/environments/*.rb`, `config/database.yml` | Rails app config, environment profiles, DB connection |
   | `application.properties`, `application.yml` | Spring Boot config, active profiles, datasource settings |
   | `config/*.php`, `.env` (Laravel) | Laravel config files, environment variables |
   | `appsettings.json`, `appsettings.*.json` | ASP.NET config, environment-specific settings |
   ```

   Append these 6 rows to the end of the `### Entry Points` table (currently ending with the `steps/`, `src/steps/` row at line 80):

   ```markdown
   | `manage.py`, `wsgi.py`, `asgi.py`, `urls.py` | Django CLI/management entry, WSGI/ASGI entry, root URLconf routing |
   | `app.py`/`wsgi.py` (only after Flask confirmed via the signal above), `__init__.py` Blueprint registrations | Flask app factory and blueprint-based routing |
   | `config/routes.rb`, `app/controllers/`, `config.ru` | Rails routing, controllers, Rack entry point |
   | `src/main/java/**/*Application.java` (`@SpringBootApplication`), `@RestController`/`@Controller` classes | Spring Boot bootstrap class, REST/MVC controllers |
   | `routes/web.php`, `routes/api.php`, `app/Http/Controllers/` | Laravel routing and controllers |
   | `Program.cs`, `Startup.cs`, `Controllers/` | ASP.NET / .NET app bootstrap, middleware pipeline, MVC/API controllers |
   ```

   Append these 6 rows to the end of the `### Models & Schemas` table (currently ending with the `interfaces/`, `*.interface.*` row at line 95):

   ```markdown
   | `models.py`, `<app>/models.py`, `migrations/` | Django ORM models and migration history |
   | `models.py` (SQLAlchemy `db.Model` classes), `schemas.py` (Marshmallow/Pydantic) | Flask ORM models and serialization schemas |
   | `app/models/`, `db/schema.rb`, `db/migrate/` | Rails ActiveRecord models and schema/migration history |
   | `@Entity`-annotated classes, `src/main/resources/db/migration/`, `repository/` | Spring JPA entities, Flyway migrations, Spring Data repositories |
   | `app/Models/`, `database/migrations/` | Laravel Eloquent models and migration history |
   | `Models/`, EF Core `DbContext` classes, `Migrations/` | ASP.NET EF Core models and migration history |
   ```

   Directly under the `### Package & Dependency Files` heading, before the table, add one sentence documenting the ambiguous-signal handling (AC12):

   ```markdown
   When signals for two ecosystems both match in the same repo (e.g. a Django project bundling a small Flask-based tool), record both findings rather than forcing a single choice -- use the `<!-- VERIFY: ... -->` convention from the Scanner Accuracy section below so the user confirms during review.
   ```

2. **Verify references.** Run `grep -c "Django\|Flask\|Rails\|Spring\|Laravel\|ASP.NET" agents/scanner-agent.md` and confirm the count increased by 24 (6 ecosystems × 4 tables) from the pre-edit baseline of 0. Confirm each of the 4 tables still has a well-formed header/separator row and every new row has exactly 2 columns (matching the existing `| X | Y |` shape).

3. **Commit.**

   ```
   feat(scanner-agent): detect Django, Flask, Rails, Spring, Laravel, .NET
   ```

### Task 2: Replace the inline Context7 MCP Usage section with a pointer

**Files:**
- Modify: `agents/scanner-agent.md`

**Interfaces:**
- Consumes: `skills/project/reference/context7-usage.md` (Phase 1, Task 1) — the shared doc this section now points to.
- Produces: the updated `## Context7 MCP Usage` section in `agents/scanner-agent.md`, which is the template Phases 3–4's 10 pointer sections follow (framing line + pointer sentence).

**Acceptance Criteria:** AC5

**Steps:**

1. **Write content.** In `agents/scanner-agent.md`, replace the existing `## Context7 MCP Usage` section (the final section of the file) in full:

   Current content being replaced:

   ```markdown
   ## Context7 MCP Usage

   Use the context7 MCP server to look up current documentation for any framework or library you encounter during scanning. This ensures version-accurate information about:
   - Framework conventions (e.g., Next.js App Router vs Pages Router)
   - Configuration file schemas (e.g., valid Tailwind config keys)
   - Default directory structures for detected frameworks

   Query context7 when you need to confirm how a framework organizes its code, not for general programming concepts.
   ```

   New content:

   ```markdown
   ## Context7 MCP Usage

   Confirm framework conventions, config schemas, and default directory structures for a detected ecosystem.

   See `skills/project/reference/context7-usage.md` for the full call flow, query scoping, and budget discipline.
   ```

2. **Verify references.** Confirm `agents/scanner-agent.md` contains the literal string `skills/project/reference/context7-usage.md` exactly once, and that the `## Context7 MCP Usage` section is still the last `##` heading in the file (unchanged position).

3. **Commit.**

   ```
   docs(scanner-agent): point Context7 MCP Usage at shared reference doc
   ```

---

## Phase 2 Complete

`scanner-agent` now detects 6 additional ecosystems at full depth across all four scan tables, and its own context7 section is a short pointer matching the pattern the remaining 10 agents will adopt in Phases 3–4.

**Next:** `phase-3.md`
