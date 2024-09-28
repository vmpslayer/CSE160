// Config file
#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
configuration FloodingC
{
    provides interface Flooding;
}
implementation // Specifies wiring
{
    components FloodingP;
    Flooding = FloodingP.Flooding;

    // components new SimpleSendC(AM_PACK) as Sender;
    // components new AMReceiverC(AM_PACK) as Receiver;
    // FloodingP.Sender-> Sender;
    // FloodingP.Receiver -> Receiver;
}