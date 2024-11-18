configuration TransportC{
    provides interface Transport;
}
implementation{
    components TransportP;
    Transport = TransportP.Transport;

    components new TimerMilliC() as transportTimer;
    TransportP.transportTimer -> transportTimer;
    
    components LinkStateRoutingC as LinkStateRouting;
    TransportP.LinkStateRouting -> LinkStateRouting;
}