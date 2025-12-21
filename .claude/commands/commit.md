# Claude Command: Commit

This command helps you create well-formatted commits with conventional commit messages and emoji.

## Usage

To create a commit, just type:

```text
/commit
```

Or with options:

```text
/commit --no-verify
```

## What This Command Does

1. Unless specified with `--no-verify`, automatically runs pre-commit checks:
   - `pnpm lint` to ensure code quality
   - `pnpm build` to verify the build succeeds
   - `pnpm generate:docs` to update documentation
2. Checks which files are staged with `git status`
3. If 0 files are staged, automatically adds all modified and new files with `git add`
4. Performs a `git diff` to understand what changes are being committed
5. Analyzes the diff to determine if multiple distinct logical changes are present
6. If multiple distinct changes are detected, suggests breaking the commit into multiple smaller commits
7. For each commit (or the single commit if not split), creates a commit message using emoji conventional commit format

## Monorepo Commit Format

This is a monorepo project containing multiple datapacks. All commit messages **must** include the changed project's name tag in the format `[PROJECT_ABBR]` where the abbreviation is derived from the first letter of each word in the project name (uppercase).

- **With project tag**: `[DFL] ✨ feat: add new library function`
- **Without project tag** (for repository-wide changes): `♻️ refactor: update build system`

### Project Abbreviation Rules

1. **Abbreviation derivation**: Take the first letter of each word in the project name, convert to uppercase
   - Example: "datapack function library" → "DFL"
   - Example: "stone disappearance" → "SD"
   - Example: "auto lucky block" → "ALB"

2. **When to use project tags**:
   - Changes specific to a single datapack project
   - Modifications within a project's directory
   - Updates to project-specific configuration

3. **When to omit project tags**:
   - Repository-wide changes (e.g., root `.github/`, `rule/`, `template/`)
   - Build system updates affecting all projects
   - Documentation changes covering multiple projects
   - CI/CD configuration changes

### Commit Message Format

The complete commit message format for this monorepo is:

```text
[PROJECT_ABBR] <emoji> <type>: <description>
```

Where:

- `[PROJECT_ABBR]` - Optional project abbreviation tag (omit for repository-wide changes)
- `<emoji>` - Appropriate emoji for the commit type (see below)
- `<type>` - Conventional commit type (feat, fix, docs, etc.)
- `<description>` - Concise description in imperative mood

## Best Practices for Commits

- **Verify before committing**: Ensure code is linted, builds correctly, and documentation is updated
- **Atomic commits**: Each commit should contain related changes that serve a single purpose
- **Split large changes**: If changes touch multiple concerns, split them into separate commits
- **Conventional commit format**: Use the format `<type>: <description>` where type is one of:
  - `feat`: A new feature
  - `fix`: A bug fix
  - `docs`: Documentation changes
  - `style`: Code style changes (formatting, etc)
  - `refactor`: Code changes that neither fix bugs nor add features
  - `perf`: Performance improvements
  - `test`: Adding or fixing tests
  - `chore`: Changes to the build process, tools, etc.
- **Present tense, imperative mood**: Write commit messages as commands (e.g., "add feature" not "added feature")
- **Concise first line**: Keep the first line under 72 characters
- **Emoji**: Each commit type is paired with an appropriate emoji:
  - ✨ `feat`: New feature
  - 🐛 `fix`: Bug fix
  - 📝 `docs`: Documentation
  - 💄 `style`: Formatting/style
  - ♻️ `refactor`: Code refactoring
  - ⚡️ `perf`: Performance improvements
  - ✅ `test`: Tests
  - 🔧 `chore`: Tooling, configuration
  - 🚀 `ci`: CI/CD improvements
  - 🗑️ `revert`: Reverting changes
  - 🧪 `test`: Add a failing test
  - 🚨 `fix`: Fix compiler/linter warnings
  - 🔒️ `fix`: Fix security issues
  - 👥 `chore`: Add or update contributors
  - 🚚 `refactor`: Move or rename resources
  - 🏗️ `refactor`: Make architectural changes
  - 🔀 `chore`: Merge branches
  - 📦️ `chore`: Add or update compiled files or packages
  - ➕ `chore`: Add a dependency
  - ➖ `chore`: Remove a dependency
  - 🌱 `chore`: Add or update seed files
  - 🧑‍💻 `chore`: Improve developer experience
  - 🧵 `feat`: Add or update code related to multithreading or concurrency
  - 🔍️ `feat`: Improve SEO
  - 🏷️ `feat`: Add or update types
  - 💬 `feat`: Add or update text and literals
  - 🌐 `feat`: Internationalization and localization
  - 👔 `feat`: Add or update business logic
  - 📱 `feat`: Work on responsive design
  - 🚸 `feat`: Improve user experience / usability
  - 🩹 `fix`: Simple fix for a non-critical issue
  - 🥅 `fix`: Catch errors
  - 👽️ `fix`: Update code due to external API changes
  - 🔥 `fix`: Remove code or files
  - 🎨 `style`: Improve structure/format of the code
  - 🚑️ `fix`: Critical hotfix
  - 🎉 `chore`: Begin a project
  - 🔖 `chore`: Release/Version tags
  - 🚧 `wip`: Work in progress
  - 💚 `fix`: Fix CI build
  - 📌 `chore`: Pin dependencies to specific versions
  - 👷 `ci`: Add or update CI build system
  - 📈 `feat`: Add or update analytics or tracking code
  - ✏️ `fix`: Fix typos
  - ⏪️ `revert`: Revert changes
  - 📄 `chore`: Add or update license
  - 💥 `feat`: Introduce breaking changes
  - 🍱 `assets`: Add or update assets
  - ♿️ `feat`: Improve accessibility
  - 💡 `docs`: Add or update comments in source code
  - 🗃️ `db`: Perform database related changes
  - 🔊 `feat`: Add or update logs
  - 🔇 `fix`: Remove logs
  - 🤡 `test`: Mock things
  - 🥚 `feat`: Add or update an easter egg
  - 🙈 `chore`: Add or update .gitignore file
  - 📸 `test`: Add or update snapshots
  - ⚗️ `experiment`: Perform experiments
  - 🚩 `feat`: Add, update, or remove feature flags
  - 💫 `ui`: Add or update animations and transitions
  - ⚰️ `refactor`: Remove dead code
  - 🦺 `feat`: Add or update code related to validation
  - ✈️ `feat`: Improve offline support

