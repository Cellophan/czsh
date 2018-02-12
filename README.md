# czsh
[zsh](https://en.wikipedia.org/wiki/Z_shell) with [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) and [agnoster theme](https://github.com/agnoster/agnoster-zsh-them) in a container.

This is thought as a toolbox and contains:

* `docker` (the client)
* `docker-compose`
* Shortcuts for docker compose: `up`, `down`, `logs`, `pull`, `scale`, `start`, `stop`, `ps`
* `refresh` for pulling the image itself.
* `drone` client.


## Use

The goal is to feel at home without impacting the host itself. There are 2 ways to start the container:
* `czsh`: The current directory is mounted inside the container.
* `me`: Each sub-directory of your HOME directory are mounted in the container.

Each of them can be started as a shell or as an environment for a single command:

* As a shell:

```
$ czsh

```

* As an environment:

```
$ czsh command
```

## Install / Deploy

This is just a shortcut added in `/usr/local/bin`:

```
docker run --rm --entrypoint install -v /usr/local/bin:/installdir cell/czsh
```

### powerline

One nice thing of the [agnoster theme](https://github.com/agnoster/agnoster-zsh-them) is the prompt. Sadly it relies on some fonts on your host and compatibilities with your terminal. `czsh` doesn't solve this problem.

What worked for me is to follow the steps in the `Dockerfile` of this project after `#powerline`, [there](https://github.com/Cellophan/czsh/blob/master/Dockerfile).

## Others

This image rely on [cell/playground](https://github.com/Cellophan/dockerized-playground).

A similar image centered on `vim` is [cell/cvim](https://github.com/Cellophan/cvim).
