#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
configuration FloodingC{
    provides interface Flooding;
}
implementation{
    components FloodingP;
    Flooding = FloodingP.Flooding;

    // Timers
    // components new TimerMilliC() as floodTimer;
    // FloodingP.floodTimer -> floodTimer;

    // // Ping & Reply
    // components new SimpleSendC(AM_FLOODING) as Sender;
    // FloodingP.Sender -> Sender;
}