
publish-app:
	dotnet publish -c Release

docker-build:
	docker build -t ardimr/grpc-hello-world:$(TAG) .

docker-run:
	docker container run -p 80:80-n grpc-hello-world ardimr/grpc-hello-world:$(TAG)

docker-push:
	docker image push ardimr/grpc-hello-world:$(TAG)
# docker container run -p 8080:8080 --rm --name grpc-hello-world ardimr/grpc-hello-world:dev

create-replica-set:
	kubectl apply -f backend-replica-set.yaml
delete-replica-set:
	kubectl delete -f backend-replica-set.yaml

create-load-balancer:
	kubectl apply -f backend-load-balancer.yaml
delete-load-balancer:
	kubectl delete -f backend-load-balancer.yaml

create-ingress:
	kubectl apply -f ingress.yaml
delete-ingress:
	kubectl delete -f ingress.yaml

grpc-client:
	grpcurl -plaintext -import-path Protos/ -proto greet.proto -d '{"name": "ardi"}' af2c10f64eeda42348fbd95dd98ad8d8-1643405534.ap-southeast-3.elb.amazonaws.com:80 greet.Greeter/SayHelloWorld
