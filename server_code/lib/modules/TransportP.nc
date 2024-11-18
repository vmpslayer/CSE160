#include "../../includes/TCP.h"
#include "../../includes/socket.h"

#define INVALID_SOCKET (socket_t)(-1)

module TransportP{
    provides interface Transport;

    uses interface Timer<TMilli> as transportTimer;
    uses interface LinkStateRouting;
}
implementation{
    socket_store_t connections[MAX_NUM_OF_SOCKETS];
    uint16_t seqNum[MAX_NUM_OF_SOCKETS];
    Routing forwardingTable[MAX_NEIGHBORS];
    pack pkt;

    nx_uint8_t serverSrc;
    nx_uint8_t serverPort;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    event void LinkStateRouting.updateListener(Routing* table, uint8_t length){
        memcpy(forwardingTable, table, length * sizeof(Routing));
    }

    command error_t Transport.initTransport(){
        call transportTimer.startOneShot(1000);

        return SUCCESS;
    }

    event void transportTimer.fired(){
        socket_t socket;
        socket_addr_t addr;

        socket = call Transport.socket();

        if(socket == INVALID_SOCKET){
            dbg(TRANSPORT_CHANNEL, "ERROR: No available sockets\n");
        }

        addr.port = serverPort;
        addr.addr = serverSrc;

        if(call Transport.bind(socket, &addr) == SUCCESS){
            dbg(TRANSPORT_CHANNEL, "SUCCESS: Socket bound to address\n");
        }
        else{
            dbg(TRANSPORT_CHANNEL, "ERROR: Failed to bind to soccket\n");
        }

        if(call Transport.listen(socket) == SUCCESS){
            dbg(TRANSPORT_CHANNEL, "SUCCESS: Listening on socket\n");
        }
        else{
            dbg(TRANSPORT_CHANNEL, "ERROR: Failed to start listening on socket\n");
        }
    }

    command socket_t Transport.socket(){
        // Get a socket if there is one available
        // Look for closed socket
        // Then, return that socket
        uint8_t i;

        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
            if(connections[i].state == CLOSED){
                return i;
            }
        }
        return INVALID_SOCKET;
    }
    command error_t Transport.bind(socket_t fd, socket_addr_t *addr){
        // Bind socket with address
        if(connections[fd].state == CLOSED){
            // SUCCESS if you can bind to socket
            connections[fd].src = addr->port;
            connections[fd].dest = *addr;
            return SUCCESS;
        }
        return FAIL;
    }
    command socket_t Transport.accept(socket_t fd){
        uint8_t i;
        if(connections[fd].state == LISTEN){
            for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
                if(connections[i].state == CLOSED){
                    connections[i] = connections[fd];
                    connections[i].state = ESTABLISHED;
                    return i;
                }
            }
        }
        return INVALID_SOCKET;
    }
    command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){
        // Change TTL (0) to a value
        // makePack(&pkt, connections[fd].src, connections[fd].dest.port, 0, PROTOCOL_TCP, connections[fd].seq, buff, bufflen)
    }
    command error_t Transport.receive(pack* package){
        uint8_t i = 0;
        TCP synAckPkt;
        TCP ackPkt;

        TCP *receivedTCP = (TCP*)package->payload;

        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
            // Server should first be listening
            // If listen, then we reply with SYN(SEQ = y) & ACK(x + 1)
            // dbg(TRANSPORT_CHANNEL, "%i, %i, %i, %i\n", TOS_NODE_ID, package->dest, connections[i].dest.port, receivedTCP->destPort);
            if(connections[i].state == LISTEN && TOS_NODE_ID == package->dest && connections[i].dest.port == receivedTCP->destPort){

                dbg(TRANSPORT_CHANNEL, "SUCCESS: Received initial SYN packet.\n");

                // Server receives the first initial SYN packet:
                if(receivedTCP->flags == SYN){
                    connections[i].state = SYN_RCVD;
                    
                    synAckPkt.srcPort = receivedTCP->srcPort;
                    synAckPkt.destPort = receivedTCP->destPort;
                    synAckPkt.seq = seqNum[i];
                    synAckPkt.ack = receivedTCP->seq + 1;
                    synAckPkt.flags = SYNACK;

                    makePack(&pkt, package->dest, package->src, 10, PROTOCOL_TCP, seqNum[i], (uint8_t*)&synAckPkt, sizeof(TCP));

                    seqNum[i]++;

                    if(call LinkStateRouting.forward(package->src, pkt) == SUCCESS){
                        dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent SYN(%i) & ACK(%i) to %i\n", synAckPkt.seq, synAckPkt.ack, package->dest);
                        return SUCCESS;
                    }
                    else{
                        return FAIL;
                    }
                }
                // Client receives the second SYN + ACK packet:
                else if(receivedTCP->flags == SYNACK){
                    dbg(TRANSPORT_CHANNEL, "SUCCESS: Received SYN + ACK packet\n");
                    connections[i].state = ESTABLISHED;

                    ackPkt.srcPort = receivedTCP->srcPort;
                    ackPkt.destPort = receivedTCP->destPort;
                    ackPkt.seq = seqNum[i];
                    ackPkt.ack = receivedTCP->seq + 1;
                    ackPkt.flags = ACK;

                    makePack(&pkt, package->dest, package->src, 10, PROTOCOL_TCP, seqNum[i], (uint8_t *)&ackPkt, sizeof(TCP));

                    seqNum[i]++;

                    if(call LinkStateRouting.forward(package->src, pkt) == SUCCESS){
                        dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent SYN(SEQ = %i) & ACK(%i) to %i\n", synAckPkt.seq, synAckPkt.ack, package->dest);
                        return SUCCESS;
                    }
                    else{
                        return FAIL;
                    }
                }
                // Server receives the final ACK packet:
                else if(receivedTCP->flags == ACK){
                    
                }
            }
        }
    }
    command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){
        
    }
    command error_t Transport.connect(socket_t fd, socket_addr_t * addr){
        // Client sends a SYN(SEQ = x) to server
        // Next: Server will send SYN(SEQ = y) & ACK(x + 1) 
        TCP synPkt;
        if(connections[fd].state != CLOSED){
            return FAIL;
        }

        synPkt.srcPort = connections[fd].src;
        synPkt.destPort = (uint16_t)addr->port;
        synPkt.seq = seqNum[fd];
        synPkt.ack = 0;
        synPkt.flags = SYN;

        makePack(&pkt, TOS_NODE_ID, addr->addr, 10, PROTOCOL_TCP, seqNum[fd], (uint8_t *) &synPkt, (sizeof(TCP)));

        seqNum[fd]++;

        // dbg(TRANSPORT_CHANNEL, "Sending %u to port %i\n", pkt.payload, addr->addr);
        if(call LinkStateRouting.forward(addr->addr, pkt) == SUCCESS){
            dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent Connection (SYN(SEQ = %i)) Request to %i\n", synPkt.seq, addr->addr);
            connections[fd].state = SYN_SENT;
            return SUCCESS;
        }
        else{
            return FAIL;
        }
    }
    command error_t Transport.close(socket_t fd){
        if(connections[fd].state == ESTABLISHED){
            connections[fd].state = CLOSED;
            return SUCCESS;
        }
        return FAIL;
    }
    command error_t Transport.release(socket_t fd){
        
    }
    command error_t Transport.listen(socket_t fd){
        // Connection, establish it on a random socket
        // Traffic from one port to
        if(connections[fd].state == CLOSED){
            connections[fd].state = LISTEN;
            return SUCCESS;
        }
        return FAIL;
    }
    command error_t Transport.testServer(nx_uint8_t src, nx_uint8_t srcPort){
        serverSrc = src;
        serverPort = srcPort;
        if(call Transport.initTransport() == SUCCESS){
            return SUCCESS;
        }
        return FAIL;
    }
    command error_t Transport.testClient(nx_uint8_t src, nx_uint8_t srcPort, nx_uint8_t dest, nx_uint8_t destPort){
        socket_t socket;
        socket_addr_t addr;

        addr.port = destPort;
        addr.addr = dest;

        socket = call Transport.socket();

        if(call Transport.connect(socket, &addr) == SUCCESS){
            return SUCCESS;
        }
        return FAIL;
    }
}