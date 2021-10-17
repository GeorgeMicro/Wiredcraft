# get base image
FROM python:3.8

MAINTAINER George Zhao <microgeorge1993@gmail.com>

WORKDIR /fastapi-app

COPY requirements.txt .

RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt

COPY ./app ./app

CMD [ "python", "./app/main.py"]

