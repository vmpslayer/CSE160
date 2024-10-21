configuration LinkStateRoutingC
{
    provides interface LinkStateRouting;
}
implementation
{
    components LinkStateRoutingP;
    LinkStateRouting = LinkStateRoutingP.LinkStateRouting;

    components NeighborDiscoveryC as NeighborDiscovery;
    LinkStateRoutingP.NeighborDiscovery -> NeighborDiscovery;

    components FloodingC as Flooding;
    LinkStateRoutingP.Flooding -> Flooding;

    components new SimpleSendC(AM_PACK) as Sender;
    FloodingP.Sender -> Sender;
}