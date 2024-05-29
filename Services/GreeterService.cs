using Google.Protobuf.WellKnownTypes;
using Grpc.Core;
using GrpcHelloWorld;

namespace GrpcHelloWorld.Services;

public class GreeterService : Greeter.GreeterBase
{
    private readonly ILogger<GreeterService> _logger;
    public GreeterService(ILogger<GreeterService> logger)
    {
        _logger = logger;
    }

    public override Task<HelloWorldReply> SayHelloWorld(Empty request, ServerCallContext context)
    {
        return Task.FromResult(new HelloWorldReply
        {
            Message = "Hello, World!"
        });
    }
}
