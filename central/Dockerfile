# start by pulling the python image
FROM python:3.15-alpine

# copy the requirements file into the image
COPY ./requirements.txt /app/requirements.txt

# switch working directory
WORKDIR /app

# install the dependencies and packages in the requirements file
RUN pip install -r requirements.txt

RUN apk update && apk add git

# release version, passed in by the release workflow (shown in the UI)
ARG VERSION=unknown
ENV PIKIOSK_VERSION=$VERSION

# copy every content from the local file to the image
COPY . /app

# configure the container to run in an executed manner
ENTRYPOINT [ "python" ]

CMD ["pikiosk-central.py" ]

