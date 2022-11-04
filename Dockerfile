ARG SMALLFILE_VERSION="1.1"

#stage 1
FROM quay.io/centos/centos:stream8

ARG SMALLFILE_VERSION

RUN dnf install -y wget

RUN mkdir /smallfile
RUN chmod 777 /smallfile
WORKDIR /smallfile
USER 1000
RUN wget https://github.com/distributed-system-analysis/smallfile/archive/refs/tags/${SMALLFILE_VERSION}.tar.gz
RUN tar xzf ${SMALLFILE_VERSION}.tar.gz

#stage 2
FROM quay.io/centos/centos:stream8

ARG SMALLFILE_VERSION

RUN dnf module -y install python39 && dnf install -y python39 python39-pip

RUN mkdir /plugin
RUN chmod 777 /plugin
ADD README.md /plugin/
ADD poetry.lock /plugin/
ADD pyproject.toml /plugin/
ADD smallfile_plugin.py /plugin/
ADD smallfile_schema.py /plugin/
ADD test_smallfile_plugin.py /plugin/
ADD smallfile-example.yaml /plugin/
ADD https://raw.githubusercontent.com/arcalot/arcaflow-plugins/main/LICENSE /plugin/
RUN chmod +x /plugin/smallfile_plugin.py /plugin/test_smallfile_plugin.py
COPY --from=0 /smallfile/smallfile-${SMALLFILE_VERSION} /plugin/smallfile
RUN chmod 777 /plugin/smallfile
WORKDIR /plugin

RUN pip3 install poetry
RUN poetry config virtualenvs.create false
RUN poetry install --without dev
USER 1000
RUN /plugin/test_smallfile_plugin.py


ENTRYPOINT ["/plugin/smallfile_plugin.py"]
CMD []

LABEL org.opencontainers.image.source="https://github.com/arcalot/arcaflow-plugin-smallfile"
LABEL org.opencontainers.image.licenses="Apache-2.0+GPL-2.0-only"
LABEL org.opencontainers.image.vendor="Arcalot project"
LABEL org.opencontainers.image.authors="Arcalot contributors"
LABEL org.opencontainers.image.title="Arcaflow Smallfile workload plugin"
LABEL io.github.arcalot.arcaflow.plugin.version="1"
