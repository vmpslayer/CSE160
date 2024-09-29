#include "../../includes/packet.h"

interface Flooding{
    command error_t flood(pack msg, uint16_t src);
    event message_t* receive(message_t* msg, void* payload, uint8_t len);
}