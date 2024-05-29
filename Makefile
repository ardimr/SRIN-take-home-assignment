
publish-app:
	dotnet publish -c Release

docker-build:
	docker build -t ardimr/grpc-hello-world:$(TAG) .

docker-run:
	docker container run -p 80:80-n grpc-hello-world ardimr/grpc-hello-world:$(TAG)

docker-push:
	docker image push ardimr/grpc-hello-world:$(TAG)
# docker container run -p 8080:8080 --rm --name grpc-hello-world ardimr/grpc-hello-world:dev

create-deployment:
	kubectl apply -f k8s/deployment.yaml
delete-deployment:
	kubectl delete -f k8s/deployment.yaml

create-service:
	kubectl apply -f k8s/service.yaml
delete-service:
	kubectl delete -f k8s/service.yaml

create-ingress:
	kubectl apply -f k8s/ingress.yaml
delete-ingress:
	kubectl delete -f k8s/ingress.yaml

grpc-client:
	grpcurl -plaintext -import-path Protos/ -proto greet.proto a63a498f42b164e2d913fcbdbfc79307-1261931033.ap-southeast-3.elb.amazonaws.com:8888 greet.Greeter/SayHelloWorld
