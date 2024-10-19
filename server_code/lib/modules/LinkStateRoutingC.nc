configuration LinkStateRoutingC
{
    provides interface LinkStateRouting;
}
implementation
{
    components LinkStateRoutingP;
    LinkStateRouting = LinkStateRoutingP.LinkStateRouting;

    components new NeighborDiscoveryC() as NeighborDiscovery;
    LinkStateRoutingP.NeighborDiscovery -> NeighborDiscovery;
}