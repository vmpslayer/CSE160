configuration TransportC{
    provides interface Transport;
}
implementation{
    components TransportP;
    Transport = TransportP.Transport;

    // components new QueueC(socket_t*, 10) as socketQueue;
    // TransportP.socketQueue -> socketQueue;

    components new QueueC(socket_t*, 10) as socketConnectionQueue;
    TransportP.socketConnectionQueue -> socketConnectionQueue;

    components new QueueC(socket_t*, 10) as socketDisconnectionQueue;
    TransportP.socketDisconnectionQueue ->socketDisconnectionQueue;

    // components new TimerMilliC() as transportTimer;
    // TransportP.transportTimer -> transportTimer;

    // Connecting to a socket
    components new TimerMilliC() as attemptConnectionTimer;
    TransportP.attemptConnectionTimer -> attemptConnectionTimer;

    // Writing to a socket
    components new TimerMilliC() as clientWriteTimer;
    TransportP.clientWriteTimer -> clientWriteTimer;

    // Disconnecting from a socket
    components new TimerMilliC() as disconnectTimer;
    TransportP.disconnectTimer -> disconnectTimer;
    
    components LinkStateRoutingC as LinkStateRouting;
    TransportP.LinkStateRouting -> LinkStateRouting;
}