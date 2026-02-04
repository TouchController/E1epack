---
name: commit
description: 创建符合规范的提交信息，支持常规提交格式和emoji。使用 /commit 来创建提交。
---

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

### Complete Commit Message Format

The complete commit message format for this monorepo is:

```text
[PROJECT_ABBR] <emoji> <type>: <description>

<detailed_description>

<footers>
```

Where:

- **Line 1 (Required)**: `[PROJECT_ABBR] <emoji> <type>: <description>`
- **Line 2 (Required)**: Empty line separator
- **Lines 3+ (Optional)**: Detailed description explaining the "why" and context
- **Final Lines (Optional)**: Footer metadata like issue references

### Format Requirements

1. **Title Line (First Line)**:
   - **Length**: Maximum 72 characters (preferably under 50)
   - **Format**: `[PROJECT_ABBR] <emoji> <type>: <description>`
   - **Mood**: Imperative present tense (e.g., "add feature" not "added feature")
   - **Content**: Concise summary of what changes

2. **Body (Optional but Recommended)**:
   - **Separation**: Must be separated from title by a single blank line
   - **Purpose**: Explain the **reasoning** behind the change, not just what changed
   - **Content**:
     - What problem does this solve?
     - What context is important for future developers?
     - Any technical details that aren't obvious from the code?
   - **Format**: Each line should be wrapped at 72 characters

3. **Footers (Optional)**:
   - **Separation**: Must be separated from body by a single blank line
   - **Content**:
     - Issue references: `Fixes #123`, `Closes #456`
     - Breaking changes: `BREAKING CHANGE: <description>`
     - Co-authors: `Co-authored-by: Name <email>`
   - **Format**: Each footer on its own line

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

## Best Practices for Commits

### Core Principles

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
- **Emoji**: Each commit type is paired with an appropriate emoji (see list below)

### Multi-line Commit Message Guidelines

**When to use multi-line messages:**

- Complex changes that need explanation
- Bug fixes with important context
- Features that require usage documentation
- Changes with potential side effects
- Refactoring that changes behavior

**When single-line is acceptable:**

- Trivial changes (typo fixes, simple renames)
- Obvious changes that are self-explanatory
- Automated tooling changes

**Body content best practices:**

- Explain the **why**, not the **what** (code shows what changed)
- Provide context for future maintainers
- Include relevant technical details
- Mention any trade-offs or alternative approaches considered
- Reference related commits or issues

**Example structure:**

```text
[DFL] ✨ feat: add item validation function

Adds a new validation function to check item properties before
processing. This prevents crashes when handling malformed items
and improves error messages for debugging.

The validation is performed before any transformations to ensure
data integrity throughout the pipeline. This addresses issue #123
where invalid items caused silent failures.

Fixes #123
```

## Conventional Commit Types with Emoji

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

### Single-line Examples

**Project-specific changes (with project abbreviation):**

- `[DFL] ✨ feat: add new library function for item manipulation`
- `[SD] 🐛 fix: resolve stone disappearance timing issue`
- `[ALB] 📝 docs: update auto lucky block configuration guide`
- `[DFL] ♻️ refactor: simplify function error handling logic`

**Repository-wide changes (without project abbreviation):**

- `♻️ refactor: update build system configuration for all datapacks`
- `📝 docs: update repository README with new project structure`
- `🔧 chore: add new CI workflow for automated testing`

### Multi-line Examples

**Project-specific feature with context:**

```text
[DFL] ✨ feat: add item validation function

Adds a new `validateItem()` function to check item properties before
processing. This prevents crashes when handling malformed items and
provides clear error messages for debugging.

Key improvements:
- Validates item ID format and metadata structure
- Checks for required NBT tags
- Returns detailed error objects instead of boolean
- Includes unit tests for edge cases

This addresses the silent failures reported in issue #123.
```

**Bug fix with technical details:**

```text
[SD] 🐛 fix: resolve stone disappearance timing issue

Fixes a race condition where stones would disappear before their
animation completed. The issue occurred because the cleanup function
was called too early in the tick cycle.

Changes:
- Moved cleanup logic to run after animation check
- Added 2-tick delay before removal
- Updated state management to track animation progress

Fixes #456
```

**Refactoring with breaking changes:**

```text
[ALB] ♻️ refactor: restructure lucky block configuration

BREAKING CHANGE: Configuration file format has changed

The old flat structure has been replaced with a nested format for
better organization and future extensibility.

Old format:
{
  "drop_chance": 0.1,
  "reward_count": 3
}

New format:
{
  "rewards": {
    "drop_chance": 0.1,
    "count": 3
  }
}

Migration guide: See MIGRATION.md for detailed upgrade instructions.

```

**Repository-wide change:**

```text
♻️ refactor: migrate from webpack to vite for all datapacks

Improves build performance and developer experience by switching
to Vite as the build tool.

Benefits:
- 10x faster hot reload
- Simpler configuration
- Better TypeScript support
- Reduced dependency count

All projects now use a unified build configuration located in
the root `build/` directory.

Co-authored-by: Developer Name <dev@example.com>
```

## Command Options

- `--no-verify`: Skip running the pre-commit checks (lint, build, generate:docs)

## Important Notes

- By default, pre-commit checks (`pnpm lint`, `pnpm build`, `pnpm generate:docs`) will run to ensure code quality
- If these checks fail, you'll be asked if you want to proceed with the commit or fix the issues first
- If specific files are already staged, the command will only commit those files
- If no files are staged, it will automatically stage all modified and new files
- The commit message will be constructed based on the changes detected
- Before committing, the command will review the diff to identify if multiple commits would be more appropriate
- If suggesting multiple commits, it will help you stage and commit the changes separately
- Always review the commit diff to ensure the message matches the changes
- **For multi-line messages**: The command will prompt for additional body content and footers when complex changes are detected
