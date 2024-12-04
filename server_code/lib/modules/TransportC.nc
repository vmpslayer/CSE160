configuration TransportC{
    provides interface Transport;
}
implementation{
    components TransportP;
    Transport = TransportP.Transport;

    // components new QueueC(socket_t*, 10) as socketQueue;
    // TransportP.socketQueue -> socketQueue;

    // Sockets trying to connect
    components new QueueC(socket_t, 10) as socketConnectionQueue;
    TransportP.socketConnectionQueue -> socketConnectionQueue;

    // Sockets trying to transmit data
    components new QueueC(socket_t, 10) as socketTransmitQueue;
    TransportP.socketTransmitQueue -> socketTransmitQueue;

    // Sockets trying to receive data
    components new QueueC(socket_t, 10) as socketReceiveQueue;
    TransportP.socketReceiveQueue -> socketReceiveQueue;

    // Sockets trying to disconnect
    components new QueueC(socket_t, 10) as socketDisconnectionQueue;
    TransportP.socketDisconnectionQueue ->socketDisconnectionQueue;

    // Sockets trying to retry
    components new QueueC(socket_t, 10) as socketRetryQueue;
    TransportP.socketRetryQueue ->socketRetryQueue;

    // components new TimerMilliC() as transportTimer;
    // TransportP.transportTimer -> transportTimer;

    // Connecting to a socket
    components new TimerMilliC() as attemptConnectionTimer;
    TransportP.attemptConnectionTimer -> attemptConnectionTimer;

    // Writing to a socket
    components new TimerMilliC() as transmitTimer;
    TransportP.transmitTimer -> transmitTimer;

    // Receive from a socket
    components new TimerMilliC() as receiveTimer;
    TransportP.receiveTimer -> receiveTimer;

    // Disconnecting from a socket
    components new TimerMilliC() as disconnectTimer;
    TransportP.disconnectTimer -> disconnectTimer;
    
    // Used for forwarding
    components LinkStateRoutingC as LinkStateRouting;
    TransportP.LinkStateRouting -> LinkStateRouting;
}