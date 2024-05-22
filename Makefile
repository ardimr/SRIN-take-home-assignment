
publish-app:
	dotnet publish -c Release

docker-build:
	docker build -t ardimr/grpc-hello-world:$(TAG) .

docker-run:
	docker container run -p 80:80-n grpc-hello-world ardimr/grpc-hello-world:$(TAG)

# docker container run -p 8080:8080 --rm --name grpc-hello-world ardimr/grpc-hello-world:dev 