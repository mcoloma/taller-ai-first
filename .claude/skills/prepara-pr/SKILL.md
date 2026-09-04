---
name: prepara-pr
description: Corre los controles de calidad del proyecto (ruff, bandit, pytest, Conventional Commits) y, si todos pasan y el subagente revisor-pr aprueba el diff, abre el Pull Request de la rama actual contra main con gh. Usar cuando el usuario pida abrir/crear un PR, preparar un PR, o publicar la rama actual.
---

# prepara-pr

Automatiza la apertura de un Pull Request de la rama actual contra `main`, pero solo si pasa una serie de controles de calidad y la revisión del subagente `revisor-pr`. Nunca abras el PR si algún control falla o si el revisor rechaza el diff.

## Flujo

1. **Verifica el estado del repo.** Confirma que no estás en `main` y que hay commits en la rama actual que no están en `main` (`git log main..HEAD`). Si no hay nada que subir, avisa al usuario y detente.

2. **Ejecuta los gates.** Corre el script `gates.sh` de esta misma carpeta del skill:

   ```sh
   bash .claude/skills/prepara-pr/gates.sh
   ```

   El script imprime la salida de cada uno de los cuatro controles (ruff, bandit, pytest, Conventional Commits) y termina con código de salida 1 si alguno falla.

   - Si el script termina con código distinto de 0: **no abras el PR**. Muestra al usuario qué control(es) fallaron (según la salida del script) y detente ahí. No intentes arreglar el código automáticamente salvo que el usuario lo pida explícitamente.

3. **Si todos los gates pasan**, pide la revisión del diff al subagente `revisor-pr` (rama actual vs `main`). Usa el agente ya definido en `.claude/agents/revisor-pr.md`; no reimplementes sus criterios aquí.

4. **Evalúa el veredicto del revisor:**
   - Si el veredicto es **RECHAZADO**: no abras el PR. Muestra al usuario el resumen y la lista de problemas que reportó `revisor-pr`, y detente.
   - Si el veredicto es **APROBADO**: continúa al siguiente paso.

5. **Abre el PR con `gh`.** Asegúrate primero de que la rama actual esté publicada en el remoto (si `git status` indica que no hay upstream, haz `git push -u origin <rama-actual>`; si ya existe upstream, no hace falta pushear de nuevo salvo que haya commits locales sin subir). Luego crea el PR:

   ```sh
   gh pr create --base main --head <rama-actual> --title "<título>" --body "<descripción>"
   ```

   - El título debe resumir el cambio principal de la rama (puedes basarte en el/los commit(s) más relevantes).
   - El body debe incluir un resumen breve de los cambios y, si `revisor-pr` señaló observaciones menores (severidad Media/Baja) que no bloquean, puedes mencionarlas como nota para el reviewer humano.
   - Al terminar, entrega al usuario la URL del PR que devuelve `gh pr create`.

## Reglas importantes

- Nunca uses `--no-verify` ni saltes ninguno de los cuatro controles.
- Nunca abras el PR si `gates.sh` falló o si `revisor-pr` rechazó el diff, sin importar cuán menor parezca el problema.
- No hagas push forzado ni reescribas commits para "arreglar" el formato de Conventional Commits sin que el usuario lo pida explícitamente — si los commits no cumplen el formato, repórtalo y deja que el usuario decida cómo corregirlo (rebase interactivo, amend, etc.).
- Si `gh` no tiene sesión autenticada o el remoto no está configurado, informa el error tal cual y detente; no intentes workarounds.
