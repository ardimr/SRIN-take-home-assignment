
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

create-eks-grpcserver:
	kubectl apply -f k8s/eks-grpcserver.yaml
delete-eks-grpcserver:
	kubectl delete -f k8s/eks-grpcserver.yaml
grpc-client:
	grpcurl -cacert my-certificate.pem -plaintext -import-path Protos/ -proto greet.proto k8s-developm-backendi-bdbfceaea2-1916316558.ap-southeast-3.elb.amazonaws.com:80 greet.Greeter/SayHelloWorld
