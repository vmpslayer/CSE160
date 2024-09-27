// Config file
#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/am_types.h"
configuration NeighborDiscoveryC
{
    provides interface NeighborDiscovery;
}
implementation // Specifies wiring
{
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;

    components new TimerMilliC() as discoveryTimer;
    components MainC;

    // // Timers
    NeighborDiscoveryP.discoveryTimer -> discoveryTimer;
    NeighborDiscoveryP.Boot -> MainC.Boot;

    // NeighborDiscoveryP.Packet -> AMSenderC;
    // NeighborDiscoveryP.AMPacket -> AMSenderC;
    // NeighborDiscoveryP.AMSend -> AMSenderC;

    // NeighborDiscoveryP.AMReceiverC -> AMReceiverC;
}