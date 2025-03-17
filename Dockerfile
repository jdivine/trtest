FROM ubuntu:24.04

ENV PYTHONFAULTHANDLER=1 \
  PYTHONUNBUFFERED=1 \
  POETRY_NO_INTERACTION=1 

# I would probably not use the Ubuntu image for a real prod container (probably the slim Python image instead)
# And I would not want to run apt update / upgrade on every CI run - too slow and potentially glitchy.
# We'd use a consistent, recent baseline, either from upstream or maintained ourselves depending.
RUN apt update -y && apt upgrade -y && apt install -y python3-pip pipx

USER ubuntu

# The while one-liner is working around a weird non-deterministic SSL issue I was encountering locally on Ubuntu.
# it randomly failed with an SSL error but would eventually work if retried! Feels like a network glitch but IDK.
# I would never want to do this in a real-world build but don't think that isolating the issue is relevant in this example.
RUN while ( ! pipx list | grep poetry ) ; do pipx install poetry ; done

WORKDIR /app

COPY . /app

RUN ~/.local/bin/poetry install --no-root --no-interaction --no-ansi

WORKDIR /app/src

ENTRYPOINT ~/.local/bin/poetry run python -m uvicorn api:app --host 0.0.0.0
