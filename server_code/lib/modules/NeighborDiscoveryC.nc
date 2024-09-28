// Config file
#include "../../includes/am_types.h"
configuration NeighborDiscoveryC
{
    provides interface NeighborDiscovery;
}
implementation // Specifies wiring
{
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;

    // Timers
    components new TimerMilliC() as discoveryTimer;
    NeighborDiscoveryP.discoveryTimer -> discoveryTimer;
    components RandomC as Random;
    NeighborDiscoveryP.Random -> Random;

    // Ping & Reply
    components new SimpleSendC(AM_PACK) as Sender;
    components new AMReceiverC(AM_PACK) as Receiver;
    NeighborDiscoveryP.Sender-> Sender;
    NeighborDiscoveryP.Receiver -> Receiver;
}