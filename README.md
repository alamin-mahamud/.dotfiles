## Python Workflow:

Here’s how you can use this setup with best practices in mind:

### Install & Manage Python Versions with `pyenv`:

Use `pyenv` to install & manage the desired Python version for your project.

```bash
pyenv install 3.11.0
pyenv global 3.11.0

# setting a python version for only a specific project
pyenv local 3.11.0
```

### Project dependencies with `pipenv`:

Navigate to your project directory and start using `pipenv` to manage dependencies and virtual environments.

```bash
# This will use the version of Python managed by pyenv and 
# create a virtual environment specific to your project.
pipenv install --python $(pyenv which python)

# install a package for that specific venv
pipenv install requests 

# Activate venv by running
pipenv shell

# lock the exact versions of all installed packages
pipenv lock
```

### Install & manage global python tools with pipx

```bash
# install tools
pipx install black
pipx install httpie

# list all tools installed by pipx
pipx list

# Once installed with pipx, you can use the tools as if they were installed globally
black myfile.py
http httpbin.org/get

# upgrade / uninstall tools
pipx upgrade black
pipx uninstall httpie
```