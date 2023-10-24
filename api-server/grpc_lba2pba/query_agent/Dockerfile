FROM ubuntu:22.04
RUN apt update -y && apt install -y net-tools python3.10 python3-pip python3-dev
COPY ./requirement.txt /app/requirement.txt
WORKDIR /app
RUN python3 -m pip install pip --upgrade
RUN python3 -m pip install -r requirement.txt
COPY . /app
CMD [ "python3", "query_agent.py" ]
