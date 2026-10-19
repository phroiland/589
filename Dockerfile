#
# Spiderfoot Dockerfile
#
# http://www.spiderfoot.net
#
# Written by: Michael Pellon <m@pellon.io>
# Updated by: Chandrapal <bnchandrapal@protonmail.com>
# Updated by: Steve Micallef <steve@binarypool.com>
# Updated by: Steve Bate <svc-spiderfoot@stevebate.net>
#    -> Inspired by https://github.com/combro2k/dockerfiles/tree/master/alpine-spiderfoot
#
# Usage:
#
#   sudo docker build -t spiderfoot .
#   sudo docker run -p 5001:5001 --security-opt no-new-privileges spiderfoot
#
# Using Docker volume for spiderfoot data
#
#   sudo docker run -p 5001:5001 -v /mydir/spiderfoot:/var/lib/spiderfoot spiderfoot
#
# Using SpiderFoot remote command line with web server
#
#   docker run --rm -it spiderfoot sfcli.py -s http://my.spiderfoot.host:5001/
#
# Running spiderfoot commands without web server (can optionally specify volume)
#
#   sudo docker run --rm spiderfoot sf.py -h
#
# Running a shell in the container for maintenance
#   sudo docker run -it --entrypoint /bin/sh spiderfoot
#
# Running spiderfoot unit tests in container
#
#   sudo docker build -t spiderfoot-test --build-arg REQUIREMENTS=test/requirements.txt .
#   sudo docker run --rm spiderfoot-test -m pytest --flake8 .

FROM python:3.13-alpine AS build
ARG REQUIREMENTS=requirements.txt
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1

# Wheels exist for the current dependency set (musllinux). Build tools are
# only required if a package falls back to a source build.
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /tmp/reqs
COPY requirements.txt requirements.txt
COPY test/requirements.txt test/requirements.txt
RUN pip install -U pip \
    && pip install --no-cache-dir -r "${REQUIREMENTS}"


FROM python:3.13-alpine
WORKDIR /home/spiderfoot

# Place database and logs outside installation directory
ENV SPIDERFOOT_DATA=/var/lib/spiderfoot \
    SPIDERFOOT_LOGS=/var/lib/spiderfoot/log \
    SPIDERFOOT_CACHE=/var/lib/spiderfoot/cache \
    PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN addgroup -S spiderfoot \
    && adduser -S -G spiderfoot -h /home/spiderfoot -s /sbin/nologin \
               -g "SpiderFoot User" spiderfoot \
    && mkdir -p "$SPIDERFOOT_DATA" "$SPIDERFOOT_LOGS" "$SPIDERFOOT_CACHE" \
    && chown spiderfoot:spiderfoot "$SPIDERFOOT_DATA" "$SPIDERFOOT_LOGS" "$SPIDERFOOT_CACHE"

COPY . .
COPY --from=build /opt/venv /opt/venv

USER spiderfoot

EXPOSE 5001

# Run the application.
ENTRYPOINT ["/opt/venv/bin/python"]
CMD ["sf.py", "-l", "0.0.0.0:5001"]