## Guidelines for Splitting Commits

When analyzing the diff, consider splitting commits based on these criteria:

1. **Different concerns**: Changes to unrelated parts of the codebase
2. **Different types of changes**: Mixing features, fixes, refactoring, etc.
3. **File patterns**: Changes to different types of files (e.g., source code vs documentation)
4. **Logical grouping**: Changes that would be easier to understand or review separately
5. **Size**: Very large changes that would be clearer if broken down

## Examples

Good commit messages:

### Project-specific changes (with project abbreviation)

- [DFL] ✨ feat: add new library function for item manipulation
- [SD] 🐛 fix: resolve stone disappearance timing issue
- [ALB] 📝 docs: update auto lucky block configuration guide
- [DFL] ♻️ refactor: simplify function error handling logic
- [SD] 🚨 fix: resolve linter warnings in tick function
- [ALB] 🧑‍💻 chore: improve developer tooling setup process
- [DFL] 👔 feat: implement business logic for item validation
- [SD] 🩹 fix: address minor timing inconsistency in animation

### Repository-wide changes (without project abbreviation)

- ♻️ refactor: update build system configuration for all datapacks
- 📝 docs: update repository README with new project structure
- 🔧 chore: add new CI workflow for automated testing
- 🚨 fix: resolve linter configuration issues affecting all projects
- 🧑‍💻 chore: improve developer documentation for monorepo setup
- ✅ test: add integration tests for cross-datapack function calls

### Example of splitting commits for a datapack project

Suppose you're making changes to the "datapack function library" project. Instead of one large commit, you could split it into:

- First commit: [DFL] ✨ feat: add new function for item manipulation
- Second commit: [DFL] 📝 docs: update function documentation with usage examples
- Third commit: [DFL] 🔧 chore: update dependency configuration
- Fourth commit: [DFL] 🏷️ feat: add type annotations for function parameters
- Fifth commit: [DFL] 🧵 feat: improve performance with concurrent processing
- Sixth commit: [DFL] 🚨 fix: resolve linter warnings in new code
- Seventh commit: [DFL] ✅ test: add unit tests for new functions
- Eighth commit: [DFL] 🔒️ fix: update dependencies with security patches

### Example of splitting repository-wide changes

For repository-wide changes affecting multiple projects:

- First commit: ♻️ refactor: update build system for all datapacks
- Second commit: 📝 docs: update repository documentation with new guidelines
- Third commit: 🔧 chore: add shared CI workflow configuration
- Fourth commit: ✅ test: add integration tests for cross-project compatibility
- Fifth commit: 🚨 fix: resolve shared configuration issues
- Sixth commit: 🧑‍💻 chore: improve developer setup documentation

## Command Options

- `--no-verify`: Skip running the pre-commit checks (lint, build, generate:docs)

## Important Notes

- By default, pre-commit checks (`pnpm lint`, `pnpm build`, `pnpm generate:docs`) will run to ensure code quality
- If these checks fail, you'll be asked if you want to proceed with the commit anyway or fix the issues first
- If specific files are already staged, the command will only commit those files
- If no files are staged, it will automatically stage all modified and new files
- The commit message will be constructed based on the changes detected
- Before committing, the command will review the diff to identify if multiple commits would be more appropriate
- If suggesting multiple commits, it will help you stage and commit the changes separately
- Always reviews the commit diff to ensure the message matches the changes
