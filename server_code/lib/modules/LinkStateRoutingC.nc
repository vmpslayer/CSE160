configuration LinkStateRoutingC
{
    provides interface LinkStateRouting;
}
implementation
{
    components LinkStateRoutingP;
    LinkStateRouting = LinkStateRoutingP.LinkStateRouting;

    components new TimerMilliC() as linkStateTimer;
    LinkStateRoutingP.linkStateTimer -> linkStateTimer;

    components new NeighborDiscoveryC() as NeighborDiscovery;
    LinkStateRoutingP.NeighborDiscovery -> NeighborDiscovery;

    components new FloodingC() as Flooding;
    LinkStateRoutingP.Flooding -> Flooding;
}