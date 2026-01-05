# Contributing to DevOps Shell Arsenal

Thank you for considering contributing! This repository thrives on real-world scripts from the DevOps community.

## How to Contribute

### 1. Script Contribution
If you have a production script that solved a real problem:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-awesome-script`)
3. Add your script to the appropriate directory
4. Ensure your script follows the guidelines below
5. Submit a Pull Request

### 2. Documentation Improvements
Documentation updates are always welcome:
- Fix typos or unclear explanations
- Add more examples to existing guides
- Create new advanced command guides

### 3. Bug Fixes
Found a bug? Please:
1. Open an issue describing the bug
2. Submit a PR with the fix
3. Include test cases if applicable

---

## Script Guidelines

Every contributed script must follow these standards:

### Required Elements
1. **Header comment block** with:
   - Script name
   - Description
   - Usage
   - Author
   - Dependencies

2. **Safety features**:
   ```bash
   set -euo pipefail
   ```

3. **Help/usage function**:
   ```bash
   usage() {
       cat << EOF
   Usage: script.sh [OPTIONS]
   ...
   EOF
   }
   ```

4. **Error handling**:
   - Check dependencies
   - Validate inputs
   - Meaningful error messages

5. **Dry-run mode** for destructive operations

6. **Logging** for important actions

7. **Executable permissions**:
   ```bash
   chmod +x your-script.sh
   ```

### Code Quality
- **ShellCheck clean**: Run `shellcheck your-script.sh` and fix all warnings
- **Comments**: Explain complex logic
- **Naming**: Use descriptive variable names
- **Quoting**: Always quote variables

### Documentation
Create a README or update the existing one with:
- **Use case**: When to use this script
- **Example usage**: Real-world example
- **Prerequisites**: Required tools/permissions
- **Common issues**: Known gotchas

---

## Testing Your Script

Before submitting:

1. **Run ShellCheck**:
   ```bash
   shellcheck your-script.sh
   ```

2. **Test in isolated environment**:
   - Use a test AWS account / GCP project
   - Test with sample data
   - Verify error handling

3. **Test dry-run mode**:
   ```bash
   ./your-script.sh --dry-run
   ```

4. **Test help function**:
   ```bash
   ./your-script.sh --help
   ```

---

## Pull Request Process

1. **Descriptive title**: Use format `Add: [Category] Script name`
   - Example: `Add: [Kubernetes] Resource quota checker`

2. **Clear description**:
   - What problem does this solve?
   - Real-world use case
   - Any special considerations

3. **Checklist**:
   - [ ] Script follows guidelines
   - [ ] Passed ShellCheck
   - [ ] Tested in isolated environment
   - [ ] Documentation added/updated
   - [ ] Example usage provided
   - [ ] No hardcoded credentials

4. **Review process**:
   - Maintainers will review within 1 week
   - Address feedback promptly
   - Be open to suggestions

---

## What We're Looking For

### High Priority
- **Real production scenarios** (not academic examples)
- **Cloud automation** (AWS, GCP, Azure)
- **Kubernetes utilities**
- **Security and compliance** scripts
- **Performance troubleshooting** tools

### Not Accepted
- Basic tutorials (e.g., "hello world")
- Scripts with hardcoded credentials
- Unmaintainable "clever" one-liners without explanation
- Scripts without error handling

---

## Code of Conduct

- Be respectful and professional
- Provide constructive feedback
- Focus on the code, not the person
- Help newcomers

---

## Questions?

- Open an issue for questions
- Tag with `question` label
- We'll respond within a few days

---

**Thank you for helping make DevOps easier for everyone!** 🙌
