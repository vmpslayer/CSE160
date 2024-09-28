#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
module FloodingP{
    provides interface Flooding;

    // uses interface SimpleSend as Sender;
    // uses interface Receive as Receiver;
}
implementation{
    command void Flooding.pass(){}
}