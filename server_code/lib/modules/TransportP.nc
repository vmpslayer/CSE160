#include "../../includes/TCP.h"
#include "../../includes/socket.h"

#define INVALID_SOCKET (socket_t)(-1)

module TransportP{
    provides interface Transport;

    uses interface Queue<socket_t> as socketConnectionQueue; 
    uses interface Queue<socket_t> as socketTransmitQueue;
    uses interface Queue<socket_t> as socketDisconnectionQueue; 
    uses interface Queue<socket_t> as socketRetryQueue;

    uses interface Timer<TMilli> as attemptConnectionTimer;
    uses interface Timer<TMilli> as transmitTimer;
    uses interface Timer<TMilli> as disconnectTimer;

    uses interface LinkStateRouting;
}
implementation{
    socket_store_t connections[MAX_NUM_OF_SOCKETS];
    socket_t socket;
    // uint8_t windowSize = 5;
    uint8_t retryCount = 0;
    uint16_t seqNum[MAX_NUM_OF_SOCKETS];
    Routing forwardingTable[MAX_NEIGHBORS];
    pack pkt;

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

    // #####################################################################################
    // Start Server
    // #####################################################################################

    command error_t Transport.initTransportServer(nx_uint8_t src, nx_uint8_t srcPort){
        socket_addr_t addr;
        
        // global fd = socket();
        socket = call Transport.socket();

        // socket address = NODE_ID [port]
        addr.port = srcPort;
        addr.addr = src;

        // bind(fd, socket address)
        if(call Transport.bind(socket, &addr) == SUCCESS){
            dbg(TRANSPORT_CHANNEL, "SUCCESS: Socket bound to address\n");
        }
        else{
            dbg(TRANSPORT_CHANNEL, "ERROR: Failed to bind to soccket\n");
        }
        if(call Transport.listen(socket) == SUCCESS){
            dbg(TRANSPORT_CHANNEL, "SUCCESS: Listening on socket\n");
            return SUCCESS;
        }
        else{
            dbg(TRANSPORT_CHANNEL, "ERROR: Failed to start listening on socket\n");
            return FAIL;
        }
        // startTimer(attempt_connection_time)
        return FAIL;
    }

    event void attemptConnectionTimer.fired(){
        socket_t fd;
        
        fd = call socketConnectionQueue.dequeue();

        if(connections[fd].state == ESTABLISHED){
            retryCount = 0;
            return;
        }

        retryCount++;

        if (retryCount > 3){
            connections[fd].state = CLOSED;
            dbg(TRANSPORT_CHANNEL, "ERROR: Could not connect to socket %i after 3 retries...\n", fd);
            return;
        }

        call attemptConnectionTimer.startOneShot(1000);
    }

    // #####################################################################################
    // Start Client
    // #####################################################################################

    // command error_t Transport.initTransportClient(nx_uint8_t dest, nx_uint8_t srcPort, nx_uint8_t destPort, uint16_t transfer)
    command error_t Transport.initTransportClient(nx_uint8_t dest, nx_uint8_t srcPort, nx_uint8_t destPort){
        // COMPLETE
        socket_addr_t addr;

        socket = call Transport.socket();

        addr.port = destPort;
        addr.addr = dest;

        connections[socket].src = (uint16_t)srcPort;

        // dbg(TRANSPORT_CHANNEL, "DEBUG: Using socket %i\n");
        if(call Transport.connect(socket, &addr) == SUCCESS){
            return SUCCESS;
        } 
        return FAIL;
    }

    // #####################################################################################
    // Disconnect
    // #####################################################################################

    command error_t Transport.clientClose(nx_uint8_t src, nx_uint8_t srcPort, nx_uint16_t dest, nx_uint16_t destPort){
        uint8_t i;

        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
            if(connections[i].state == ESTABLISHED && src == TOS_NODE_ID && connections[i].src == srcPort && connections[i].dest.addr == dest && connections[i].dest.port == destPort){
                if(call Transport.close(i) == SUCCESS){
                    dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent FIN packet to %i:%i\n", dest, destPort);
                    // dbg(TRANSPORT_CHANNEL, "DEBUG: src = %i, srcPort = %i, dest = %i, destPort = %i. Socket: %i\n", TOS_NODE_ID, connections[i].src, connections[i].dest.addr, connections[i].dest.port, i);
                    return SUCCESS;
                }
                else{
                    dbg(TRANSPORT_CHANNEL, "ERROR: Failed to send FIN packet to %i\n", dest);
                    return FAIL;
                }
            }
        }
        dbg(TRANSPORT_CHANNEL, "ERROR: No socket found with src = %i:%i, dest = %i:%i\n", TOS_NODE_ID, srcPort, dest, destPort);
        return FAIL;
    }

    task void disconnectSocket(){
        socket_t fd;
        if(!call socketDisconnectionQueue.empty()){
            fd = call socketDisconnectionQueue.dequeue();
            connections[fd].state = CLOSED;
            connections[fd].src = 0;
            connections[fd].dest.addr = 0;
            connections[fd].dest.port = 0;
            dbg(TRANSPORT_CHANNEL, "SUCCESS: Connection disconnected and socket %i CLOSED\n", fd);
        }
        else{
            dbg(TRANSPORT_CHANNEL, "DEBUG: No\n");
        }
    }

    event void disconnectTimer.fired(){
        post disconnectSocket();
    }

    // #####################################################################################

    command socket_t Transport.socket(){
        // COMPLETED
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
        // COMPLETE
        if(connections[fd].state == CLOSED){
            // SUCCESS if you can bind to socket
            connections[fd].src = addr->port;
            return SUCCESS;
        }
        return FAIL;
    }

    command socket_t Transport.accept(socket_t fd){
        socket_t newFd;
        
        // When server accepts a connection an accept event should be signaled
        // Client can signal a connectDone event when it is done
        // Only be signaled when the connection is ESTABLISHED
        if(fd != INVALID_SOCKET || connections[fd].state == ESTABLISHED){
            // Find new socket and copy information to new socket
            newFd = call Transport.socket();

            // dbg(TRANSPORT_CHANNEL, "DEBUG [1] (newFd): srcPort = %i, destPort = %i, state = %i. Socket: %i\n", connections[newFd].src, connections[newFd].dest.port, connections[newFd].state, newFd);
            // dbg(TRANSPORT_CHANNEL, "DEBUG [1] (fd): srcPort = %i, destPort = %i, state = %i. Socket: %i \n", connections[fd].src, connections[fd].dest.port, connections[fd].state, fd);

            connections[newFd] = connections[fd];
            connections[newFd].state = ESTABLISHED;
            seqNum[newFd] = seqNum[fd];

            dbg(TRANSPORT_CHANNEL, "SUCCESS: Socket accepted, can accept new connection\n");

            connections[fd].src = 0;
            connections[fd].dest.port = 0;
            connections[fd].dest.addr = 0;
            connections[fd].state = LISTEN;
            seqNum[fd] = 0;

            // dbg(TRANSPORT_CHANNEL, "DEBUG [2] (newFd): srcPort = %i, destPort = %i, state = %i. Socket: %i \n", connections[newFd].src, connections[newFd].dest.port, connections[newFd].state, newFd);
            // dbg(TRANSPORT_CHANNEL, "DEBUG [2] (fd): srcPort = %i, destPort = %i, state = %i. Socket: %i \n", connections[fd].src, connections[fd].dest.port, connections[fd].state, fd);

            return newFd;
        }
        else{
            return INVALID_SOCKET;
        }
    }
    
    // #####################################################################################
    // Read and Write
    // #####################################################################################

    command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){
        uint8_t i;
        uint16_t openWindow;
        uint16_t sendData;

        if (connections[fd].state != ESTABLISHED){
            dbg(TRANSPORT_CHANNEL, "ERROR: Cannot write to %i since it is not an ESTABLISHED connection\n", fd);
            return 0;
        }

        openWindow = connections[fd].lastWritten - connections[fd].lastAck;

        if (bufflen > openWindow){
            sendData = openWindow;  
        }
        else{
            sendData = bufflen;        
        }

        if(sendData > 0){
            memcpy(connections[fd].sendBuff, buff, sendData);
            if(call socketTransmitQueue.enqueue(fd) == SUCCESS){
                connections[fd].lastWritten += sendData;
                connections[fd].effectiveWindow -= sendData;
                call transmitTimer.startOneShot(1000);
                return sendData;
            }
        }
        else{
            dbg(TRANSPORT_CHANNEL, "ERROR: Cannot write data, buffer is full.\n");
            return 0;
        }
    }

    command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){
        uint16_t openWindow;
        uint16_t readData;
        
        if (connections[fd].state != ESTABLISHED){
            dbg(TRANSPORT_CHANNEL, "ERROR: Cannot read from socket %i since it is not an established connection\n");
            return 0;
        }

        openWindow = connections[fd].lastRead - connections[fd].lastRcvd;

        if (openWindow == 0){
            dbg(TRANSPORT_CHANNEL, "ERROR: No data in the receive buffer\n");
            return 0;
        }

        if (bufflen > openWindow){
            readData = openWindow;
        }
        else{       
            readData = bufflen;
        }
        memcpy(buff, connections[fd].rcvdBuff, readData);

        connections[fd].lastRead += readData;

        return readData; 
    }

    // #####################################################################################
    // Transmit data task
    // #####################################################################################

    task void transmitData(){
        socket_t fd;
        TCP dataPkt;

        if(!call socketTransmitQueue.empty()){
            socket = call socketTransmitQueue.dequeue();

            dataPkt.srcPort = connections[fd].src;
            dataPkt.destPort = connections[fd].dest.port;
            dataPkt.seq = seqNum[fd];
            dataPkt.ack = 0;
            dataPkt.flags = DATA;
            memcpy(dataPkt.payload, connections[fd].sendBuff, TCP_MAX_PAYLOAD_SIZE);
            dataPkt.adwindow = connections[fd].effectiveWindow;

            makePack(&pkt, TOS_NODE_ID, connections[fd].dest.addr, 10, PROTOCOL_TCP, seqNum[fd], (uint8_t*)&dataPkt, sizeof(TCP));
            
            if(call LinkStateRouting.forward(connections[fd].dest.addr, pkt) == SUCCESS){
                dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent DATA(SEQ = %i) for socket %i\n", seqNum[fd], fd);
                seqNum[fd]++;
            }
        }
    }

    event void transmitTimer.fired(){
        post transmitData();
    }

    // #####################################################################################
    // Custom Send
    // #####################################################################################

    command error_t Transport.writeMsg(nx_uint8_t src, nx_uint8_t srcPort, nx_uint8_t dest, nx_uint8_t destPort, uint8_t* message){
        uint8_t i;
        uint16_t bytes;

        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
            if(src == TOS_NODE_ID && srcPort == connections[i].src && dest == connections[i].dest.addr && destPort == connections[i].dest.port){
                bytes = call Transport.write(i, &message, sizeof(message));
                if(bytes > 0){
                    dbg(TRANSPORT_CHANNEL, "SUCCESS: Client wrote %i bytes\n", bytes);
                }
                else{
                    dbg(TRANSPORT_CHANNEL, "ERROR: Client could not write\n");
                }
            }
        }
    }

    // #####################################################################################

    command error_t Transport.receive(pack* package){
        // SHOULD BE complete, just need to add accept
        uint8_t i = 0;
        TCP synAckPkt;
        TCP ackPkt;

        TCP *receivedTCP = (TCP*)package->payload;

        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
            // Server should first be listening
            // If listen, then we reply with SYN(SEQ = y) & ACK(x + 1)
            // #####################################################################################
            // DEBUGGING:
            // dbg(TRANSPORT_CHANNEL, "Socket (%i) INFO:\nSrc Port: %i = %i\nDest: %i = %i, Dest Port: %i = %i\n", i, connections[i].src, receivedTCP->srcPort, TOS_NODE_ID, package->dest, connections[i].src, receivedTCP->destPort);
            // dbg(TRANSPORT_CHANNEL, "Received Flag: %i\n", receivedTCP->flags);
            // dbg(TRANSPORT_CHANNEL, "State: %i\n",connections[i].state);
            // #####################################################################################
            
            // socket_port_t src (src = port);
            // socket_addr_t dest (port = port, addr = dest);
            if(TOS_NODE_ID == package->dest){
                // #####################################################################################
                // SETUP
                // #####################################################################################
                // (S2) Server receives the first initial SYN packet:
                if(connections[i].state == LISTEN && receivedTCP->flags == SYN){
                    dbg(TRANSPORT_CHANNEL, "SUCCESS: Received initial SYN packet from %i.\n", package->src);

                    connections[i].state = SYN_RCVD;
                    connections[i].lastRcvd = receivedTCP->seq;
                    
                    synAckPkt.srcPort = receivedTCP->destPort;
                    synAckPkt.destPort = receivedTCP->srcPort;
                    synAckPkt.seq = seqNum[i];
                    synAckPkt.ack = receivedTCP->seq + 1;
                    synAckPkt.flags = SYNACK;
                    synAckPkt.adwindow = receivedTCP->adwindow;

                    connections[i].lastSent = seqNum[i];

                    // dbg(TRANSPORT_CHANNEL, "DEBUG(SERVER RECEIVE SYN/REPLY WITH SYN-ACK): srcPort: %i, destPort: %i\n", synAckPkt.srcPort, synAckPkt.destPort);

                    makePack(&pkt, TOS_NODE_ID, package->src, 10, PROTOCOL_TCP, seqNum[i], (uint8_t *) &synAckPkt, (sizeof(TCP)));

                    if(call LinkStateRouting.forward(package->src, pkt) == SUCCESS){
                        dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent SYN(%i) & ACK(%i) to %i\n", synAckPkt.seq, synAckPkt.ack, package->src);
                        seqNum[i]++;
                        return SUCCESS;
                    }
                    else{
                        dbg(TRANSPORT_CHANNEL, "ERROR: Could not send SYN(%i) & ACK(%i) to %i\n", synAckPkt.seq, synAckPkt.ack, package->src);
                        return FAIL;
                    }
                }
                // (S3) Client receives the second SYN + ACK packet:
                else if(connections[i].state == SYN_SENT && receivedTCP->flags == SYNACK){
                    dbg(TRANSPORT_CHANNEL, "SUCCESS: Received SYN + ACK packet\n");
                    
                    connections[i].state = ESTABLISHED;
                    connections[i].lastRcvd = receivedTCP->seq;

                    ackPkt.srcPort = receivedTCP->destPort;
                    ackPkt.destPort = receivedTCP->srcPort;
                    ackPkt.seq = seqNum[i];
                    ackPkt.ack = receivedTCP->seq + 1;
                    ackPkt.flags = ACK;

                    connections[i].src = ackPkt.srcPort;
                    connections[i].dest.addr = package->src;
                    connections[i].dest.port = ackPkt.destPort;
                    connections[i].lastAck = ackPkt.ack;
                    connections[i].lastSent = seqNum[i];
                    connections[i].effectiveWindow = receivedTCP->adwindow;

                    // dbg(TRANSPORT_CHANNEL, "DEBUG(CLIENT RECEIVE SYN-ACK/REPLY WITH ACK): srcPort: %i, destPort: %i\n", ackPkt.srcPort, ackPkt.destPort);

                    makePack(&pkt, TOS_NODE_ID, package->src, 10, PROTOCOL_TCP, seqNum[i], (uint8_t*)&ackPkt, sizeof(TCP));

                    if(call LinkStateRouting.forward(package->src, pkt) == SUCCESS){
                        dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent ACK(%i) to %i\n", ackPkt.ack, package->src);
                        seqNum[i]++;
                        return SUCCESS;
                    }
                    else{
                        dbg(TRANSPORT_CHANNEL, "ERROR: Could not send ACK(%i) to %i\n", ackPkt.ack, package->src);
                        return FAIL;
                    }
                }
                // (S4) Server receives the final ACK packet:
                else if(connections[i].state == SYN_RCVD && receivedTCP->flags == ACK){
                    socket_t newFd;
                    dbg(TRANSPORT_CHANNEL, "SUCCESS: Received final ACK packet\n");

                    connections[i].state = ESTABLISHED;
                    connections[i].lastAck = receivedTCP->seq;
                    connections[i].lastRcvd = receivedTCP->seq;
                    
                    // Server's destPort (101) = ackPkt's (Client's) srcPort (101)
                    // Server's srcPort (80) = ackPkt's (Client's) destPort (80)
                    connections[i].src = receivedTCP->destPort;
                    connections[i].dest.addr = package->src;
                    connections[i].dest.port = receivedTCP->srcPort;
                    connections[i].effectiveWindow = receivedTCP->adwindow;

                    // dbg(TRANSPORT_CHANNEL, "DEBUG(SERVER RECEIVES FINAL ACK): srcPort: %i, dest: %i:%i\n", connections[i].src, connections[i].dest.addr, connections[i].dest.port);
                    
                    newFd = call Transport.accept(i);
                    if(call socketConnectionQueue.enqueue(i) == SUCCESS){
                        if(call socketConnectionQueue.enqueue(newFd) == SUCCESS){
                            dbg(TRANSPORT_CHANNEL, "SUCCESS: New connection accepted and socket %i queued\n", newFd);
                            return SUCCESS;
                        }
                        else{
                            dbg(TRANSPORT_CHANNEL, "ERROR: Failed to queue new connection on socket %i\n", newFd);
                            return FAIL;
                        }
                    }
                    else{
                        dbg(TRANSPORT_CHANNEL, "ERROR: Failed to accept new connection on socket %i", i);
                        return FAIL;
                    }
                }
                // #####################################################################################
                // TEARDOWN
                // #####################################################################################
                // (T2) Recipient (Server) of Teardown
                else if (connections[i].state == ESTABLISHED && receivedTCP->flags == FIN && connections[i].dest.addr == package->src && connections[i].dest.port == receivedTCP->srcPort && connections[i].src == receivedTCP->destPort){
                    connections[i].state = CLOSE_WAIT;

                    dbg(TRANSPORT_CHANNEL, "SUCCESS: RECEIVED Initial FIN packet from %i:%i\n", connections[i].dest.addr, connections[i].dest.port);

                    ackPkt.srcPort = connections[i].src;
                    ackPkt.destPort = connections[i].dest.port;
                    ackPkt.seq = seqNum[i];
                    ackPkt.ack = receivedTCP->seq + 1;
                    ackPkt.flags = ACK;          

                    connections[i].lastRcvd = receivedTCP->seq;
                    connections[i].lastAck = ackPkt.ack;


                    makePack(&pkt, TOS_NODE_ID, package->src, 10, PROTOCOL_TCP, seqNum[i], (uint8_t *) &ackPkt, (sizeof(TCP)));

                    if(call LinkStateRouting.forward(package->src, pkt) == SUCCESS){
                        dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent ACK(%i) packet to acknowledge FIN from %i\n", ackPkt.ack, package->src);
                        seqNum[i]++;
                    }
                    else{
                        dbg(TRANSPORT_CHANNEL, "ERROR: Could not send ACK(%i) packet to acknowledge FIN from %i\n", ackPkt.seq, package->src);
                    }
                    if(call Transport.close(i) == SUCCESS){
                        dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent their own FIN packet to %i\n", package->src);
                        return SUCCESS;
                    }
                    else{
                        dbg(TRANSPORT_CHANNEL, "ERROR: Failed to send FIN packet to %i\n", package->src);
                        return FAIL;
                    }
                }
                // (T4) Initiator (Client) of Teardown (Receiving the reply from server)
                else if (connections[i].state == FIN_WAIT_1 && receivedTCP->flags == ACK && connections[i].dest.addr == package->src && connections[i].dest.port == receivedTCP->srcPort && connections[i].src == receivedTCP->destPort){
                    connections[i].state = FIN_WAIT_2;
                    connections[i].lastAck = receivedTCP->seq;
                }
                // (T5) Initiator (Client) of Teardown (Receiving FIN from recipient)
                else if (connections[i].state == FIN_WAIT_2 && receivedTCP->flags == FIN){
                    dbg(TRANSPORT_CHANNEL, "SUCCESS: Received Recipient's FIN packet.\n");
                    connections[i].state = TIME_WAIT;

                    ackPkt.srcPort = connections[i].src;
                    ackPkt.destPort = connections[i].dest.port;
                    ackPkt.seq = seqNum[i];
                    ackPkt.ack = receivedTCP->seq + 1;
                    ackPkt.flags = ACK;

                    connections[i].lastRcvd = receivedTCP->seq;
                    connections[i].lastAck = ackPkt.ack;

                    makePack(&pkt, TOS_NODE_ID, package->src, 10, PROTOCOL_TCP, seqNum[i], (uint8_t *) &ackPkt, (sizeof(TCP)));

                    if (call LinkStateRouting.forward(package->src, pkt) == SUCCESS){
                        dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent final ACK(%i) for FIN to %i\n", ackPkt.ack, package->src);
                        seqNum[i]++;
                    }
                    else{
                        dbg(TRANSPORT_CHANNEL, "ERROR: Failed to send final ACK(%i) for FIN to %i\n", ackPkt.ack, package->src);
                    }

                    if(call socketDisconnectionQueue.enqueue(i) == SUCCESS){
                        call disconnectTimer.startOneShot(1000);
                        return SUCCESS;
                    }
                    else{
                        dbg(TRANSPORT_CHANNEL, "ERROR: Failed to disconnection from socket %i\n", i);
                        return FAIL;
                    }

                }
                // #####################################################################################
                // WRITE/READ
                // #####################################################################################
                // (WR2) Receives data packet sent. Stores payload in the receive buffer associated to that socket
                else if (connections[i].state == ESTABLISHED && receivedTCP->flags == DATA){
                    uint16_t dataSize;

                    dbg(TRANSPORT_CHANNEL, "SUCCESS: Received Data Packet. It says:\n %s\n", receivedTCP->payload);
                    
                    dataSize = sizeof(receivedTCP->payload);

                    memcpy(&connections[i].rcvdBuff[connections[i].lastRcvd], &receivedTCP->payload, dataSize);
                    // connections[i].lastRcvd += receivedTCP->length;

                    // connections[i].nextExpected += receivedTCP->length;

                    ackPkt.srcPort = connections[i].src;
                    ackPkt.destPort = connections[i].dest.port;
                    ackPkt.seq = seqNum[i];
                    ackPkt.ack = connections[i].lastRcvd;
                    ackPkt.flags = ACK;
                    // Read/Receive Buffer
                    ackPkt.adwindow = SOCKET_BUFFER_SIZE - (connections[i].lastRcvd - connections[i].lastRead);

                    makePack(&pkt, TOS_NODE_ID, package->src, 10, PROTOCOL_TCP, 0, (uint8_t*)&ackPkt, sizeof(TCP));

                    if(call LinkStateRouting.forward(package->src, pkt) == SUCCESS){
                        seqNum[i]++;
                        dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent ACK(%i) to %i's data packet\n", ackPkt.ack, package->src);
                    }
                }
                // (WR3) Receives acknowledgement of data packet. Adjusts the window size accordingly
                else if (connections[i].state == ESTABLISHED && receivedTCP->flags == ACK){
                    // connections[i].lastRcvd += dataSize;

                    // connections[i].lastAck = receivedTCP->ack;
                    // connections[i].effectiveWindow = receivedTCP->adwindow;
                }
                else{
                    // dbg(TRANSPORT_CHANNEL, "ERROR: Out of range or out of order. Check debug\n");
                    // dbg(TRANSPORT_CHANNEL, "DEBUG: Expected %i, received %i. Socket %i with connection %i:%i to %i:%i\n", connections[i].nextExpected, receivedTCP->seq, i, TOS_NODE_ID, connections[i].src, connections[i].dest.addr, connections[i].dest.port);
                    continue;
                }
            }
            else{ 
                dbg(TRANSPORT_CHANNEL, "ERROR: Could not handle package since it is not intended for %i, but instead for %i\n", TOS_NODE_ID, package->src); 
                return FAIL;
            }
        }
    }

    command error_t Transport.connect(socket_t fd, socket_addr_t * addr){
        // COMPLETE
        // (S1) Client sends a SYN(SEQ = x) to server
        // Next: (S2) Server will send SYN(SEQ = y) & ACK(x + 1) 
        TCP synPkt;
        if(connections[fd].state != CLOSED){
            return FAIL;
        }

        synPkt.srcPort = connections[fd].src;
        synPkt.destPort = (uint16_t)addr->port;
        synPkt.seq = seqNum[fd];
        synPkt.ack = 0;
        synPkt.flags = SYN;
        synPkt.adwindow = SOCKET_BUFFER_SIZE;

        connections[fd].lastSent = seqNum[fd];

        // dbg(TRANSPORT_CHANNEL, "DEBUG(CLIENT SENDS INITIAL SYN): srcPort: %i, destPort: %i\n", synPkt.srcPort, synPkt.destPort);

        makePack(&pkt, TOS_NODE_ID, addr->addr, 10, PROTOCOL_TCP, seqNum[fd], (uint8_t *) &synPkt, (sizeof(TCP)));

        // dbg(TRANSPORT_CHANNEL, "Sending %u to port %i\n", pkt.payload, addr->addr);
        if(call LinkStateRouting.forward(addr->addr, pkt) == SUCCESS){
            dbg(TRANSPORT_CHANNEL, "SUCCESS: Sent Connection (SYN(SEQ = %i)) Request to %i\n", synPkt.seq, addr->addr);
            seqNum[fd]++;
            // call socketConnectionQueue.enqueue(fd);
            connections[fd].state = SYN_SENT;
            return SUCCESS;
        }
        else{
            retryCount = 0;
            call attemptConnectionTimer.startOneShot(1000);
            return FAIL;
        }
    }

    command error_t Transport.close(socket_t fd){
        TCP finPkt;
        // Initiation
            // Node tears down when close is called
            // Node will send out all remaining data then a FIN packet
            // Wait until it receives an ACK
            // After, it goes into FIN_WAIT_2 state
            // When FIN is received from other node, then our node will be in TIME_WAIT state
            // Wait a "long" time until it goes into closed, effectively allowing a few missed FIN packets to be sent
        // Recipient
            // receives FIN, goes to CLOSE_WAIT
            // Waits until application also calls close
            // Transmit FIN back to other node and receive the final acks before closing
        // Both
            // Close call, FIN is sent
            // When ACK + FIN is received, it will behave similar to node initiating teardown at TIME_WAIT

        finPkt.srcPort = connections[fd].src;
        finPkt.destPort = connections[fd].dest.port;
        finPkt.seq = seqNum[fd];
        finPkt.ack = 0;
        finPkt.flags = FIN;

        connections[fd].lastSent = finPkt.seq;

        // (T1) Calling close from client to server on socket
        if(connections[fd].state == ESTABLISHED){
            connections[fd].state = FIN_WAIT_1;
        }
        // (T3) Recipient (server) calls for .close
        else if(connections[fd].state == CLOSE_WAIT){
            connections[fd].state = LAST_ACK;
            if(call socketDisconnectionQueue.enqueue(fd) == SUCCESS){
                call disconnectTimer.startOneShot(100);
            }
            else{
                dbg(TRANSPORT_CHANNEL, "ERROR: Cannot enqueue and disconnect from socket %i", fd);
            }   
        }

        makePack(&pkt, TOS_NODE_ID, connections[fd].dest.addr, 10, PROTOCOL_TCP, seqNum[fd], (uint8_t*)&finPkt, sizeof(TCP));

        if(call LinkStateRouting.forward(connections[fd].dest.addr, pkt) == SUCCESS){
            seqNum[fd]++;
            return SUCCESS;
        }
        else{
            return FAIL;
        }
    } 
    command error_t Transport.release(socket_t fd){
        // COMPLETE
        connections[fd].state = CLOSED;
        dbg(TRANSPORT_CHANNEL, "SUCCESS: Released socket %i\n", fd);
        return SUCCESS;
    }
    command error_t Transport.listen(socket_t fd){
        // COMPLETE
        // Connection, establish it on a random socket
        // Traffic from one port to
        if(connections[fd].state == CLOSED){
            connections[fd].state = LISTEN;
            return SUCCESS;
        }
        return FAIL;
    }
}