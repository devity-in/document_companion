# Contributing to Document Companion

Thank you for your interest in contributing to Document Companion! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## Getting Started

### Prerequisites

- Flutter SDK 3.47 or higher
- Dart SDK 3.13 or higher
- Git
- A code editor (VS Code, Android Studio, or IntelliJ IDEA recommended)

### Setting Up the Development Environment

1. **Fork the repository**
   ```bash
   # Click the "Fork" button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/devity-in/document_companion.git
   cd document_companion
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/originalusername/document_companion.git
   ```

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Development Workflow

### Creating a Branch

Always create a new branch for your work:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
# or
git checkout -b docs/your-documentation-update
```

### Branch Naming Convention

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Adding or updating tests
- `chore/` - Maintenance tasks

### Keeping Your Branch Updated

Regularly sync with the main branch:

```bash
git fetch upstream
git checkout main
git merge upstream/main
git checkout your-branch
git merge main
```

## Coding Standards

### Dart/Flutter Style Guide

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use `dart format` before committing
- Run `flutter analyze` to check for issues

### Code Formatting

```bash
# Format all Dart files
dart format .

# Analyze code
flutter analyze
```

### Architecture Guidelines

- **BLoC Pattern**: Use BLoC for state management
- **Separation of Concerns**: Keep UI, business logic, and data layers separate
- **Models**: Use immutable models where possible
- **Error Handling**: Always handle errors appropriately
- **Null Safety**: Use null safety features properly

### File Organization

- Group related files in modules
- Keep views, models, and business logic separate
- Use meaningful file and folder names

### Code Comments

- Write clear, concise comments
- Document public APIs
- Explain "why" not "what" in complex logic

## Commit Guidelines

### Commit Message Format

Use clear, descriptive commit messages:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(scanner): add edge detection for document scanning

- Implement automatic edge detection
- Add manual crop adjustment
- Update UI for crop preview

Closes #123
```

```
fix(database): prevent memory leak in StreamController

- Add dispose method to FolderBloc
- Properly close database connections

Fixes #456
```

## Pull Request Process

### Before Submitting

1. **Update your branch**
   ```bash
   git fetch upstream
   git merge upstream/main
   ```

2. **Run tests**
   ```bash
   flutter test
   ```

3. **Check code quality**
   ```bash
   flutter analyze
   dart format .
   ```

4. **Test on multiple platforms** (if possible)
   - Android
   - iOS
   - Web

### PR Checklist

- [ ] Code follows the project's style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated (if needed)
- [ ] Tests added/updated (if applicable)
- [ ] All tests pass
- [ ] No new warnings introduced
- [ ] Screenshots added (for UI changes)

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How was this tested?

## Screenshots (if applicable)

## Related Issues
Closes #issue_number
```

### Review Process

- Maintainers will review your PR
- Address feedback promptly
- Be open to suggestions and improvements
- Keep discussions respectful and constructive

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

1. **Clear title**
2. **Description** of the issue
3. **Steps to reproduce**
4. **Expected behavior**
5. **Actual behavior**
6. **Screenshots** (if applicable)
7. **Environment:**
   - Flutter version (`flutter --version`)
   - Device/OS information
   - App version

### Feature Requests

For feature requests, include:

1. **Clear title**
2. **Description** of the feature
3. **Use case** - why is this feature needed?
4. **Proposed solution** (if you have one)
5. **Alternatives considered**

## Questions?

- Open a [GitHub Discussion](https://github.com/devity-in/document_companion/discussions)
- Check existing [Issues](https://github.com/devity-in/document_companion/issues)
- Review the [README](README.md)

## Thank You!

Your contributions make this project better for everyone. We appreciate your time and effort! 🎉

