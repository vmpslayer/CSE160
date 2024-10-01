#ifndef DEVICE_H
#define DEVICE_H

#include "packet.h"
#include "protocol.h"
#include "channels.h"

enum{
    MAX_NEIGHBORS = 20,
};

typedef nx_struct Device{
    nx_uint8_t address; // Identifier for node
    nx_uint16_t pktReceived; // For calculations, X = total packets received
    nx_uint16_t pktSent; // For calculations, Y = total packets sent
} Device;

void logDevice(Device *device){
	dbg(GENERAL_CHANNEL, "Node Address: %hhu Packets Received: %hhu Packets Sent: %hhu\n",
	device->address, device->pktReceived, device->pktSent);
};

#endif
