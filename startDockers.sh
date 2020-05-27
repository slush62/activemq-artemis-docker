#!/bin/sh

# create network definition
docker network create \
	--driver=bridge \
	--subnet=172.0.20.0/24 \
	--gateway=172.0.20.1 geoswarm

# start postgresDB
docker run --name=postgis \
	-d --network=geoswarm \
	-e POSTGRES_USER=geoserver \
	-e POSTGRES_PASS=geoserver \
	-e POSTGRES_DBNAME=geoserver \
	-e ALLOW_IP_RANGE=0.0.0.0/0 \
	-e DATADIR:/opt/postgres/data \
	-e DEFAULT_ENCODING=UTF8 \
	-e DEFAULT_COLLATION=id_ID.utf8 \
	-e DEFAULT_CTYPE=id_ID.utf8 \
	-p 5432:5432 \
	-v /opt/postgres/data:/var/lib/postgresql \
	-v /opt/postgres/xfer:/xfer \
	--restart=always postgres/postgis

# start GeoServer
docker run --name=geoserver \
	-d --network=geoswarm \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v /opt/geoserver/data/:/geoserver_data/data \
	-v /opt/geoserver/xfer:/xfer \
	-p 8080:8080 geoserver/postgres

# start initial artemis
docker run -it --rm --name=artemis \
	--network=geoswarm \
	-p 8161:8161 -p 61616:61616 \
	artemis-ubuntu

docker run -it --name=artemis \
	-d --network=geoswarm \
	-p 8161:8161 -p 61616:61616  \
	artemis-docker

docker run -it --name=dbwriter -d --network=geoswarm \
	-e QUEUENAME=dbQueue \
	-e ARTEMISURL=amqp://artemis:5672 \
	-e USERNAME=artemis \
	-e PASSWORD=simetraehcapa \
	artemis/dbwriter

docker run --name=convectivewarnings \
	-d --network=geoswarm \
	-e PURGEDAYS=30 \
	-e QUEUENAME="dbQueue" \
	-e ARTEMISURL="stomp://artemis:61613" \
	-e USERNAME="artemis" \
	-e PASSWORD="simetraehcapa" \
	perl/nwswarning
