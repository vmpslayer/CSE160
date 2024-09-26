// Config file
configuration NeighborDiscoveryC
{
    provides interface NeighborDiscovery;
}
implementation // Specifies wiring
{
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;
}