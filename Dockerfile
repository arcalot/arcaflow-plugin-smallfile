ARG package=arcaflow_plugin_smallfile
ARG SMALLFILE_VERSION="1.1"

# STAGE 1 -- Build module dependencies and run tests
# The 'poetry' and 'coverage' modules are installed and verson-controlled in the
# quay.io/arcalot/arcaflow-plugin-baseimage-python-buildbase image to limit drift
FROM quay.io/arcalot/arcaflow-plugin-baseimage-python-buildbase:0.2.0 as build
ARG package
ARG SMALLFILE_VERSION
ENV SMALLFILE_URL="https://github.com/distributed-system-analysis/smallfile/archive/refs/tags/${SMALLFILE_VERSION}.tar.gz"

# WORKDIR /smallfile
# USER 1000

RUN dnf install -y wget \
 && mkdir /smallfile \
 && chmod 777 /smallfile \
 && wget -O - ${SMALLFILE_URL}  | tar xvz -C /smallfile

COPY poetry.lock /app/
COPY pyproject.toml /app/

# Convert the dependencies from poetry to a static requirements.txt file
RUN python -m poetry install --without dev --no-root \
 && python -m poetry export -f requirements.txt --output requirements.txt --without-hashes

COPY ${package}/ /app/${package}
COPY tests /app/${package}/tests

ENV PYTHONPATH /app/${package}
WORKDIR /app/${package}

# Run tests and return coverage analysis
RUN python -m coverage run tests/test_${package}.py \
 && python -m coverage html -d /htmlcov --omit=/usr/local/*


# STAGE 2 -- Build final plugin image
FROM quay.io/arcalot/arcaflow-plugin-baseimage-python-osbase:0.2.0
ARG package

COPY --from=build /smallfile/ /smallfile/
COPY --from=build /app/requirements.txt /app/
COPY --from=build /htmlcov /htmlcov/
COPY LICENSE /app/
COPY README.md /app/
COPY ${package}/ /app/${package}

# Install all plugin dependencies from the generated requirements.txt file
RUN python -m pip install -r requirements.txt

WORKDIR /app/${package}

ENTRYPOINT ["python", "smallfile_plugin.py"]
CMD []

LABEL org.opencontainers.image.source="https://github.com/arcalot/arcaflow-plugin-smallfile"
LABEL org.opencontainers.image.licenses="Apache-2.0+GPL-2.0-only"
LABEL org.opencontainers.image.vendor="Arcalot project"
LABEL org.opencontainers.image.authors="Arcalot contributors"
LABEL org.opencontainers.image.title="Arcaflow Smallfile workload plugin"
LABEL io.github.arcalot.arcaflow.plugin.version="1"
