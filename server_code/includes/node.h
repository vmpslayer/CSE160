#ifndef NODE_H
#define NODE_H

#include "packet.h"
#include "protocol.h"
#include "channels.h"

enum{
    MAX_NEIGHBORS = 10,
};

typedef nx_struct Node{
    nx_uint8_t address; // Identifier for node
    nx_uint16_t pktReceived; // For calculations, X = total packets received
    nx_uint16_t pktSent; // For calculations, Y = total packets sent
} Node;

void logNode(Node *node){
	dbg(GENERAL_CHANNEL, "Node Address: %hhu Packets Received: %hhu Packets Sent: %hhu\n",
	node->address, node->pktReceived, node->pktSent);
};

#endif
