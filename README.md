# dyb

dyb, d-docker and y-yaml for b-bash, Default docker container definition in YAML for containerized execution of a single line bash command.

It is convenient to use docker containers as an environment for development. This project seeks to make it extremely convenient to execute a bash command inside a docker container whose image (docker build) and container (docker run) command line arguments are managed by dyb.yml.

Running commands from your local host operating system are as simple as:

```bash
dyb echo "Hello World"
```

Spawning a less ephemeral container for your development is easy as well. Run this command, and then use `docker exec -it /bin/bash` to login:

```bash
dyb --dev_workspace_container
```

## Auto-completion

Add this to your bash profile for local operating system auto complete (assumes Mac or Linux):

```bash
# Autocomplete function for dyb to mimic default Bash shell completion
_dyb() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    # Complete using both files and commands in PATH
    COMPREPLY=($(compgen -c -f -- "$cur"))
}

# Enable the new autocompletion for the 'dyb' command
complete -F _dyb dyb
```