#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
module FloodingP{
    provides interface Flooding;

    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
}
implementation{
    command void Flooding.pass(){}
}